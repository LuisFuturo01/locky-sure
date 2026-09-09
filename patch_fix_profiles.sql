-- ============================================================
-- Locky — Patch de actualización para reparar usuarios existentes
-- ============================================================
-- Ejecutar este script en Supabase SQL Editor si ya tenías la BD creada.
-- Crea el perfil en public.profiles para todos los usuarios registrados previamente en auth.users
-- ============================================================

INSERT INTO public.profiles (id, display_name)
SELECT id, COALESCE(raw_user_meta_data->>'display_name', split_part(email, '@', 1))
FROM auth.users
ON CONFLICT (id) DO NOTHING;
