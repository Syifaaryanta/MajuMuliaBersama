-- ============================================================
-- 16_sync_product_stock_for_sales.sql
-- Sinkron stok produk agar modul penjualan tidak false "stok kosong"
-- Jalankan di: Supabase Dashboard -> SQL Editor
-- ============================================================

BEGIN;

-- 1) Pastikan kolom-kolom kompatibel dengan query frontend.
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS aktif BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS is_archived BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS satuan TEXT NOT NULL DEFAULT 'pcs';

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS foto_urls TEXT[] DEFAULT '{}';

ALTER TABLE public.product_prices
  ADD COLUMN IF NOT EXISTS aktif BOOLEAN NOT NULL DEFAULT TRUE;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'products'
      AND column_name = 'stok'
      AND data_type IN ('smallint', 'integer', 'bigint')
  ) THEN
    ALTER TABLE public.products
      ALTER COLUMN stok TYPE NUMERIC(15,3)
      USING stok::NUMERIC(15,3);
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'product_prices'
      AND column_name = 'stok'
      AND data_type IN ('smallint', 'integer', 'bigint')
  ) THEN
    ALTER TABLE public.product_prices
      ALTER COLUMN stok TYPE NUMERIC(15,3)
      USING stok::NUMERIC(15,3);
  END IF;
END $$;

-- 2) Normalisasi nilai null/negatif.
UPDATE public.products
SET
  stok = GREATEST(COALESCE(stok, 0), 0),
  aktif = COALESCE(aktif, TRUE),
  is_archived = COALESCE(is_archived, FALSE),
  satuan = COALESCE(NULLIF(BTRIM(satuan), ''), 'pcs'),
  updated_at = NOW();

UPDATE public.product_prices
SET
  stok = GREATEST(COALESCE(stok, 0), 0),
  aktif = COALESCE(aktif, TRUE),
  updated_at = NOW();

-- 3) Sinkron awal stok products dari total stok aktif di product_prices.
-- Hanya update produk yang memang punya baris product_prices.
WITH agg AS (
  SELECT
    product_id,
    GREATEST(COALESCE(SUM(COALESCE(stok, 0)), 0), 0) AS total_stok
  FROM public.product_prices
  WHERE COALESCE(aktif, TRUE) = TRUE
  GROUP BY product_id
)
UPDATE public.products p
SET
  stok = agg.total_stok,
  updated_at = NOW()
FROM agg
WHERE p.id = agg.product_id;

-- 4) Trigger sinkron otomatis setelah perubahan product_prices.
CREATE OR REPLACE FUNCTION public.sync_products_stok_from_price_rows()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_new_product_id UUID;
  v_old_product_id UUID;
BEGIN
  v_new_product_id := CASE WHEN TG_OP = 'DELETE' THEN NULL ELSE NEW.product_id END;
  v_old_product_id := CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE OLD.product_id END;

  IF v_new_product_id IS NOT NULL THEN
    UPDATE public.products p
    SET
      stok = COALESCE((
        SELECT GREATEST(COALESCE(SUM(COALESCE(pp.stok, 0)), 0), 0)
        FROM public.product_prices pp
        WHERE pp.product_id = v_new_product_id
          AND COALESCE(pp.aktif, TRUE) = TRUE
      ), 0),
      updated_at = NOW()
    WHERE p.id = v_new_product_id;
  END IF;

  IF v_old_product_id IS NOT NULL AND v_old_product_id IS DISTINCT FROM v_new_product_id THEN
    UPDATE public.products p
    SET
      stok = COALESCE((
        SELECT GREATEST(COALESCE(SUM(COALESCE(pp.stok, 0)), 0), 0)
        FROM public.product_prices pp
        WHERE pp.product_id = v_old_product_id
          AND COALESCE(pp.aktif, TRUE) = TRUE
      ), 0),
      updated_at = NOW()
    WHERE p.id = v_old_product_id;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_products_stok_from_price_rows ON public.product_prices;

CREATE TRIGGER trg_sync_products_stok_from_price_rows
AFTER INSERT OR UPDATE OR DELETE ON public.product_prices
FOR EACH ROW
EXECUTE FUNCTION public.sync_products_stok_from_price_rows();

COMMIT;
