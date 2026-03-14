-- ============================================================
-- 02_seed.sql  —  MMB (Maju Mulia Bersama)
-- Data awal: Supplier, Customer
-- Jalankan SETELAH 01_schema.sql
-- ============================================================

-- ── Reset data BARANG & TRANSAKSI (profiles/suppliers/customers tetap) ──
-- Khusus untuk mengosongkan data halaman Barang dan data turunannya.
DO $$
BEGIN
  IF to_regclass('public.sale_items') IS NOT NULL THEN
    DELETE FROM sale_items;
  END IF;

  IF to_regclass('public.sales') IS NOT NULL THEN
    DELETE FROM sales;
  END IF;

  IF to_regclass('public.purchase_items') IS NOT NULL THEN
    DELETE FROM purchase_items;
  END IF;

  IF to_regclass('public.purchases') IS NOT NULL THEN
    DELETE FROM purchases;
  END IF;

  IF to_regclass('public.product_prices') IS NOT NULL THEN
    DELETE FROM product_prices;
  END IF;

  IF to_regclass('public.products') IS NOT NULL THEN
    DELETE FROM products;
  END IF;
END $$;

-- ── Supplier ─────────────────────────────────────────────────
INSERT INTO suppliers (kode, nama, alamat, no_telp) VALUES
  ('SUP-001', 'Supplier A — Denso',   'Jl. Industri No. 1, Jakarta',  '02112340001'),
  ('SUP-002', 'Supplier B — Valeo',   'Jl. Raya No. 20, Bekasi',      '02112340002'),
  ('SUP-003', 'Supplier C — Sanden',  'Jl. Gatot Subroto No. 5, Depok','02112340003')
ON CONFLICT (kode) DO NOTHING;

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
