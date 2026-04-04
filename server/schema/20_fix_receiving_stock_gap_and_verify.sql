-- ============================================================
-- 20_fix_receiving_stock_gap_and_verify.sql
-- Perbaiki gap stok products vs product_prices + verifikasi schema
-- Jalankan di: Supabase Dashboard -> SQL Editor
-- ============================================================

BEGIN;

DO $$
BEGIN
  IF to_regclass('public.purchases') IS NULL OR to_regclass('public.purchase_items') IS NULL THEN
    RAISE EXCEPTION 'Tabel purchases/purchase_items belum ada. Jalankan 19_fix_receiving_and_barang_history_db_alignment.sql terlebih dahulu.';
  END IF;
END $$;

-- Guard kolom agar kompatibel.
ALTER TABLE public.purchases
  ADD COLUMN IF NOT EXISTS receiving_validations JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS receiving_validated_at JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE public.purchase_items
  ADD COLUMN IF NOT EXISTS receiving_key TEXT;

ALTER TABLE public.product_prices
  ADD COLUMN IF NOT EXISTS aktif BOOLEAN NOT NULL DEFAULT TRUE;

-- 1) Jika stok products lebih besar dari total stok aktif product_prices,
--    selisih (gap) dipindahkan ke salah satu baris supplier aktif.
WITH totals AS (
  SELECT
    p.id AS product_id,
    COALESCE(p.stok, 0) AS product_stok,
    COALESCE(SUM(CASE WHEN COALESCE(pp.aktif, TRUE) THEN COALESCE(pp.stok, 0) ELSE 0 END), 0) AS total_active_price_stok
  FROM public.products p
  LEFT JOIN public.product_prices pp ON pp.product_id = p.id
  GROUP BY p.id, p.stok
),
ranked_rows AS (
  SELECT
    pp.id,
    pp.product_id,
    ROW_NUMBER() OVER (
      PARTITION BY pp.product_id
      ORDER BY COALESCE(pp.updated_at, NOW()) DESC, pp.id DESC
    ) AS rn
  FROM public.product_prices pp
  WHERE COALESCE(pp.aktif, TRUE) = TRUE
),
gaps AS (
  SELECT
    t.product_id,
    GREATEST(t.product_stok - t.total_active_price_stok, 0) AS gap
  FROM totals t
  WHERE t.product_stok > t.total_active_price_stok
),
targets AS (
  SELECT
    r.id AS price_row_id,
    g.gap
  FROM ranked_rows r
  JOIN gaps g ON g.product_id = r.product_id
  WHERE r.rn = 1
)
UPDATE public.product_prices pp
SET
  stok = COALESCE(pp.stok, 0) + targets.gap,
  updated_at = NOW()
FROM targets
WHERE pp.id = targets.price_row_id
  AND targets.gap > 0;

-- 2) Selaraskan products.stok dengan total stok aktif product_prices.
WITH totals AS (
  SELECT
    pp.product_id,
    COALESCE(SUM(CASE WHEN COALESCE(pp.aktif, TRUE) THEN COALESCE(pp.stok, 0) ELSE 0 END), 0) AS total_active_price_stok
  FROM public.product_prices pp
  GROUP BY pp.product_id
)
UPDATE public.products p
SET
  stok = totals.total_active_price_stok,
  updated_at = NOW()
FROM totals
WHERE p.id = totals.product_id
  AND COALESCE(p.stok, 0) IS DISTINCT FROM totals.total_active_price_stok;

NOTIFY pgrst, 'reload schema';

COMMIT;

-- ============================================================
-- Verifikasi setelah perbaikan
-- ============================================================

-- A) Cek mismatch stok products vs sum product_prices aktif.
WITH totals AS (
  SELECT
    p.id,
    p.kode,
    p.nama,
    COALESCE(p.stok, 0) AS product_stok,
    COALESCE(SUM(CASE WHEN COALESCE(pp.aktif, TRUE) THEN COALESCE(pp.stok, 0) ELSE 0 END), 0) AS total_active_price_stok
  FROM public.products p
  LEFT JOIN public.product_prices pp ON pp.product_id = p.id
  GROUP BY p.id, p.kode, p.nama, p.stok
)
SELECT *
FROM totals
WHERE product_stok <> total_active_price_stok
ORDER BY nama;

-- B) Cek order pembelian yang belum punya item.
SELECT
  p.no_order,
  p.status,
  p.order_date,
  p.received_at
FROM public.purchases p
LEFT JOIN public.purchase_items pi ON pi.purchase_id = p.id
GROUP BY p.id, p.no_order, p.status, p.order_date, p.received_at
HAVING COUNT(pi.id) = 0
ORDER BY p.order_date DESC;

-- C) Cek item pembelian yang receiving_key masih kosong.
SELECT
  p.no_order,
  pi.product_kode,
  pi.product_nama,
  pi.qty
FROM public.purchase_items pi
JOIN public.purchases p ON p.id = pi.purchase_id
WHERE COALESCE(BTRIM(pi.receiving_key), '') = ''
ORDER BY p.order_date DESC;

-- D) Cek produk dengan stok > 0 tapi belum punya supplier aktif.
SELECT
  p.id,
  p.kode,
  p.nama,
  p.stok
FROM public.products p
WHERE COALESCE(p.stok, 0) > 0
  AND NOT EXISTS (
    SELECT 1
    FROM public.product_prices pp
    WHERE pp.product_id = p.id
      AND COALESCE(pp.aktif, TRUE) = TRUE
  )
ORDER BY p.nama;
