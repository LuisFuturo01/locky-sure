-- ============================================================
-- SureThing — Patch de Corrección de Sincronización y Permisos RLS
-- ============================================================
-- Ejecuta este script en el SQL Editor de Supabase:
-- Dashboard → SQL Editor → New Query → Pegar y Ejecutar
-- 
-- Este script es idéntico y seguro para bases de datos existentes:
-- No borra datos ni recrea tablas.
-- ============================================================

-- 1. Crear perfiles faltantes para usuarios ya registrados en auth.users
INSERT INTO public.profiles (id, display_name)
SELECT id, COALESCE(raw_user_meta_data->>'display_name', split_part(email, '@', 1))
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- 2. Habilitar RLS en public.profiles (por si no estuviera activo)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. Habilitar política de INSERT para public.profiles
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- 4. Asegurar política de SELECT y UPDATE para public.profiles
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 5. Asegurar políticas RLS de vault_items
ALTER TABLE public.vault_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own items" ON public.vault_items;
CREATE POLICY "Users can view own items"
    ON public.vault_items FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own items" ON public.vault_items;
CREATE POLICY "Users can create own items"
    ON public.vault_items FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own items" ON public.vault_items;
CREATE POLICY "Users can update own items"
    ON public.vault_items FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own items" ON public.vault_items;
CREATE POLICY "Users can delete own items"
    ON public.vault_items FOR DELETE
    USING (auth.uid() = user_id);
