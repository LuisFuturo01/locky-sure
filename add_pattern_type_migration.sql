-- ============================================================
-- Migración: Permitir tipo 'pattern' en la tabla vault_items
-- ============================================================
-- Ejecutar en Supabase Dashboard → SQL Editor → New Query

ALTER TABLE public.vault_items 
DROP CONSTRAINT IF EXISTS vault_items_item_type_check;

ALTER TABLE public.vault_items 
ADD CONSTRAINT vault_items_item_type_check 
CHECK (item_type IN ('password', 'card', 'note', 'identity', 'api_key', 'pattern', 'custom'));
