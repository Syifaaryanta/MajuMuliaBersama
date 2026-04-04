-- ============================================================
-- 14_decimal_qty_stock_support.sql
-- Ubah qty/stok dari integer ke numeric agar support desimal
-- Jalankan di: Supabase Dashboard -> SQL Editor
-- ============================================================

BEGIN;

-- 1) sale_items.qty -> NUMERIC(15,3)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'sale_items'
      AND column_name = 'qty'
      AND data_type IN ('smallint', 'integer', 'bigint')
  ) THEN
    ALTER TABLE public.sale_items
      ALTER COLUMN qty TYPE NUMERIC(15,3)
      USING qty::NUMERIC(15,3);
  END IF;
END $$;

-- 2) products.stok -> NUMERIC(15,3)
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
END $$;

-- 3) product_prices.stok -> NUMERIC(15,3)
DO $$
BEGIN
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

-- 4) Opsional: jika tabel legacy purchase_items ada, ubah qty juga
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'purchase_items'
      AND column_name = 'qty'
      AND data_type IN ('smallint', 'integer', 'bigint')
  ) THEN
    ALTER TABLE public.purchase_items
      ALTER COLUMN qty TYPE NUMERIC(15,3)
      USING qty::NUMERIC(15,3);
  END IF;
END $$;

COMMIT;
