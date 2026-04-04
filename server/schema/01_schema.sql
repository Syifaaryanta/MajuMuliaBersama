-- ============================================================
-- 01_schema.sql  —  MMB (Maju Mulia Bersama)
-- Jalankan di: Supabase Dashboard → SQL Editor
-- ============================================================

-- ── 0. DROP semua objek lama (urut balik dependency) ────────
DROP TABLE  IF EXISTS sale_items      CASCADE;
DROP TABLE  IF EXISTS sales           CASCADE;
DROP TABLE  IF EXISTS purchase_items  CASCADE;
DROP TABLE  IF EXISTS purchases       CASCADE;
DROP TABLE  IF EXISTS product_prices  CASCADE;
DROP TABLE  IF EXISTS products        CASCADE;
DROP TABLE  IF EXISTS customers       CASCADE;
DROP TABLE  IF EXISTS suppliers       CASCADE;
DROP TABLE  IF EXISTS profiles        CASCADE;

DROP FUNCTION IF EXISTS get_my_role()        CASCADE;
DROP FUNCTION IF EXISTS update_updated_at()  CASCADE;
DROP FUNCTION IF EXISTS handle_new_user()    CASCADE;

DROP TYPE IF EXISTS user_role CASCADE;

-- ── 1. Enum role ─────────────────────────────────────────────
CREATE TYPE user_role AS ENUM (
  'admin',
  'staff_gudang',
  'staff_kantor',
  'sales'
);

-- ── 2. Fungsi updated_at trigger ────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- ── 3. Tabel PROFILES — harus ada SEBELUM get_my_role() ──────
-- (get_my_role() mereferensikan tabel profiles, jadi profiles
--  wajib dibuat lebih dulu)
CREATE TABLE profiles (
  id           UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email        TEXT        NOT NULL,
  nama         TEXT        NOT NULL DEFAULT '',
  role         user_role   NOT NULL DEFAULT 'sales',
  aktif        BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Trigger: otomatis buat profile saat user baru dibuat di auth.users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  INSERT INTO profiles (id, email, nama, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'nama', split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'sales')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Backfill profil untuk user auth yang sudah ada sebelum trigger dibuat.
INSERT INTO profiles (id, email, nama, role, aktif)
SELECT
  u.id,
  u.email,
  COALESCE(u.raw_user_meta_data->>'nama', split_part(u.email, '@', 1)),
  COALESCE((u.raw_user_meta_data->>'role')::user_role, 'sales'::user_role),
  TRUE
FROM auth.users u
ON CONFLICT (id) DO NOTHING;

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Semua user login bisa baca profil (termasuk profil sendiri).
-- Tidak ada subquery ke profiles → tidak rekursi.
CREATE POLICY "User login bisa baca profil"
  ON profiles FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "User bisa update profil sendiri"
  ON profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- ── 4. Fungsi helper RLS — dibuat SETELAH tabel profiles ada ─
-- SECURITY DEFINER → berjalan sebagai superuser, tidak kena RLS
-- pada tabel profiles → tidak ada infinite recursion.
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS TEXT
LANGUAGE SQL
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT role::TEXT FROM profiles WHERE id = auth.uid();
$$;

-- ── 5. Tabel SUPPLIERS ───────────────────────────────────────
CREATE TABLE suppliers (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  kode        TEXT        NOT NULL UNIQUE,
  nama        TEXT        NOT NULL,
  alamat      TEXT,
  no_telp     TEXT,
  aktif       BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_suppliers_updated_at
  BEFORE UPDATE ON suppliers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User login bisa baca supplier"
  ON suppliers FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admin & gudang bisa kelola supplier"
  ON suppliers FOR ALL
  USING (get_my_role() IN ('admin', 'staff_gudang'));

-- ── 6. Tabel PRODUCTS ────────────────────────────────────────
CREATE TABLE products (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  kode        TEXT        NOT NULL UNIQUE,
  nama        TEXT        NOT NULL,
  deskripsi   TEXT,
  stok        NUMERIC(15,3) NOT NULL DEFAULT 0 CHECK (stok >= 0),
  satuan      TEXT        NOT NULL DEFAULT 'pcs',
  aktif       BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_products_nama ON products USING gin (to_tsvector('simple', nama));
CREATE INDEX idx_products_kode ON products (kode);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User login bisa baca produk"
  ON products FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admin & gudang bisa kelola produk"
  ON products FOR ALL
  USING (get_my_role() IN ('admin', 'staff_gudang'));

-- ── 7. Tabel PRODUCT_PRICES ──────────────────────────────────
CREATE TABLE product_prices (
  id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id  UUID          NOT NULL REFERENCES products(id)  ON DELETE CASCADE,
  supplier_id UUID          NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
  stok        NUMERIC(15,3) NOT NULL DEFAULT 0 CHECK (stok >= 0),
  harga_beli  NUMERIC(15,2) NOT NULL DEFAULT 0,
  aktif       BOOLEAN       NOT NULL DEFAULT TRUE,
  updated_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  UNIQUE (product_id, supplier_id)
);

CREATE TRIGGER trg_prices_updated_at
  BEFORE UPDATE ON product_prices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE product_prices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User login bisa baca harga"
  ON product_prices FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admin & gudang bisa kelola harga"
  ON product_prices FOR ALL
  USING (get_my_role() IN ('admin', 'staff_gudang'));

-- ── 8. Tabel PURCHASES (Header Pembelian) ────────────────────
CREATE TABLE purchases (
  id                     UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  no_order               TEXT          NOT NULL UNIQUE,
  order_date             DATE          NOT NULL DEFAULT CURRENT_DATE,
  no_faktur              TEXT,
  supplier_id            UUID          REFERENCES suppliers(id) ON DELETE SET NULL,
  supplier_nama          TEXT,
  supplier_alamat        TEXT,
  terms                  TEXT,
  subtotal               NUMERIC(15,2) NOT NULL DEFAULT 0,
  status                 TEXT          NOT NULL DEFAULT 'ordered'
                                      CHECK (status IN ('draft', 'ordered', 'received')),
  received_at            TIMESTAMPTZ,
  receiving_validations  JSONB         NOT NULL DEFAULT '{}'::jsonb,
  receiving_validated_at JSONB         NOT NULL DEFAULT '{}'::jsonb,
  request_fingerprint    TEXT,
  created_at             TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_purchases_updated_at
  BEFORE UPDATE ON purchases
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_purchases_order_date ON purchases (order_date);
CREATE INDEX idx_purchases_status ON purchases (status);
CREATE INDEX idx_purchases_supplier_id ON purchases (supplier_id);

ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User login bisa baca purchases"
  ON purchases FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admin, gudang & kantor bisa kelola purchases"
  ON purchases FOR ALL
  USING (get_my_role() IN ('admin', 'staff_gudang', 'staff_kantor'));

-- ── 9. Tabel PURCHASE_ITEMS (Detail Pembelian) ───────────────
CREATE TABLE purchase_items (
  id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_id   UUID          NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
  product_id    UUID          REFERENCES products(id) ON DELETE SET NULL,
  product_kode  TEXT          NOT NULL DEFAULT '',
  product_nama  TEXT          NOT NULL,
  qty           NUMERIC(15,3) NOT NULL CHECK (qty > 0),
  unit_cost     NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (unit_cost >= 0),
  total         NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
  receiving_key TEXT,
  created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_purchase_items_updated_at
  BEFORE UPDATE ON purchase_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_purchase_items_purchase_id ON purchase_items (purchase_id);
CREATE INDEX idx_purchase_items_product_id ON purchase_items (product_id);

ALTER TABLE purchase_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User login bisa baca purchase items"
  ON purchase_items FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admin, gudang & kantor bisa kelola purchase items"
  ON purchase_items FOR ALL
  USING (get_my_role() IN ('admin', 'staff_gudang', 'staff_kantor'));

-- ── 10. Tabel CUSTOMERS ──────────────────────────────────────
CREATE TABLE customers (
  id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  kode          TEXT          NOT NULL UNIQUE,
  nama          TEXT          NOT NULL,
  alamat        TEXT,
  no_telp       TEXT,
  limit_kredit  NUMERIC(15,2) NOT NULL DEFAULT 10000000,
  saldo_piutang NUMERIC(15,2) NOT NULL DEFAULT 0,
  aktif         BOOLEAN       NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_customers_updated_at
  BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_customers_nama ON customers USING gin (to_tsvector('simple', nama));

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User login bisa baca customer"
  ON customers FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admin & kantor bisa kelola customer"
  ON customers FOR ALL
  USING (get_my_role() IN ('admin', 'staff_kantor'));
