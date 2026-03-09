-- ============================================================
-- 07_archive_products.sql  —  MMB (Maju Mulia Bersama)
-- Tambah kolom is_archived pada tabel products
-- Jalankan di: Supabase Dashboard → SQL Editor
-- ============================================================

-- Tambah kolom is_archived ke tabel products
ALTER TABLE products
  ADD COLUMN IF NOT EXISTS is_archived BOOLEAN NOT NULL DEFAULT FALSE;

-- Index untuk filter cepat
CREATE INDEX IF NOT EXISTS idx_products_is_archived ON products (is_archived);

-- Update RLS: tetap menggunakan policy yang sudah ada (tidak perlu perubahan)
-- Kolom is_archived hanya bisa diubah oleh admin & staff_gudang (sudah tercover oleh policy existing)
