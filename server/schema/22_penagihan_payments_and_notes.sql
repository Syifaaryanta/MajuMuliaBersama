-- ============================================================
-- 22_penagihan_payments_and_notes.sql
-- Modul Penagihan: pembayaran piutang, status nota, dan view ringkasan
-- Jalankan di: Supabase Dashboard -> SQL Editor
-- ============================================================

BEGIN;

-- 1) Tambahan kolom pada sales untuk kebutuhan penagihan
ALTER TABLE public.sales
  ADD COLUMN IF NOT EXISTS due_date DATE,
  ADD COLUMN IF NOT EXISTS nota_merah BOOLEAN,
  ADD COLUMN IF NOT EXISTS nota_putih BOOLEAN,
  ADD COLUMN IF NOT EXISTS nota_kuning BOOLEAN;

UPDATE public.sales
SET
  nota_merah = COALESCE(nota_merah, FALSE),
  nota_putih = COALESCE(nota_putih, FALSE),
  nota_kuning = COALESCE(nota_kuning, TRUE);

ALTER TABLE public.sales
  ALTER COLUMN nota_merah SET DEFAULT FALSE,
  ALTER COLUMN nota_merah SET NOT NULL,
  ALTER COLUMN nota_putih SET DEFAULT FALSE,
  ALTER COLUMN nota_putih SET NOT NULL,
  ALTER COLUMN nota_kuning SET DEFAULT TRUE,
  ALTER COLUMN nota_kuning SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'sales_nota_mutually_exclusive'
  ) THEN
    ALTER TABLE public.sales
      ADD CONSTRAINT sales_nota_mutually_exclusive
      CHECK (NOT (nota_merah AND nota_putih));
  END IF;
END $$;

-- 2) Hitung due date otomatis berdasar limit_bulan
CREATE OR REPLACE FUNCTION public.compute_sales_due_date(p_order_date DATE, p_limit_bulan INTEGER)
RETURNS DATE
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_order_date IS NULL THEN
    RETURN NULL;
  END IF;

  CASE COALESCE(p_limit_bulan, 0)
    WHEN -1 THEN RETURN p_order_date; -- Tunai
    WHEN 0 THEN RETURN (p_order_date + INTERVAL '1 month')::DATE; -- 1 bulan
    WHEN 1 THEN RETURN (p_order_date + INTERVAL '2 month')::DATE; -- 2 bulan
    WHEN 2 THEN RETURN (p_order_date + INTERVAL '3 month')::DATE; -- 3 bulan
    ELSE RETURN p_order_date;
  END CASE;
END;
$$;

CREATE OR REPLACE FUNCTION public.fill_sales_due_date()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.due_date := public.compute_sales_due_date(NEW.order_date, NEW.limit_bulan);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_fill_sales_due_date ON public.sales;
CREATE TRIGGER trg_fill_sales_due_date
BEFORE INSERT OR UPDATE OF order_date, limit_bulan
ON public.sales
FOR EACH ROW
EXECUTE FUNCTION public.fill_sales_due_date();

UPDATE public.sales
SET due_date = public.compute_sales_due_date(order_date, limit_bulan)
WHERE due_date IS DISTINCT FROM public.compute_sales_due_date(order_date, limit_bulan);

-- 3) Tabel pembayaran per transaksi penjualan (cicilan/lunas)
CREATE TABLE IF NOT EXISTS public.sales_payments (
  id             UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id        UUID          NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
  payment_date   DATE          NOT NULL DEFAULT CURRENT_DATE,
  amount         NUMERIC(15,2) NOT NULL CHECK (amount > 0),
  payment_method TEXT          NOT NULL DEFAULT 'cash',
  note           TEXT,
  created_by     UUID          REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

ALTER TABLE public.sales_payments
  ADD COLUMN IF NOT EXISTS sale_id UUID REFERENCES public.sales(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS payment_date DATE DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS amount NUMERIC(15,2),
  ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'cash',
  ADD COLUMN IF NOT EXISTS note TEXT,
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

UPDATE public.sales_payments
SET
  payment_date = COALESCE(payment_date, CURRENT_DATE),
  amount = COALESCE(amount, 0),
  payment_method = COALESCE(NULLIF(BTRIM(payment_method), ''), 'cash'),
  created_at = COALESCE(created_at, NOW()),
  updated_at = COALESCE(updated_at, NOW())
WHERE payment_date IS NULL
   OR amount IS NULL
   OR payment_method IS NULL
   OR BTRIM(payment_method) = ''
   OR created_at IS NULL
   OR updated_at IS NULL;

ALTER TABLE public.sales_payments
  ALTER COLUMN sale_id SET NOT NULL,
  ALTER COLUMN payment_date SET NOT NULL,
  ALTER COLUMN payment_date SET DEFAULT CURRENT_DATE,
  ALTER COLUMN amount SET NOT NULL,
  ALTER COLUMN payment_method SET NOT NULL,
  ALTER COLUMN payment_method SET DEFAULT 'cash',
  ALTER COLUMN created_at SET NOT NULL,
  ALTER COLUMN created_at SET DEFAULT NOW(),
  ALTER COLUMN updated_at SET NOT NULL,
  ALTER COLUMN updated_at SET DEFAULT NOW();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'sales_payments_amount_positive'
  ) THEN
    ALTER TABLE public.sales_payments
      ADD CONSTRAINT sales_payments_amount_positive
      CHECK (amount > 0);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_sales_payments_sale_id ON public.sales_payments (sale_id);
CREATE INDEX IF NOT EXISTS idx_sales_payments_payment_date ON public.sales_payments (payment_date DESC);

DROP TRIGGER IF EXISTS trg_sales_payments_updated_at ON public.sales_payments;
CREATE TRIGGER trg_sales_payments_updated_at
BEFORE UPDATE ON public.sales_payments
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();

ALTER TABLE public.sales_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "User login bisa baca sales payments" ON public.sales_payments;
CREATE POLICY "User login bisa baca sales payments"
  ON public.sales_payments FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Admin kantor sales bisa kelola sales payments" ON public.sales_payments;
CREATE POLICY "Admin kantor sales bisa kelola sales payments"
  ON public.sales_payments FOR ALL
  USING (public.get_my_role() IN ('admin', 'staff_kantor', 'sales'));

-- 4) Recompute saldo_piutang customer berbasis outstanding kredit
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
      SELECT SUM(
        GREATEST(
          (COALESCE(s.subtotal, 0) + COALESCE(s.extra_charge_amount, 0))
          - COALESCE(pay.total_paid, 0),
          0
        )
      )
      FROM public.sales s
      LEFT JOIN (
        SELECT sale_id, SUM(amount) AS total_paid
        FROM public.sales_payments
        GROUP BY sale_id
      ) pay ON pay.sale_id = s.id
      WHERE s.customer_id = p_customer_id
        AND s.status = 'completed'
        AND COALESCE(s.limit_bulan, 0) >= 0
    ), 0),
    updated_at = NOW()
  WHERE c.id = p_customer_id;
END;
$$;

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

CREATE OR REPLACE FUNCTION public.sync_customer_saldo_piutang_from_sales_payments()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_new_customer_id UUID;
  v_old_customer_id UUID;
BEGIN
  IF TG_OP <> 'DELETE' THEN
    SELECT customer_id INTO v_new_customer_id
    FROM public.sales
    WHERE id = NEW.sale_id;
  END IF;

  IF TG_OP <> 'INSERT' THEN
    SELECT customer_id INTO v_old_customer_id
    FROM public.sales
    WHERE id = OLD.sale_id;
  END IF;

  IF v_new_customer_id IS NOT NULL THEN
    PERFORM public.recompute_customer_saldo_piutang(v_new_customer_id);
  END IF;

  IF v_old_customer_id IS NOT NULL AND v_old_customer_id IS DISTINCT FROM v_new_customer_id THEN
    PERFORM public.recompute_customer_saldo_piutang(v_old_customer_id);
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_customer_saldo_piutang_on_sales_payments ON public.sales_payments;
CREATE TRIGGER trg_sync_customer_saldo_piutang_on_sales_payments
AFTER INSERT OR UPDATE OR DELETE ON public.sales_payments
FOR EACH ROW
EXECUTE FUNCTION public.sync_customer_saldo_piutang_from_sales_payments();

-- Rekonsiliasi ulang semua saldo_piutang customer
UPDATE public.customers
SET saldo_piutang = 0,
    updated_at = NOW();

UPDATE public.customers c
SET
  saldo_piutang = agg.total_outstanding,
  updated_at = NOW()
FROM (
  SELECT
    s.customer_id,
    SUM(
      GREATEST(
        (COALESCE(s.subtotal, 0) + COALESCE(s.extra_charge_amount, 0))
        - COALESCE(pay.total_paid, 0),
        0
      )
    ) AS total_outstanding
  FROM public.sales s
  LEFT JOIN (
    SELECT sale_id, SUM(amount) AS total_paid
    FROM public.sales_payments
    GROUP BY sale_id
  ) pay ON pay.sale_id = s.id
  WHERE s.status = 'completed'
    AND COALESCE(s.limit_bulan, 0) >= 0
  GROUP BY s.customer_id
) agg
WHERE c.id = agg.customer_id;

-- 5) Sinkron default status nota berdasar status hutang terakhir
UPDATE public.sales s
SET
  nota_merah = CASE
    WHEN COALESCE(s.limit_bulan, 0) < 0 THEN FALSE
    ELSE (
      GREATEST(
        (COALESCE(s.subtotal, 0) + COALESCE(s.extra_charge_amount, 0))
        - COALESCE((
          SELECT SUM(sp.amount)
          FROM public.sales_payments sp
          WHERE sp.sale_id = s.id
        ), 0),
        0
      ) > 0
    )
  END,
  nota_putih = CASE
    WHEN COALESCE(s.limit_bulan, 0) < 0 THEN TRUE
    ELSE (
      GREATEST(
        (COALESCE(s.subtotal, 0) + COALESCE(s.extra_charge_amount, 0))
        - COALESCE((
          SELECT SUM(sp.amount)
          FROM public.sales_payments sp
          WHERE sp.sale_id = s.id
        ), 0),
        0
      ) = 0
    )
  END,
  nota_kuning = TRUE
WHERE s.status = 'completed';

-- 6) View ringkasan penagihan untuk frontend
DROP VIEW IF EXISTS public.v_penagihan_sales;
CREATE VIEW public.v_penagihan_sales
WITH (security_invoker = true)
AS
WITH payment_agg AS (
  SELECT
    sp.sale_id,
    SUM(sp.amount) AS total_paid,
    MAX(sp.payment_date) AS last_payment_date,
    COUNT(*) AS payment_count
  FROM public.sales_payments sp
  GROUP BY sp.sale_id
),
base AS (
  SELECT
    s.id AS sale_id,
    s.no_order,
    s.no_faktur,
    s.order_date,
    s.due_date,
    s.customer_id,
    s.customer_nama,
    s.customer_alamat,
    s.customer_telp,
    s.limit_bulan,
    s.nota_merah,
    s.nota_putih,
    s.nota_kuning,
    COALESCE(s.subtotal, 0) + COALESCE(s.extra_charge_amount, 0) AS grand_total,
    COALESCE(pa.total_paid, 0) AS total_paid,
    pa.last_payment_date,
    COALESCE(pa.payment_count, 0) AS payment_count
  FROM public.sales s
  LEFT JOIN payment_agg pa ON pa.sale_id = s.id
  WHERE s.status = 'completed'
)
SELECT
  b.sale_id,
  b.no_order,
  b.no_faktur,
  b.order_date,
  b.due_date,
  b.customer_id,
  b.customer_nama,
  b.customer_alamat,
  b.customer_telp,
  b.limit_bulan,
  b.nota_merah,
  b.nota_putih,
  b.nota_kuning,
  b.grand_total,
  b.total_paid,
  CASE
    WHEN b.limit_bulan = -1 THEN 0
    ELSE GREATEST(b.grand_total - b.total_paid, 0)
  END AS outstanding_amount,
  CASE
    WHEN b.limit_bulan = -1 THEN 'cash'
    WHEN GREATEST(b.grand_total - b.total_paid, 0) = 0 THEN 'paid'
    WHEN b.total_paid > 0 THEN 'partial'
    ELSE 'unpaid'
  END AS payment_status,
  CASE
    WHEN b.limit_bulan = -1 THEN 'Tunai'
    WHEN b.limit_bulan = 0 THEN '1 Bulan'
    WHEN b.limit_bulan = 1 THEN '2 Bulan'
    WHEN b.limit_bulan = 2 THEN '3 Bulan'
    ELSE 'Tempo'
  END AS payment_term_label,
  (b.limit_bulan = -1) AS is_cash,
  (b.limit_bulan >= 0) AS is_credit,
  CASE
    WHEN b.limit_bulan >= 0
      AND GREATEST(b.grand_total - b.total_paid, 0) > 0
      AND b.due_date < CURRENT_DATE
    THEN (CURRENT_DATE - b.due_date)::INTEGER
    ELSE 0
  END AS overdue_days,
  (
    b.limit_bulan >= 0
    AND GREATEST(b.grand_total - b.total_paid, 0) > 0
    AND b.due_date < CURRENT_DATE
  ) AS is_overdue,
  b.last_payment_date,
  b.payment_count
FROM base b;

DROP VIEW IF EXISTS public.v_penagihan_payments;
CREATE VIEW public.v_penagihan_payments
WITH (security_invoker = true)
AS
SELECT
  sp.id,
  sp.sale_id,
  sp.payment_date,
  sp.amount,
  sp.payment_method,
  sp.note,
  sp.created_by,
  sp.created_at,
  s.no_order,
  s.no_faktur,
  s.customer_id,
  s.customer_nama,
  s.limit_bulan,
  (COALESCE(s.limit_bulan, 0) = -1) AS is_cash
FROM public.sales_payments sp
JOIN public.sales s ON s.id = sp.sale_id
WHERE s.status = 'completed';

NOTIFY pgrst, 'reload schema';

COMMIT;

-- Verifikasi cepat
SELECT
  c.kode,
  c.nama,
  c.saldo_piutang
FROM public.customers c
ORDER BY c.nama
LIMIT 30;
