-- ============================================================
-- 18_fix_master_data_columns_and_cache.sql
-- Pastikan kolom master-data yang dipakai UI tersedia + refresh cache
-- Jalankan di: Supabase Dashboard -> SQL Editor
-- ============================================================

BEGIN;

-- SUPPLIERS
ALTER TABLE public.suppliers
  ADD COLUMN IF NOT EXISTS aktif BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE public.suppliers
  ADD COLUMN IF NOT EXISTS jatuh_tempo_bulan INTEGER;

UPDATE public.suppliers
SET jatuh_tempo_bulan = 1
WHERE jatuh_tempo_bulan IS NULL OR jatuh_tempo_bulan NOT IN (1, 2, 3);

ALTER TABLE public.suppliers
  ALTER COLUMN jatuh_tempo_bulan SET DEFAULT 1,
  ALTER COLUMN jatuh_tempo_bulan SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'suppliers_jatuh_tempo_bulan_check'
  ) THEN
    ALTER TABLE public.suppliers
      ADD CONSTRAINT suppliers_jatuh_tempo_bulan_check
      CHECK (jatuh_tempo_bulan IN (1, 2, 3));
  END IF;
END $$;

-- CUSTOMERS
ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS aktif BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS jatuh_tempo_bulan INTEGER;

ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS limit_kredit NUMERIC(15,2) NOT NULL DEFAULT 10000000;

ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS saldo_piutang NUMERIC(15,2) NOT NULL DEFAULT 0;

UPDATE public.customers
SET
  jatuh_tempo_bulan = CASE WHEN jatuh_tempo_bulan IN (1, 2, 3) THEN jatuh_tempo_bulan ELSE 1 END,
  limit_kredit = COALESCE(limit_kredit, 10000000),
  saldo_piutang = COALESCE(saldo_piutang, 0);

ALTER TABLE public.customers
  ALTER COLUMN jatuh_tempo_bulan SET DEFAULT 1,
  ALTER COLUMN jatuh_tempo_bulan SET NOT NULL,
  ALTER COLUMN limit_kredit SET DEFAULT 10000000,
  ALTER COLUMN limit_kredit SET NOT NULL,
  ALTER COLUMN saldo_piutang SET DEFAULT 0,
  ALTER COLUMN saldo_piutang SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'customers_jatuh_tempo_bulan_check'
  ) THEN
    ALTER TABLE public.customers
      ADD CONSTRAINT customers_jatuh_tempo_bulan_check
      CHECK (jatuh_tempo_bulan IN (1, 2, 3));
  END IF;
END $$;

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;

-- Verifikasi cepat
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('customers', 'suppliers')
  AND column_name IN ('jatuh_tempo_bulan', 'saldo_piutang', 'limit_kredit', 'aktif')
ORDER BY table_name, column_name;
