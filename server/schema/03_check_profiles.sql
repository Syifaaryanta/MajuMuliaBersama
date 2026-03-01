-- ============================================================
-- 03_check_profiles.sql
-- Script untuk memeriksa dan memperbaiki data profiles
-- ============================================================

-- Cek semua profiles yang ada
SELECT id, email, nama, role, aktif, created_at 
FROM profiles 
ORDER BY created_at;

-- Jika admin@mmb.com belum ada atau role-nya salah, perbaiki:
-- UPDATE profiles 
-- SET role = 'admin', aktif = true
-- WHERE email = 'admin@mmb.com';

-- Atau jika belum ada profile sama sekali untuk admin@mmb.com,
-- Anda perlu membuat user di Supabase Authentication terlebih dahulu,
-- kemudian jalankan ini untuk memastikan profile-nya ada:

-- Cari user_id dari auth.users berdasarkan email
-- SELECT id, email FROM auth.users WHERE email = 'admin@mmb.com';

-- Jika user sudah ada di auth.users tapi tidak ada di profiles,
-- insert manual (ganti <USER_ID> dengan ID yang didapat dari query di atas):
-- INSERT INTO profiles (id, email, nama, role, aktif)
-- VALUES ('<USER_ID>', 'admin@mmb.com', 'Administrator', 'admin', true)
-- ON CONFLICT (id) DO UPDATE 
-- SET role = 'admin', aktif = true;
