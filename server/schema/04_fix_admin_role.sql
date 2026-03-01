-- ============================================================
-- 04_fix_admin_role.sql
-- Perbaiki role admin untuk user admin@mmb.com
-- ============================================================

-- Cek apakah ada user auth dengan email admin@mmb.com
DO $$
DECLARE
  admin_id UUID;
BEGIN
  -- Cari ID user admin
  SELECT id INTO admin_id 
  FROM auth.users 
  WHERE email = 'admin@mmb.com';
  
  IF admin_id IS NULL THEN
    RAISE NOTICE 'User admin@mmb.com tidak ditemukan di auth.users!';
    RAISE NOTICE 'Silakan buat user admin@mmb.com di Supabase Authentication terlebih dahulu.';
  ELSE
    RAISE NOTICE 'User admin@mmb.com ditemukan dengan ID: %', admin_id;
    
    -- Pastikan profile ada dan role-nya 'admin'
    INSERT INTO profiles (id, email, nama, role, aktif)
    VALUES (admin_id, 'admin@mmb.com', 'Administrator', 'admin', true)
    ON CONFLICT (id) DO UPDATE 
    SET role = 'admin', 
        aktif = true,
        nama = CASE WHEN profiles.nama = '' THEN 'Administrator' ELSE profiles.nama END;
    
    RAISE NOTICE 'Profile admin berhasil diperbaiki!';
  END IF;
END $$;

-- Verifikasi hasil
SELECT id, email, nama, role, aktif 
FROM profiles 
WHERE email = 'admin@mmb.com';
