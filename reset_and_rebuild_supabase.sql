-- ============================================================
-- SureThing / Locky — Script Completo de Reinicio e Instalación Limpia de BD
-- ============================================================
-- Ejecuta este script en el SQL Editor de Supabase:
-- Dashboard → SQL Editor → New Query → Pegar todo y Ejecutar (RUN)
-- 
-- ⚠️ ESTE SCRIPT BORRA LAS TABLAS ANTERIORES Y LAS CREA DESDE CERO
-- (Los usuarios registrados en Auth NO se borran, se migran automáticamente)
-- ============================================================

-- 1. ELIMINAR TABLAS, FUNCIONES Y TRIGGERS ANTERIORES
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_profiles_updated ON public.profiles;
DROP TRIGGER IF EXISTS on_folders_updated ON public.folders;
DROP TRIGGER IF EXISTS on_vault_items_updated ON public.vault_items;

DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_updated_at() CASCADE;

DROP TABLE IF EXISTS public.item_links CASCADE;
DROP TABLE IF EXISTS public.vault_items CASCADE;
DROP TABLE IF EXISTS public.folders CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- 2. EXTENSIONES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 3. TABLA: profiles
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. TABLA: folders
CREATE TABLE public.folders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES public.folders(id) ON DELETE SET NULL,
    name_encrypted TEXT NOT NULL,
    icon TEXT NOT NULL DEFAULT 'folder',
    color TEXT NOT NULL DEFAULT '#6366F1',
    sort_order INT NOT NULL DEFAULT 0,
    iv TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. TABLA: vault_items
CREATE TABLE public.vault_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    folder_id UUID REFERENCES public.folders(id) ON DELETE SET NULL,
    item_type TEXT NOT NULL DEFAULT 'password',
    title_encrypted TEXT NOT NULL,
    data_encrypted TEXT NOT NULL,
    iv TEXT NOT NULL,
    is_favorite BOOLEAN NOT NULL DEFAULT false,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. TABLA: item_links
CREATE TABLE public.item_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_item_id UUID NOT NULL REFERENCES public.vault_items(id) ON DELETE CASCADE,
    target_item_id UUID NOT NULL REFERENCES public.vault_items(id) ON DELETE CASCADE,
    link_type TEXT NOT NULL DEFAULT 'related',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (source_item_id, target_item_id)
);

-- 7. ÍNDICES DE RENDIMIENTO
CREATE INDEX idx_folders_user_id ON public.folders(user_id);
CREATE INDEX idx_folders_parent_id ON public.folders(parent_id);
CREATE INDEX idx_vault_items_user_id ON public.vault_items(user_id);
CREATE INDEX idx_vault_items_folder_id ON public.vault_items(folder_id);
CREATE INDEX idx_vault_items_type ON public.vault_items(item_type);

-- 8. FUNCIONES Y TRIGGERS AUTOMÁTICOS
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER on_profiles_updated
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_folders_updated
    BEFORE UPDATE ON public.folders
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_vault_items_updated
    BEFORE UPDATE ON public.vault_items
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 9. MIGRAR USUARIOS EXISTENTES DE auth.users A public.profiles
INSERT INTO public.profiles (id, display_name)
SELECT id, COALESCE(raw_user_meta_data->>'display_name', split_part(email, '@', 1))
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- 10. HABILITAR ROW LEVEL SECURITY (RLS) Y PERMISOS COMPLETO
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vault_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.item_links ENABLE ROW LEVEL SECURITY;

-- POLÍTICAS: PROFILES
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- POLÍTICAS: FOLDERS
CREATE POLICY "Users can view own folders" ON public.folders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own folders" ON public.folders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own folders" ON public.folders FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own folders" ON public.folders FOR DELETE USING (auth.uid() = user_id);

-- POLÍTICAS: VAULT_ITEMS
CREATE POLICY "Users can view own items" ON public.vault_items FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own items" ON public.vault_items FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own items" ON public.vault_items FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own items" ON public.vault_items FOR DELETE USING (auth.uid() = user_id);

-- POLÍTICAS: ITEM_LINKS
CREATE POLICY "Users can view own links" ON public.item_links FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.vault_items WHERE id = source_item_id AND user_id = auth.uid()));
CREATE POLICY "Users can create own links" ON public.item_links FOR INSERT
    WITH CHECK (
        EXISTS (SELECT 1 FROM public.vault_items WHERE id = source_item_id AND user_id = auth.uid()) AND
        EXISTS (SELECT 1 FROM public.vault_items WHERE id = target_item_id AND user_id = auth.uid())
    );
CREATE POLICY "Users can delete own links" ON public.item_links FOR DELETE
    USING (EXISTS (SELECT 1 FROM public.vault_items WHERE id = source_item_id AND user_id = auth.uid()));
