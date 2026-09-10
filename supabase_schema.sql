-- ============================================================
-- SureThing — Supabase Database Schema
-- ============================================================
-- Ejecutar este archivo en el SQL Editor de Supabase
-- Dashboard → SQL Editor → New Query → Pegar y ejecutar
-- ============================================================

-- ============================
-- EXTENSIONES
-- ============================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================
-- TABLA: profiles
-- ============================
-- Extiende auth.users de Supabase Auth
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================
-- TABLA: folders
-- ============================
-- Sistema jerárquico de carpetas (self-referencing para subcarpetas)
CREATE TABLE IF NOT EXISTS public.folders (
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

-- ============================
-- TABLA: vault_items
-- ============================
-- Credenciales y datos sensibles (todo encriptado del lado del cliente)
-- item_type: 'password', 'card', 'note', 'identity', 'api_key', 'custom'
CREATE TABLE IF NOT EXISTS public.vault_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    folder_id UUID REFERENCES public.folders(id) ON DELETE SET NULL,
    item_type TEXT NOT NULL DEFAULT 'password'
        CHECK (item_type IN ('password', 'card', 'note', 'identity', 'api_key', 'pattern', 'custom')),
    title_encrypted TEXT NOT NULL,
    data_encrypted TEXT NOT NULL,
    iv TEXT NOT NULL,
    is_favorite BOOLEAN NOT NULL DEFAULT false,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================
-- TABLA: item_links
-- ============================
-- Relaciones entre items (enlazados, derivados, padre)
CREATE TABLE IF NOT EXISTS public.item_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_item_id UUID NOT NULL REFERENCES public.vault_items(id) ON DELETE CASCADE,
    target_item_id UUID NOT NULL REFERENCES public.vault_items(id) ON DELETE CASCADE,
    link_type TEXT NOT NULL DEFAULT 'related'
        CHECK (link_type IN ('related', 'derived', 'parent')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Evitar enlaces duplicados
    UNIQUE (source_item_id, target_item_id)
);

-- ============================
-- ÍNDICES
-- ============================
CREATE INDEX IF NOT EXISTS idx_folders_user_id ON public.folders(user_id);
CREATE INDEX IF NOT EXISTS idx_folders_parent_id ON public.folders(parent_id);
CREATE INDEX IF NOT EXISTS idx_vault_items_user_id ON public.vault_items(user_id);
CREATE INDEX IF NOT EXISTS idx_vault_items_folder_id ON public.vault_items(folder_id);
CREATE INDEX IF NOT EXISTS idx_vault_items_type ON public.vault_items(item_type);
CREATE INDEX IF NOT EXISTS idx_vault_items_favorite ON public.vault_items(is_favorite) WHERE is_favorite = true;
CREATE INDEX IF NOT EXISTS idx_item_links_source ON public.item_links(source_item_id);
CREATE INDEX IF NOT EXISTS idx_item_links_target ON public.item_links(target_item_id);

-- ============================
-- FUNCIONES AUXILIARES
-- ============================

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Función para crear perfil automáticamente al registrar usuario
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================
-- TRIGGERS
-- ============================

-- Auto-crear perfil cuando se registra un usuario nuevo
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-actualizar updated_at en profiles
DROP TRIGGER IF EXISTS on_profiles_updated ON public.profiles;
CREATE TRIGGER on_profiles_updated
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Auto-actualizar updated_at en folders
DROP TRIGGER IF EXISTS on_folders_updated ON public.folders;
CREATE TRIGGER on_folders_updated
    BEFORE UPDATE ON public.folders
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Auto-actualizar updated_at en vault_items
DROP TRIGGER IF EXISTS on_vault_items_updated ON public.vault_items;
CREATE TRIGGER on_vault_items_updated
    BEFORE UPDATE ON public.vault_items
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================
-- ROW LEVEL SECURITY (RLS)
-- ============================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vault_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.item_links ENABLE ROW LEVEL SECURITY;

-- --- PROFILES ---
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- --- FOLDERS ---
DROP POLICY IF EXISTS "Users can view own folders" ON public.folders;
CREATE POLICY "Users can view own folders"
    ON public.folders FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own folders" ON public.folders;
CREATE POLICY "Users can create own folders"
    ON public.folders FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own folders" ON public.folders;
CREATE POLICY "Users can update own folders"
    ON public.folders FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own folders" ON public.folders;
CREATE POLICY "Users can delete own folders"
    ON public.folders FOR DELETE
    USING (auth.uid() = user_id);

-- --- VAULT_ITEMS ---
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

-- --- ITEM_LINKS ---
-- Los usuarios solo pueden gestionar enlaces de sus propios items
DROP POLICY IF EXISTS "Users can view own links" ON public.item_links;
CREATE POLICY "Users can view own links"
    ON public.item_links FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.vault_items
            WHERE id = source_item_id AND user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can create own links" ON public.item_links;
CREATE POLICY "Users can create own links"
    ON public.item_links FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.vault_items
            WHERE id = source_item_id AND user_id = auth.uid()
        )
        AND
        EXISTS (
            SELECT 1 FROM public.vault_items
            WHERE id = target_item_id AND user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete own links" ON public.item_links;
CREATE POLICY "Users can delete own links"
    ON public.item_links FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.vault_items
            WHERE id = source_item_id AND user_id = auth.uid()
        )
    );

