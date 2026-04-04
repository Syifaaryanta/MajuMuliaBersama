-- ============================================================
-- 06_sales_schema.sql  —  MMB (Maju Mulia Bersama)
-- Schema untuk Penjualan (Sales) dan Item Penjualan
-- Jalankan di: Supabase Dashboard → SQL Editor
-- ============================================================

-- ── 1. Tabel SALES (Header Penjualan) ───────────────────────
CREATE TABLE IF NOT EXISTS sales (
  id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  no_order      TEXT          NOT NULL UNIQUE,
  no_faktur     TEXT          UNIQUE,
  order_date    DATE          NOT NULL DEFAULT CURRENT_DATE,
  customer_id   UUID          NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
  customer_nama TEXT          NOT NULL, -- Denormalisasi untuk performa
  customer_alamat TEXT,               -- Snapshot alamat saat order
  customer_telp TEXT,                 -- Snapshot telp saat order
  diantar       BOOLEAN       NOT NULL DEFAULT TRUE,  -- TRUE=diantar, FALSE=diambil
  limit_bulan   INTEGER       NOT NULL DEFAULT 0,     -- 0=1 bulan, 1=2 bulan, 2=3 bulan
  extra_charge_desc TEXT,
  extra_charge_amount NUMERIC(15,2) NOT NULL DEFAULT 0,
  sender_note   TEXT,
  subtotal      NUMERIC(15,2) NOT NULL DEFAULT 0,
  status        TEXT          NOT NULL DEFAULT 'draft', -- draft, completed
  created_by    UUID          REFERENCES auth.users(id),
  created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sales_no_order ON sales (no_order);
CREATE INDEX IF NOT EXISTS idx_sales_no_faktur ON sales (no_faktur);
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
  qty         NUMERIC(15,3) NOT NULL CHECK (qty > 0),
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

-- ── 3. Fungsi Generate No Order (Format: YYNNN) ─────────────
CREATE OR REPLACE FUNCTION generate_no_order()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  v_tahun TEXT;
  v_new_no_int INTEGER;
  v_new_no TEXT;
BEGIN
  -- Ambil 2 digit tahun terakhir (misal: 2026 → 26)
  v_tahun := TO_CHAR(CURRENT_DATE, 'YY');

  -- Cari nomor urut terkecil yang belum dipakai di tahun ini (isi celah / gap)
  SELECT s.n INTO v_new_no_int
  FROM generate_series(1, 999) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1
    FROM sales
    WHERE no_order = v_tahun || LPAD(s.n::TEXT, 3, '0')
  )
  ORDER BY s.n
  LIMIT 1;

  -- Fallback (tidak mungkin terjadi jika < 999 order per tahun)
  IF v_new_no_int IS NULL THEN
    v_new_no_int := 1;
  END IF;

  -- Generate nomor baru (format: YYNNN, misal: 26001)
  v_new_no := v_tahun || LPAD(v_new_no_int::TEXT, 3, '0');

  RETURN v_new_no;
END;
$$;

-- ── 4. Counter & Fungsi Generate No Fraktur (Format: YYNNN) ──
CREATE TABLE IF NOT EXISTS sales_faktur_counter (
  tahun     TEXT PRIMARY KEY,
  last_no   INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION generate_no_faktur()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  v_tahun TEXT;
  v_next_no INTEGER;
BEGIN
  v_tahun := TO_CHAR(CURRENT_DATE, 'YY');

  INSERT INTO sales_faktur_counter (tahun, last_no)
  VALUES (v_tahun, 1)
  ON CONFLICT (tahun)
  DO UPDATE SET
    last_no = sales_faktur_counter.last_no + 1,
    updated_at = NOW()
  RETURNING last_no INTO v_next_no;

  RETURN v_tahun || LPAD(v_next_no::TEXT, 3, '0');
END;
$$;

-- ── 5. Trigger untuk Auto-fill No Order ──────────────────────
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

CREATE OR REPLACE FUNCTION auto_generate_no_faktur_on_complete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.status = 'completed' AND (NEW.no_faktur IS NULL OR NEW.no_faktur = '') THEN
    NEW.no_faktur := generate_no_faktur();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_no_order ON sales;
CREATE TRIGGER trg_auto_no_order
  BEFORE INSERT ON sales
  FOR EACH ROW
  EXECUTE FUNCTION auto_generate_no_order();

DROP TRIGGER IF EXISTS trg_auto_no_faktur_on_complete ON sales;
CREATE TRIGGER trg_auto_no_faktur_on_complete
  BEFORE INSERT OR UPDATE ON sales
  FOR EACH ROW
  EXECUTE FUNCTION auto_generate_no_faktur_on_complete();

-- ── 6. View untuk Summary Penjualan ──────────────────────────
DROP VIEW IF EXISTS v_sales_summary;
CREATE VIEW v_sales_summary AS
SELECT 
  s.id,
  s.no_order,
  s.no_faktur,
  s.extra_charge_desc,
  s.extra_charge_amount,
  s.sender_note,
  s.order_date,
  s.customer_nama,
  s.customer_alamat,
  s.diantar,
  s.limit_bulan,
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
COMMENT ON FUNCTION generate_no_order() IS 'Generate nomor order internal format YYNNN (isi celah / gap)';
COMMENT ON FUNCTION generate_no_faktur() IS 'Generate nomor fraktur nota format YYNNN (naik terus, tidak isi gap)';
