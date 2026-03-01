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
  stok        INTEGER     NOT NULL DEFAULT 0 CHECK (stok >= 0),
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
  stok        INTEGER       NOT NULL DEFAULT 0 CHECK (stok >= 0),
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

-- ── 8. Tabel CUSTOMERS ───────────────────────────────────────
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
