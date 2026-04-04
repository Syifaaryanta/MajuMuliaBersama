-- ============================================================
-- 15_restore_missing_profiles.sql
-- Perbaiki kasus profile/role hilang sehingga navigasi kosong
-- Jalankan di: Supabase Dashboard -> SQL Editor
-- ============================================================

BEGIN;

-- 1) Buat profile untuk user auth yang belum punya baris di public.profiles
INSERT INTO public.profiles (id, email, nama, role, aktif)
SELECT
  u.id,
  u.email,
  COALESCE(u.raw_user_meta_data->>'nama', split_part(u.email, '@', 1)),
  COALESCE((u.raw_user_meta_data->>'role')::public.user_role, 'sales'::public.user_role),
  TRUE
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE p.id IS NULL;

-- 2) Pastikan akun admin default tetap role admin
UPDATE public.profiles
SET
  role = 'admin'::public.user_role,
  aktif = TRUE,
  updated_at = NOW()
WHERE LOWER(email) = 'admin@mmb.com';

COMMIT;
