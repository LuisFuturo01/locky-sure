-- ============================================================
-- Locky — Patch de actualización para reparar usuarios existentes
-- ============================================================
-- Ejecutar este script en Supabase SQL Editor si ya tenías la BD creada.
-- Crea el perfil en public.profiles para todos los usuarios registrados previamente en auth.users
-- ============================================================

-- 1. Insertar usuarios de auth.users que no estén en public.profiles
INSERT INTO public.profiles (id, display_name)
SELECT id, COALESCE(raw_user_meta_data->>'display_name', split_part(email, '@', 1))
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- 2. Habilitar política de INSERT para profiles (necesario para el cliente)
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

