-- ============================================================
-- 02_seed.sql  —  MMB (Maju Mulia Bersama)
-- Data awal: Supplier, Produk, Harga, Customer
-- Jalankan SETELAH 01_schema.sql
-- ============================================================

-- ── Supplier ─────────────────────────────────────────────────
INSERT INTO suppliers (kode, nama, alamat, no_telp) VALUES
  ('SUP-001', 'Supplier A — Denso',   'Jl. Industri No. 1, Jakarta',  '02112340001'),
  ('SUP-002', 'Supplier B — Valeo',   'Jl. Raya No. 20, Bekasi',      '02112340002'),
  ('SUP-003', 'Supplier C — Sanden',  'Jl. Gatot Subroto No. 5, Depok','02112340003')
ON CONFLICT (kode) DO NOTHING;

-- ── Produk & Harga ────────────────────────────────────────────
DO $$
DECLARE
  s1 UUID; s2 UUID; s3 UUID;
  p  UUID;
BEGIN
  SELECT id INTO s1 FROM suppliers WHERE kode = 'SUP-001';
  SELECT id INTO s2 FROM suppliers WHERE kode = 'SUP-002';
  SELECT id INTO s3 FROM suppliers WHERE kode = 'SUP-003';

  -- ────────────────────────────────────────────────────
  -- CONDENSOR (5)
  -- ────────────────────────────────────────────────────

  -- CDX-001 · CONDENSOR AVANZA DENSO — 1 supplier  
  INSERT INTO products (kode, nama, stok, satuan)
    VALUES ('CDX-001', 'CONDENSOR AVANZA DENSO', 10, 'pcs')
    ON CONFLICT (kode) DO UPDATE SET nama = EXCLUDED.nama, stok = EXCLUDED.stok RETURNING id INTO p;
  IF p IS NULL THEN SELECT id INTO p FROM products WHERE kode = 'CDX-001'; END IF;
  INSERT INTO product_prices (product_id, supplier_id, stok, harga_beli)
    VALUES (p, s1, 10, 310000)
    ON CONFLICT (product_id, supplier_id) DO UPDATE SET stok = EXCLUDED.stok, harga_beli = EXCLUDED.harga_beli;

  -- CDX-002 · CONDENSOR XENIA STD — 2 supplier (5 + 3 = 8)
  INSERT INTO products (kode, nama, stok, satuan)
    VALUES ('CDX-002', 'CONDENSOR XENIA STD', 8, 'pcs')
    ON CONFLICT (kode) DO UPDATE SET nama = EXCLUDED.nama, stok = EXCLUDED.stok RETURNING id INTO p;
  IF p IS NULL THEN SELECT id INTO p FROM products WHERE kode = 'CDX-002'; END IF;
  INSERT INTO product_prices (product_id, supplier_id, stok, harga_beli)
    VALUES (p, s1, 5, 250000), (p, s2, 3, 265000)
    ON CONFLICT (product_id, supplier_id) DO UPDATE SET stok = EXCLUDED.stok, harga_beli = EXCLUDED.harga_beli;

  -- CDX-003 · CONDENSOR INNOVA VALEO — 2 supplier (4 + 2 = 6)
  INSERT INTO products (kode, nama, stok, satuan)
    VALUES ('CDX-003', 'CONDENSOR INNOVA VALEO', 6, 'pcs')
    ON CONFLICT (kode) DO UPDATE SET nama = EXCLUDED.nama, stok = EXCLUDED.stok RETURNING id INTO p;
  IF p IS NULL THEN SELECT id INTO p FROM products WHERE kode = 'CDX-003'; END IF;
  INSERT INTO product_prices (product_id, supplier_id, stok, harga_beli)
    VALUES (p, s2, 4, 420000), (p, s3, 2, 405000)
    ON CONFLICT (product_id, supplier_id) DO UPDATE SET stok = EXCLUDED.stok, harga_beli = EXCLUDED.harga_beli;

  -- CDX-004 · CONDENSOR XENIA MODENAS — 3 supplier (2 + 1 + 1 = 4)
  INSERT INTO products (kode, nama, stok, satuan)
    VALUES ('CDX-004', 'CONDENSOR XENIA MODENAS', 4, 'pcs')
    ON CONFLICT (kode) DO UPDATE SET nama = EXCLUDED.nama, stok = EXCLUDED.stok RETURNING id INTO p;
  IF p IS NULL THEN SELECT id INTO p FROM products WHERE kode = 'CDX-004'; END IF;
  INSERT INTO product_prices (product_id, supplier_id, stok, harga_beli)
    VALUES (p, s1, 2, 275000), (p, s2, 1, 285000), (p, s3, 1, 268000)
    ON CONFLICT (product_id, supplier_id) DO UPDATE SET stok = EXCLUDED.stok, harga_beli = EXCLUDED.harga_beli;

  -- CDX-005 · CONDENSOR JAZZ SANDEN — 1 supplier
  INSERT INTO products (kode, nama, stok, satuan)
    VALUES ('CDX-005', 'CONDENSOR JAZZ SANDEN', 9, 'pcs')
    ON CONFLICT (kode) DO UPDATE SET nama = EXCLUDED.nama, stok = EXCLUDED.stok RETURNING id INTO p;
  IF p IS NULL THEN SELECT id INTO p FROM products WHERE kode = 'CDX-005'; END IF;
  INSERT INTO product_prices (product_id, supplier_id, stok, harga_beli)
    VALUES (p, s3, 9, 345000)
    ON CONFLICT (product_id, supplier_id) DO UPDATE SET stok = EXCLUDED.stok, harga_beli = EXCLUDED.harga_beli;

  -- ────────────────────────────────────────────────────
  -- COMPRESSOR (3)
  -- ────────────────────────────────────────────────────

  -- CPR-001 · COMPRESSOR INNOVA DENSO — 1 supplier
  INSERT INTO products (kode, nama, stok, satuan)
    VALUES ('CPR-001', 'COMPRESSOR INNOVA DENSO', 3, 'pcs')
    ON CONFLICT (kode) DO UPDATE SET nama = EXCLUDED.nama, stok = EXCLUDED.stok RETURNING id INTO p;
  IF p IS NULL THEN SELECT id INTO p FROM products WHERE kode = 'CPR-001'; END IF;
  INSERT INTO product_prices (product_id, supplier_id, stok, harga_beli)
    VALUES (p, s3, 3, 1850000)
    ON CONFLICT (product_id, supplier_id) DO UPDATE SET stok = EXCLUDED.stok, harga_beli = EXCLUDED.harga_beli;

  -- CPR-002 · COMPRESSOR XENIA SANDEN — 2 supplier (3 + 2 = 5)
  INSERT INTO products (kode, nama, stok, satuan)
    VALUES ('CPR-002', 'COMPRESSOR XENIA SANDEN', 5, 'pcs')
    ON CONFLICT (kode) DO UPDATE SET nama = EXCLUDED.nama, stok = EXCLUDED.stok RETURNING id INTO p;
  IF p IS NULL THEN SELECT id INTO p FROM products WHERE kode = 'CPR-002'; END IF;
  INSERT INTO product_prices (product_id, supplier_id, stok, harga_beli)
    VALUES (p, s1, 3, 1650000), (p, s2, 2, 1720000)
    ON CONFLICT (product_id, supplier_id) DO UPDATE SET stok = EXCLUDED.stok, harga_beli = EXCLUDED.harga_beli;

  -- CPR-003 · COMPRESSOR AVANZA ZEXEL — 3 supplier (3 + 2 + 2 = 7)
  INSERT INTO products (kode, nama, stok, satuan)
    VALUES ('CPR-003', 'COMPRESSOR AVANZA ZEXEL', 7, 'pcs')
    ON CONFLICT (kode) DO UPDATE SET nama = EXCLUDED.nama, stok = EXCLUDED.stok RETURNING id INTO p;
  IF p IS NULL THEN SELECT id INTO p FROM products WHERE kode = 'CPR-003'; END IF;
  INSERT INTO product_prices (product_id, supplier_id, stok, harga_beli)
    VALUES (p, s1, 3, 1580000), (p, s2, 2, 1600000), (p, s3, 2, 1560000)
    ON CONFLICT (product_id, supplier_id) DO UPDATE SET stok = EXCLUDED.stok, harga_beli = EXCLUDED.harga_beli;

  -- ────────────────────────────────────────────────────
  -- EXPANSION VALVE (3)
  -- ────────────────────────────────────────────────────

  -- EXV-001 · EXPANSION VALVE AVANZA — 2 supplier (7 + 5 = 12)
  INSERT INTO products (kode, nama, stok, satuan)
    VALUES ('EXV-001', 'EXPANSION VALVE AVANZA', 12, 'pcs')
    ON CONFLICT (kode) DO UPDATE SET nama = EXCLUDED.nama, stok = EXCLUDED.stok RETURNING id INTO p;
  IF p IS NULL THEN SELECT id INTO p FROM products WHERE kode = 'EXV-001'; END IF;
  INSERT INTO product_prices (product_id, supplier_id, stok, harga_beli)
    VALUES (p, s1, 7, 185000), (p, s2, 5, 195000)
    ON CONFLICT (product_id, supplier_id) DO UPDATE SET stok = EXCLUDED.stok, harga_beli = EXCLUDED.harga_beli;

  -- EXV-002 · EXPANSION VALVE XENIA DENSO — 2 supplier (5 + 3 = 8)
  INSERT INTO products (kode, nama, stok, satuan)
    VALUES ('EXV-002', 'EXPANSION VALVE XENIA DENSO', 8, 'pcs')
    ON CONFLICT (kode) DO UPDATE SET nama = EXCLUDED.nama, stok = EXCLUDED.stok RETURNING id INTO p;
  IF p IS NULL THEN SELECT id INTO p FROM products WHERE kode = 'EXV-002'; END IF;
  INSERT INTO product_prices (product_id, supplier_id, stok, harga_beli)
    VALUES (p, s2, 5, 215000), (p, s3, 3, 205000)
    ON CONFLICT (product_id, supplier_id) DO UPDATE SET stok = EXCLUDED.stok, harga_beli = EXCLUDED.harga_beli;

  -- EXV-003 · EXPANSION VALVE INNOVA TGK — 1 supplier
  INSERT INTO products (kode, nama, stok, satuan)
    VALUES ('EXV-003', 'EXPANSION VALVE INNOVA TGK', 5, 'pcs')
    ON CONFLICT (kode) DO UPDATE SET nama = EXCLUDED.nama, stok = EXCLUDED.stok RETURNING id INTO p;
  IF p IS NULL THEN SELECT id INTO p FROM products WHERE kode = 'EXV-003'; END IF;
  INSERT INTO product_prices (product_id, supplier_id, stok, harga_beli)
    VALUES (p, s1, 5, 230000)
    ON CONFLICT (product_id, supplier_id) DO UPDATE SET stok = EXCLUDED.stok, harga_beli = EXCLUDED.harga_beli;

END $$;

-- ── Customer ─────────────────────────────────────────────────
-- CST-001..003 → akan ada histori beli saat modul Penjualan diimplementasi
-- CST-004..005 → customer baru, belum pernah beli
INSERT INTO customers (kode, nama, alamat, no_telp, limit_kredit) VALUES
  ('CST-001', 'Bengkel Maju Jaya',      'Jl. Raya No. 10, Bekasi',        '08112345001', 15000000),
  ('CST-002', 'AC Mobil Cepat',         'Jl. Sudirman No. 5, Depok',       '08112345002', 10000000),
  ('CST-003', 'Toko Sparepart Prima',   'Jl. Gatot Subroto, Bogor',        '08112345003', 20000000),
  ('CST-004', 'Bengkel Amanah',         'Jl. Pahlawan No. 33, Bekasi',     '08112345004',  8000000),
  ('CST-005', 'Global Auto Parts',      'Jl. MT Haryono No. 7, Jakarta',   '08112345005', 25000000)
ON CONFLICT (kode) DO UPDATE SET
  nama         = EXCLUDED.nama,
  limit_kredit = EXCLUDED.limit_kredit;
