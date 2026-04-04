-- ============================================================
-- 13_reconcile_customer_receivable_from_sales.sql
-- Rekonsiliasi + sinkron otomatis saldo piutang customer dari sales
-- Jalankan di: Supabase Dashboard -> SQL Editor
-- ============================================================

BEGIN;

-- Guard kolom agar kompatibel lintas versi schema.
ALTER TABLE public.customers
	ADD COLUMN IF NOT EXISTS saldo_piutang NUMERIC(15,2);

ALTER TABLE public.sales
	ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'draft';

ALTER TABLE public.sales
	ADD COLUMN IF NOT EXISTS extra_charge_amount NUMERIC(15,2) NOT NULL DEFAULT 0;

UPDATE public.customers
SET saldo_piutang = COALESCE(saldo_piutang, 0)
WHERE saldo_piutang IS NULL;

ALTER TABLE public.customers
	ALTER COLUMN saldo_piutang SET DEFAULT 0,
	ALTER COLUMN saldo_piutang SET NOT NULL;

-- Helper: hitung ulang saldo satu customer langsung dari tabel sales.
CREATE OR REPLACE FUNCTION public.recompute_customer_saldo_piutang(p_customer_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
	IF p_customer_id IS NULL THEN
		RETURN;
	END IF;

	UPDATE public.customers c
	SET
		saldo_piutang = COALESCE((
			SELECT SUM(COALESCE(s.subtotal, 0) + COALESCE(s.extra_charge_amount, 0))
			FROM public.sales s
			WHERE s.customer_id = p_customer_id
				AND s.status = 'completed'
		), 0),
		updated_at = NOW()
	WHERE c.id = p_customer_id;
END;
$$;

-- Trigger function: rekalkulasi customer terdampak saat sales berubah.
CREATE OR REPLACE FUNCTION public.sync_customer_saldo_piutang_from_sales()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
	v_new_customer_id UUID;
	v_old_customer_id UUID;
BEGIN
	v_new_customer_id := CASE WHEN TG_OP = 'DELETE' THEN NULL ELSE NEW.customer_id END;
	v_old_customer_id := CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE OLD.customer_id END;

	IF v_new_customer_id IS NOT NULL THEN
		PERFORM public.recompute_customer_saldo_piutang(v_new_customer_id);
	END IF;

	IF v_old_customer_id IS NOT NULL AND v_old_customer_id IS DISTINCT FROM v_new_customer_id THEN
		PERFORM public.recompute_customer_saldo_piutang(v_old_customer_id);
	END IF;

	RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_customer_saldo_piutang_on_sales ON public.sales;

CREATE TRIGGER trg_sync_customer_saldo_piutang_on_sales
AFTER INSERT OR UPDATE OR DELETE ON public.sales
FOR EACH ROW
EXECUTE FUNCTION public.sync_customer_saldo_piutang_from_sales();

-- Rekonsiliasi penuh semua customer dari data sales yang sudah ada.
UPDATE public.customers c
SET
	saldo_piutang = COALESCE(agg.total, 0),
	updated_at = NOW()
FROM (
	SELECT
		customer_id,
		SUM(COALESCE(subtotal, 0) + COALESCE(extra_charge_amount, 0)) AS total
	FROM public.sales
	WHERE status = 'completed'
	GROUP BY customer_id
) agg
WHERE c.id = agg.customer_id;

UPDATE public.customers c
SET
	saldo_piutang = 0,
	updated_at = NOW()
WHERE COALESCE(c.saldo_piutang, 0) <> 0
	AND NOT EXISTS (
		SELECT 1
		FROM public.sales s
		WHERE s.customer_id = c.id
			AND s.status = 'completed'
	);

NOTIFY pgrst, 'reload schema';

COMMIT;

-- Verifikasi cepat hasil rekonsiliasi.
SELECT
	c.kode,
	c.nama,
	c.saldo_piutang,
	COALESCE(agg.total_piutang, 0) AS saldo_hitung_ulang
FROM public.customers c
LEFT JOIN (
	SELECT
		customer_id,
		SUM(COALESCE(subtotal, 0) + COALESCE(extra_charge_amount, 0)) AS total_piutang
	FROM public.sales
	WHERE status = 'completed'
	GROUP BY customer_id
) agg ON agg.customer_id = c.id
ORDER BY c.nama;

