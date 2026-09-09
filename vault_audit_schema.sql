-- ============================================================
-- Locky — Tabla de Historial y Auditoría de Credenciales
-- ============================================================
-- Ejecutar este script en Supabase: Dashboard → SQL Editor → New Query
-- Registra eventos de creación, edición y eliminación de elementos.
-- ============================================================

-- 1. TABLA: item_audit_logs
CREATE TABLE IF NOT EXISTS public.item_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    item_id UUID,
    item_title TEXT NOT NULL,
    action TEXT NOT NULL, -- 'CREADO', 'EDITADO', 'ELIMINADO'
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    details JSONB
);

-- 2. HABILITAR RLS (Row Level Security)
ALTER TABLE public.item_audit_logs ENABLE ROW LEVEL SECURITY;

-- 3. POLÍTICAS DE SEGURIDAD RLS
CREATE POLICY "Los usuarios solo ven su propio historial"
    ON public.item_audit_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Los usuarios solo pueden insertar en su propio historial"
    ON public.item_audit_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Los usuarios pueden eliminar su propio historial"
    ON public.item_audit_logs FOR DELETE
    USING (auth.uid() = user_id);

-- 4. TRIGGER PARA AUDITORÍA AUTOMÁTICA DE CAMBIOS EN vault_items
CREATE OR REPLACE FUNCTION public.log_vault_item_activity()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO public.item_audit_logs (user_id, item_id, item_title, action, details)
        VALUES (
            NEW.user_id,
            NEW.id,
            NEW.title_encrypted,
            'CREADO',
            jsonb_build_object('item_type', NEW.item_type, 'created_at', NEW.created_at)
        );
        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO public.item_audit_logs (user_id, item_id, item_title, action, details)
        VALUES (
            NEW.user_id,
            NEW.id,
            NEW.title_encrypted,
            'EDITADO',
            jsonb_build_object('updated_at', NEW.updated_at)
        );
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO public.item_audit_logs (user_id, item_id, item_title, action, details)
        VALUES (
            OLD.user_id,
            OLD.id,
            OLD.title_encrypted,
            'ELIMINADO',
            jsonb_build_object('deleted_at', now())
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Asignar Trigger a la tabla vault_items
DROP TRIGGER IF EXISTS trigger_log_vault_item_activity ON public.vault_items;
CREATE TRIGGER trigger_log_vault_item_activity
    AFTER INSERT OR UPDATE OR DELETE ON public.vault_items
    FOR EACH ROW EXECUTE FUNCTION public.log_vault_item_activity();
