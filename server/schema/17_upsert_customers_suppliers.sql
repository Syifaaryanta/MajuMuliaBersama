-- ============================================================
-- 17_upsert_customers_suppliers.sql
-- Tambah / update data master Supplier & Customer (non-destruktif)
-- Jalankan di: Supabase Dashboard -> SQL Editor
-- ============================================================

BEGIN;

-- Guard kolom kompatibilitas (aman jika sudah ada)
ALTER TABLE public.suppliers
  ADD COLUMN IF NOT EXISTS aktif BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE public.suppliers
  ADD COLUMN IF NOT EXISTS jatuh_tempo_bulan INTEGER;

ALTER TABLE public.suppliers
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS aktif BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS jatuh_tempo_bulan INTEGER;

ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS limit_kredit NUMERIC(15,2) NOT NULL DEFAULT 10000000;

ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS saldo_piutang NUMERIC(15,2) NOT NULL DEFAULT 0;

ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

UPDATE public.suppliers
SET jatuh_tempo_bulan = 1
WHERE jatuh_tempo_bulan IS NULL OR jatuh_tempo_bulan NOT IN (1, 2, 3);

UPDATE public.customers
SET jatuh_tempo_bulan = 1
WHERE jatuh_tempo_bulan IS NULL OR jatuh_tempo_bulan NOT IN (1, 2, 3);

UPDATE public.customers
SET
  limit_kredit = COALESCE(limit_kredit, 10000000),
  saldo_piutang = COALESCE(saldo_piutang, 0)
WHERE limit_kredit IS NULL OR saldo_piutang IS NULL;

ALTER TABLE public.suppliers
  ALTER COLUMN jatuh_tempo_bulan SET DEFAULT 1,
  ALTER COLUMN jatuh_tempo_bulan SET NOT NULL;

ALTER TABLE public.customers
  ALTER COLUMN jatuh_tempo_bulan SET DEFAULT 1,
  ALTER COLUMN jatuh_tempo_bulan SET NOT NULL;

ALTER TABLE public.customers
  ALTER COLUMN limit_kredit SET DEFAULT 10000000,
  ALTER COLUMN limit_kredit SET NOT NULL,
  ALTER COLUMN saldo_piutang SET DEFAULT 0,
  ALTER COLUMN saldo_piutang SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'suppliers_jatuh_tempo_bulan_check'
  ) THEN
    ALTER TABLE public.suppliers
      ADD CONSTRAINT suppliers_jatuh_tempo_bulan_check
      CHECK (jatuh_tempo_bulan IN (1, 2, 3));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'customers_jatuh_tempo_bulan_check'
  ) THEN
    ALTER TABLE public.customers
      ADD CONSTRAINT customers_jatuh_tempo_bulan_check
      CHECK (jatuh_tempo_bulan IN (1, 2, 3));
  END IF;
END $$;

-- ============================================================
-- DATA SUPPLIER
-- Edit daftar ini sesuai kebutuhan.
-- ============================================================
CREATE TEMP TABLE tmp_suppliers_input (
  kode TEXT PRIMARY KEY,
  nama TEXT NOT NULL,
  alamat TEXT,
  no_telp TEXT,
  jatuh_tempo_bulan INTEGER NOT NULL DEFAULT 1,
  aktif BOOLEAN NOT NULL DEFAULT TRUE
) ON COMMIT DROP;

INSERT INTO tmp_suppliers_input (kode, nama, alamat, no_telp, jatuh_tempo_bulan, aktif) VALUES
  ('SUP-001', 'Denso',  'Jl. Industri No. 1, Jakarta',   '02112340001', 1, TRUE),
  ('SUP-002', 'Valeo',  'Jl. Raya No. 20, Bekasi',       '02112340002', 1, TRUE),
  ('SUP-003', 'Sanden', 'Jl. Gatot Subroto No. 5, Depok','02112340003', 1, TRUE);

WITH src AS (
  SELECT
    TRIM(kode) AS kode,
    TRIM(nama) AS nama,
    NULLIF(TRIM(alamat), '') AS alamat,
    NULLIF(TRIM(no_telp), '') AS no_telp,
    CASE WHEN jatuh_tempo_bulan IN (1, 2, 3) THEN jatuh_tempo_bulan ELSE 1 END AS jatuh_tempo_bulan,
    aktif
  FROM tmp_suppliers_input
)
UPDATE public.suppliers s
SET
  nama = src.nama,
  alamat = src.alamat,
  no_telp = src.no_telp,
  jatuh_tempo_bulan = src.jatuh_tempo_bulan,
  aktif = src.aktif,
  updated_at = NOW()
FROM src
WHERE s.kode = src.kode;

WITH src AS (
  SELECT
    TRIM(kode) AS kode,
    TRIM(nama) AS nama,
    NULLIF(TRIM(alamat), '') AS alamat,
    NULLIF(TRIM(no_telp), '') AS no_telp,
    CASE WHEN jatuh_tempo_bulan IN (1, 2, 3) THEN jatuh_tempo_bulan ELSE 1 END AS jatuh_tempo_bulan,
    aktif
  FROM tmp_suppliers_input
)
INSERT INTO public.suppliers (kode, nama, alamat, no_telp, jatuh_tempo_bulan, aktif)
SELECT
  src.kode,
  src.nama,
  src.alamat,
  src.no_telp,
  src.jatuh_tempo_bulan,
  src.aktif
FROM src
WHERE NOT EXISTS (
  SELECT 1 FROM public.suppliers s WHERE s.kode = src.kode
);

-- ============================================================
-- DATA CUSTOMER
-- Edit daftar ini sesuai kebutuhan.
-- ============================================================
CREATE TEMP TABLE tmp_customers_input (
  kode TEXT PRIMARY KEY,
  nama TEXT NOT NULL,
  alamat TEXT,
  no_telp TEXT,
  limit_kredit NUMERIC(15,2),
  jatuh_tempo_bulan INTEGER NOT NULL DEFAULT 1,
  aktif BOOLEAN NOT NULL DEFAULT TRUE
) ON COMMIT DROP;

INSERT INTO tmp_customers_input (kode, nama, alamat, no_telp, limit_kredit, jatuh_tempo_bulan, aktif) VALUES
  ('CST-001', 'Bengkel Maju Jaya',    'Jl. Raya No. 10, Bekasi',      '08112345001', 10000000, 1, TRUE),
  ('CST-002', 'AC Mobil Cepat',       'Jl. Sudirman No. 5, Depok',     '08112345002', 10000000, 1, TRUE),
  ('CST-003', 'Toko Sparepart Prima', 'Jl. Gatot Subroto, Bogor',      '08112345003', 20000000, 1, TRUE),
  ('CST-004', 'Bengkel Amanah',       'Jl. Pahlawan No. 33, Bekasi',   '08112345004', 10000000, 1, TRUE),
  ('CST-005', 'Global Auto Parts',    'Jl. MT Haryono No. 7, Jakarta', '08112345005', 20000000, 1, TRUE);

WITH src AS (
  SELECT
    TRIM(kode) AS kode,
    TRIM(nama) AS nama,
    NULLIF(TRIM(alamat), '') AS alamat,
    NULLIF(TRIM(no_telp), '') AS no_telp,
    COALESCE(limit_kredit, 10000000) AS limit_kredit,
    CASE WHEN jatuh_tempo_bulan IN (1, 2, 3) THEN jatuh_tempo_bulan ELSE 1 END AS jatuh_tempo_bulan,
    aktif
  FROM tmp_customers_input
)
UPDATE public.customers c
SET
  nama = src.nama,
  alamat = src.alamat,
  no_telp = src.no_telp,
  limit_kredit = src.limit_kredit,
  jatuh_tempo_bulan = src.jatuh_tempo_bulan,
  aktif = src.aktif,
  updated_at = NOW()
FROM src
WHERE c.kode = src.kode;

WITH src AS (
  SELECT
    TRIM(kode) AS kode,
    TRIM(nama) AS nama,
    NULLIF(TRIM(alamat), '') AS alamat,
    NULLIF(TRIM(no_telp), '') AS no_telp,
    COALESCE(limit_kredit, 10000000) AS limit_kredit,
    CASE WHEN jatuh_tempo_bulan IN (1, 2, 3) THEN jatuh_tempo_bulan ELSE 1 END AS jatuh_tempo_bulan,
    aktif
  FROM tmp_customers_input
)
INSERT INTO public.customers (kode, nama, alamat, no_telp, limit_kredit, jatuh_tempo_bulan, aktif)
SELECT
  src.kode,
  src.nama,
  src.alamat,
  src.no_telp,
  src.limit_kredit,
  src.jatuh_tempo_bulan,
  src.aktif
FROM src
WHERE NOT EXISTS (
  SELECT 1 FROM public.customers c WHERE c.kode = src.kode
);

-- Minta PostgREST refresh schema cache agar kolom baru langsung dikenali.
NOTIFY pgrst, 'reload schema';

COMMIT;
