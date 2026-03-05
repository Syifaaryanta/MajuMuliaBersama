-- ============================================================
-- 06_sales_schema.sql  —  MMB (Maju Mulia Bersama)
-- Schema untuk Penjualan (Sales) dan Item Penjualan
-- Jalankan di: Supabase Dashboard → SQL Editor
-- ============================================================

-- ── 1. Tabel SALES (Header Penjualan) ───────────────────────
CREATE TABLE IF NOT EXISTS sales (
  id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  no_order      TEXT          NOT NULL UNIQUE,
  order_date    DATE          NOT NULL DEFAULT CURRENT_DATE,
  customer_id   UUID          NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
  customer_nama TEXT          NOT NULL, -- Denormalisasi untuk performa
  customer_alamat TEXT,               -- Snapshot alamat saat order
  customer_telp TEXT,                 -- Snapshot telp saat order
  diantar       BOOLEAN       NOT NULL DEFAULT TRUE,  -- TRUE=diantar, FALSE=diambil
  limit_bulan   INTEGER       NOT NULL DEFAULT 0,     -- 0=1 bulan, 1=2 bulan, 2=3 bulan
  salesman      TEXT          NOT NULL DEFAULT 'A',   -- A, B, C, D, E (hardcoded dulu)
  subtotal      NUMERIC(15,2) NOT NULL DEFAULT 0,
  status        TEXT          NOT NULL DEFAULT 'draft', -- draft, completed
  created_by    UUID          REFERENCES auth.users(id),
  created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sales_no_order ON sales (no_order);
CREATE INDEX IF NOT EXISTS idx_sales_order_date ON sales (order_date);
CREATE INDEX IF NOT EXISTS idx_sales_customer ON sales (customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_status ON sales (status);

DROP TRIGGER IF EXISTS trg_sales_updated_at ON sales;
CREATE TRIGGER trg_sales_updated_at
  BEFORE UPDATE ON sales
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE sales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "User login bisa baca sales" ON sales;
CREATE POLICY "User login bisa baca sales"
  ON sales FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Admin, kantor & sales bisa kelola sales" ON sales;
CREATE POLICY "Admin, kantor & sales bisa kelola sales"
  ON sales FOR ALL
  USING (get_my_role() IN ('admin', 'staff_kantor', 'sales'));

-- ── 2. Tabel SALE_ITEMS (Detail Item Penjualan) ─────────────
CREATE TABLE IF NOT EXISTS sale_items (
  id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id     UUID          NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id  UUID          NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  product_kode TEXT         NOT NULL, -- Denormalisasi
  product_nama TEXT         NOT NULL, -- Denormalisasi
  qty         INTEGER       NOT NULL CHECK (qty > 0),
  unit_price  NUMERIC(15,2) NOT NULL CHECK (unit_price >= 0),
  total       NUMERIC(15,2) NOT NULL CHECK (total >= 0),
  created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items (sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_product ON sale_items (product_id);

ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "User login bisa baca sale items" ON sale_items;
CREATE POLICY "User login bisa baca sale items"
  ON sale_items FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Admin, kantor & sales bisa kelola sale items" ON sale_items;
CREATE POLICY "Admin, kantor & sales bisa kelola sale items"
  ON sale_items FOR ALL
  USING (get_my_role() IN ('admin', 'staff_kantor', 'sales'));

-- ── 3. Fungsi Generate No Order (Format: YYXXXXX) ───────────
CREATE OR REPLACE FUNCTION generate_no_order()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  tahun TEXT;
  last_no INTEGER;
  new_no TEXT;
BEGIN
  -- Ambil 2 digit tahun terakhir (misal: 2026 → 26)
  tahun := TO_CHAR(CURRENT_DATE, 'YY');
  
  -- Cari nomor order terakhir di tahun yang sama
  SELECT COALESCE(
    MAX(CAST(SUBSTRING(no_order FROM 3) AS INTEGER)),
    0
  )
  INTO last_no
  FROM sales
  WHERE no_order LIKE tahun || '%';
  
  -- Generate nomor baru (format: YYXXXXX, misal: 2600001)
  new_no := tahun || LPAD((last_no + 1)::TEXT, 5, '0');
  
  RETURN new_no;
END;
$$;

-- ── 4. Trigger untuk Auto-fill No Order ──────────────────────
CREATE OR REPLACE FUNCTION auto_generate_no_order()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.no_order IS NULL OR NEW.no_order = '' THEN
    NEW.no_order := generate_no_order();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_no_order ON sales;
CREATE TRIGGER trg_auto_no_order
  BEFORE INSERT ON sales
  FOR EACH ROW
  EXECUTE FUNCTION auto_generate_no_order();

-- ── 5. View untuk Summary Penjualan ──────────────────────────
CREATE OR REPLACE VIEW v_sales_summary AS
SELECT 
  s.id,
  s.no_order,
  s.order_date,
  s.customer_nama,
  s.customer_alamat,
  s.diantar,
  s.limit_bulan,
  s.salesman,
  s.subtotal,
  s.status,
  COUNT(si.id) as total_items,
  SUM(si.qty) as total_qty,
  s.created_at
FROM sales s
LEFT JOIN sale_items si ON s.id = si.sale_id
GROUP BY s.id;

COMMENT ON TABLE sales IS 'Tabel header penjualan';
COMMENT ON TABLE sale_items IS 'Tabel detail item penjualan';
COMMENT ON FUNCTION generate_no_order() IS 'Generate nomor order format YYXXXXX (reset per tahun)';
