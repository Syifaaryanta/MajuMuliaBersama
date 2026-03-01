-- ============================================================
-- 05_add_foto_urls.sql  —  Menambahkan kolom foto untuk products
-- Jalankan di: Supabase Dashboard → SQL Editor
-- ============================================================

-- Menambahkan kolom foto_urls bertipe TEXT[] (array of text)
-- untuk menyimpan URL foto dari Cloudinary (max 3 foto per produk)
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS foto_urls TEXT[] DEFAULT '{}';

-- Membuat index untuk optimasi query
CREATE INDEX IF NOT EXISTS idx_products_foto_urls ON products USING GIN (foto_urls);

-- Menambahkan comment untuk dokumentasi
COMMENT ON COLUMN products.foto_urls IS 'Array URL foto produk dari Cloudinary (max 3 foto)';
