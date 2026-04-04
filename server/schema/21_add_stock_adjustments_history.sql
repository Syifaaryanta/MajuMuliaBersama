-- ============================================================
-- 21_add_stock_adjustments_history.sql
-- Simpan histori penyesuaian stok global oleh staff gudang
-- Jalankan di: Supabase Dashboard -> SQL Editor
-- ============================================================

BEGIN;

DO $$
BEGIN
  IF to_regclass('public.products') IS NULL THEN
    RAISE EXCEPTION 'Tabel products belum ada. Jalankan migrasi schema produk terlebih dahulu.';
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.stock_adjustments (
  id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id      UUID          REFERENCES public.products(id) ON DELETE SET NULL,
  product_kode    TEXT          NOT NULL DEFAULT '',
  product_nama    TEXT          NOT NULL DEFAULT '',
  adjustment_date DATE          NOT NULL DEFAULT CURRENT_DATE,
  stock_before    NUMERIC(15,3) NOT NULL DEFAULT 0 CHECK (stock_before >= 0),
  stock_after     NUMERIC(15,3) NOT NULL DEFAULT 0 CHECK (stock_after >= 0),
  qty_delta       NUMERIC(15,3) NOT NULL DEFAULT 0,
  staff_nama      TEXT          NOT NULL DEFAULT '',
  alasan          TEXT          NOT NULL DEFAULT '',
  created_by      UUID          REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

ALTER TABLE public.stock_adjustments
  ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS product_kode TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS product_nama TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS adjustment_date DATE DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS stock_before NUMERIC(15,3) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS stock_after NUMERIC(15,3) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS qty_delta NUMERIC(15,3) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS staff_nama TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS alasan TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

UPDATE public.stock_adjustments
SET
  product_kode = COALESCE(product_kode, ''),
  product_nama = COALESCE(product_nama, ''),
  adjustment_date = COALESCE(adjustment_date, CURRENT_DATE),
  stock_before = COALESCE(stock_before, 0),
  stock_after = COALESCE(stock_after, COALESCE(stock_before, 0) + COALESCE(qty_delta, 0)),
  qty_delta = COALESCE(qty_delta, COALESCE(stock_after, 0) - COALESCE(stock_before, 0)),
  staff_nama = COALESCE(NULLIF(BTRIM(staff_nama), ''), 'SYSTEM'),
  alasan = COALESCE(NULLIF(BTRIM(alasan), ''), 'Penyesuaian stok'),
  created_at = COALESCE(created_at, NOW()),
  updated_at = COALESCE(updated_at, NOW());

ALTER TABLE public.stock_adjustments
  ALTER COLUMN product_kode SET NOT NULL,
  ALTER COLUMN product_kode SET DEFAULT '',
  ALTER COLUMN product_nama SET NOT NULL,
  ALTER COLUMN product_nama SET DEFAULT '',
  ALTER COLUMN adjustment_date SET NOT NULL,
  ALTER COLUMN adjustment_date SET DEFAULT CURRENT_DATE,
  ALTER COLUMN stock_before SET NOT NULL,
  ALTER COLUMN stock_before SET DEFAULT 0,
  ALTER COLUMN stock_after SET NOT NULL,
  ALTER COLUMN stock_after SET DEFAULT 0,
  ALTER COLUMN qty_delta SET NOT NULL,
  ALTER COLUMN qty_delta SET DEFAULT 0,
  ALTER COLUMN staff_nama SET NOT NULL,
  ALTER COLUMN staff_nama SET DEFAULT '',
  ALTER COLUMN alasan SET NOT NULL,
  ALTER COLUMN alasan SET DEFAULT '',
  ALTER COLUMN created_at SET NOT NULL,
  ALTER COLUMN created_at SET DEFAULT NOW(),
  ALTER COLUMN updated_at SET NOT NULL,
  ALTER COLUMN updated_at SET DEFAULT NOW();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'stock_adjustments_staff_nama_not_empty'
  ) THEN
    ALTER TABLE public.stock_adjustments
      ADD CONSTRAINT stock_adjustments_staff_nama_not_empty
      CHECK (BTRIM(staff_nama) <> '');
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'stock_adjustments_alasan_not_empty'
  ) THEN
    ALTER TABLE public.stock_adjustments
      ADD CONSTRAINT stock_adjustments_alasan_not_empty
      CHECK (BTRIM(alasan) <> '');
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'stock_adjustments_stock_consistency'
  ) THEN
    ALTER TABLE public.stock_adjustments
      ADD CONSTRAINT stock_adjustments_stock_consistency
      CHECK (ROUND(stock_before + qty_delta, 3) = ROUND(stock_after, 3));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_stock_adjustments_adjustment_date ON public.stock_adjustments (adjustment_date DESC);
CREATE INDEX IF NOT EXISTS idx_stock_adjustments_product_id ON public.stock_adjustments (product_id);
CREATE INDEX IF NOT EXISTS idx_stock_adjustments_staff_nama ON public.stock_adjustments (staff_nama);

DROP TRIGGER IF EXISTS trg_stock_adjustments_updated_at ON public.stock_adjustments;
CREATE TRIGGER trg_stock_adjustments_updated_at
  BEFORE UPDATE ON public.stock_adjustments
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

ALTER TABLE public.stock_adjustments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "User login bisa baca stock adjustments" ON public.stock_adjustments;
CREATE POLICY "User login bisa baca stock adjustments"
  ON public.stock_adjustments FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Admin & gudang bisa kelola stock adjustments" ON public.stock_adjustments;
CREATE POLICY "Admin & gudang bisa kelola stock adjustments"
  ON public.stock_adjustments FOR ALL
  USING (public.get_my_role() IN ('admin', 'staff_gudang'));

NOTIFY pgrst, 'reload schema';

COMMIT;

SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'stock_adjustments'
ORDER BY ordinal_position;
