-- ============================================================
-- 19_fix_receiving_and_barang_history_db_alignment.sql
-- Pastikan receiving dan history barang punya source of truth di DB
-- Jalankan di: Supabase Dashboard -> SQL Editor
-- ============================================================

BEGIN;

CREATE TABLE IF NOT EXISTS public.purchases (
  id                     UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  no_order               TEXT          NOT NULL,
  order_date             DATE          NOT NULL DEFAULT CURRENT_DATE,
  no_faktur              TEXT,
  supplier_id            UUID          REFERENCES public.suppliers(id) ON DELETE SET NULL,
  supplier_nama          TEXT,
  supplier_alamat        TEXT,
  terms                  TEXT,
  subtotal               NUMERIC(15,2) NOT NULL DEFAULT 0,
  status                 TEXT          NOT NULL DEFAULT 'ordered',
  received_at            TIMESTAMPTZ,
  receiving_validations  JSONB         NOT NULL DEFAULT '{}'::jsonb,
  receiving_validated_at JSONB         NOT NULL DEFAULT '{}'::jsonb,
  request_fingerprint    TEXT,
  created_at             TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.purchase_items (
  id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_id   UUID          NOT NULL REFERENCES public.purchases(id) ON DELETE CASCADE,
  product_id    UUID          REFERENCES public.products(id) ON DELETE SET NULL,
  product_kode  TEXT          NOT NULL DEFAULT '',
  product_nama  TEXT          NOT NULL DEFAULT '',
  qty           NUMERIC(15,3) NOT NULL DEFAULT 0.001,
  unit_cost     NUMERIC(15,2) NOT NULL DEFAULT 0,
  total         NUMERIC(15,2) NOT NULL DEFAULT 0,
  receiving_key TEXT,
  created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

ALTER TABLE public.purchases
  ADD COLUMN IF NOT EXISTS no_order TEXT,
  ADD COLUMN IF NOT EXISTS order_date DATE,
  ADD COLUMN IF NOT EXISTS no_faktur TEXT,
  ADD COLUMN IF NOT EXISTS supplier_id UUID REFERENCES public.suppliers(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS supplier_nama TEXT,
  ADD COLUMN IF NOT EXISTS supplier_alamat TEXT,
  ADD COLUMN IF NOT EXISTS terms TEXT,
  ADD COLUMN IF NOT EXISTS subtotal NUMERIC(15,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'ordered',
  ADD COLUMN IF NOT EXISTS received_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS receiving_validations JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS receiving_validated_at JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS request_fingerprint TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.purchase_items
  ADD COLUMN IF NOT EXISTS purchase_id UUID REFERENCES public.purchases(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS product_kode TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS product_nama TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS qty NUMERIC(15,3) DEFAULT 0.001,
  ADD COLUMN IF NOT EXISTS unit_cost NUMERIC(15,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total NUMERIC(15,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS receiving_key TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

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

UPDATE public.purchases
SET
  no_order = COALESCE(NULLIF(BTRIM(no_order), ''), 'PO-LEGACY-' || SUBSTRING(id::TEXT, 1, 8)),
  order_date = COALESCE(order_date, CURRENT_DATE),
  subtotal = COALESCE(subtotal, 0),
  status = CASE WHEN status IN ('draft', 'ordered', 'received') THEN status ELSE 'ordered' END,
  receiving_validations = COALESCE(receiving_validations, '{}'::jsonb),
  receiving_validated_at = COALESCE(receiving_validated_at, '{}'::jsonb),
  created_at = COALESCE(created_at, NOW()),
  updated_at = COALESCE(updated_at, NOW());

UPDATE public.purchase_items
SET
  product_kode = COALESCE(product_kode, ''),
  product_nama = COALESCE(NULLIF(BTRIM(product_nama), ''), product_kode, '-'),
  qty = CASE WHEN COALESCE(qty, 0) <= 0 THEN 0.001 ELSE qty END,
  unit_cost = COALESCE(unit_cost, 0),
  total = COALESCE(total, COALESCE(qty, 0) * COALESCE(unit_cost, 0)),
  created_at = COALESCE(created_at, NOW()),
  updated_at = COALESCE(updated_at, NOW());

ALTER TABLE public.purchases
  ALTER COLUMN no_order SET NOT NULL,
  ALTER COLUMN order_date SET NOT NULL,
  ALTER COLUMN order_date SET DEFAULT CURRENT_DATE,
  ALTER COLUMN subtotal SET NOT NULL,
  ALTER COLUMN subtotal SET DEFAULT 0,
  ALTER COLUMN status SET NOT NULL,
  ALTER COLUMN status SET DEFAULT 'ordered',
  ALTER COLUMN receiving_validations SET NOT NULL,
  ALTER COLUMN receiving_validations SET DEFAULT '{}'::jsonb,
  ALTER COLUMN receiving_validated_at SET NOT NULL,
  ALTER COLUMN receiving_validated_at SET DEFAULT '{}'::jsonb,
  ALTER COLUMN created_at SET NOT NULL,
  ALTER COLUMN created_at SET DEFAULT NOW(),
  ALTER COLUMN updated_at SET NOT NULL,
  ALTER COLUMN updated_at SET DEFAULT NOW();

ALTER TABLE public.purchase_items
  ALTER COLUMN product_kode SET NOT NULL,
  ALTER COLUMN product_kode SET DEFAULT '',
  ALTER COLUMN product_nama SET NOT NULL,
  ALTER COLUMN product_nama SET DEFAULT '',
  ALTER COLUMN qty SET NOT NULL,
  ALTER COLUMN qty SET DEFAULT 0.001,
  ALTER COLUMN unit_cost SET NOT NULL,
  ALTER COLUMN unit_cost SET DEFAULT 0,
  ALTER COLUMN total SET NOT NULL,
  ALTER COLUMN total SET DEFAULT 0,
  ALTER COLUMN created_at SET NOT NULL,
  ALTER COLUMN created_at SET DEFAULT NOW(),
  ALTER COLUMN updated_at SET NOT NULL,
  ALTER COLUMN updated_at SET DEFAULT NOW();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'purchases_status_check'
  ) THEN
    ALTER TABLE public.purchases
      ADD CONSTRAINT purchases_status_check
      CHECK (status IN ('draft', 'ordered', 'received'));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'purchase_items_qty_check'
  ) THEN
    ALTER TABLE public.purchase_items
      ADD CONSTRAINT purchase_items_qty_check
      CHECK (qty > 0);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'purchase_items_unit_cost_check'
  ) THEN
    ALTER TABLE public.purchase_items
      ADD CONSTRAINT purchase_items_unit_cost_check
      CHECK (unit_cost >= 0);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'purchase_items_total_check'
  ) THEN
    ALTER TABLE public.purchase_items
      ADD CONSTRAINT purchase_items_total_check
      CHECK (total >= 0);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'purchases_no_order_key'
  ) THEN
    IF EXISTS (
      SELECT no_order
      FROM public.purchases
      GROUP BY no_order
      HAVING COUNT(*) > 1
    ) THEN
      RAISE NOTICE 'Skip UNIQUE purchases.no_order because duplicate values still exist.';
    ELSE
      ALTER TABLE public.purchases
        ADD CONSTRAINT purchases_no_order_key UNIQUE (no_order);
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_purchases_order_date ON public.purchases (order_date);
CREATE INDEX IF NOT EXISTS idx_purchases_status ON public.purchases (status);
CREATE INDEX IF NOT EXISTS idx_purchases_supplier_id ON public.purchases (supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase_id ON public.purchase_items (purchase_id);
CREATE INDEX IF NOT EXISTS idx_purchase_items_product_id ON public.purchase_items (product_id);

DROP TRIGGER IF EXISTS trg_purchases_updated_at ON public.purchases;
CREATE TRIGGER trg_purchases_updated_at
  BEFORE UPDATE ON public.purchases
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trg_purchase_items_updated_at ON public.purchase_items;
CREATE TRIGGER trg_purchase_items_updated_at
  BEFORE UPDATE ON public.purchase_items
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "User login bisa baca purchases" ON public.purchases;
CREATE POLICY "User login bisa baca purchases"
  ON public.purchases FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Admin, gudang & kantor bisa kelola purchases" ON public.purchases;
CREATE POLICY "Admin, gudang & kantor bisa kelola purchases"
  ON public.purchases FOR ALL
  USING (public.get_my_role() IN ('admin', 'staff_gudang', 'staff_kantor'));

DROP POLICY IF EXISTS "User login bisa baca purchase items" ON public.purchase_items;
CREATE POLICY "User login bisa baca purchase items"
  ON public.purchase_items FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Admin, gudang & kantor bisa kelola purchase items" ON public.purchase_items;
CREATE POLICY "Admin, gudang & kantor bisa kelola purchase items"
  ON public.purchase_items FOR ALL
  USING (public.get_my_role() IN ('admin', 'staff_gudang', 'staff_kantor'));

NOTIFY pgrst, 'reload schema';

COMMIT;

SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('purchases', 'purchase_items')
ORDER BY table_name, ordinal_position;
