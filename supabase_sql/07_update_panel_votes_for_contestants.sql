-- ============================================================================
-- UPDATE PANEL VOTES - Actualizar para votar por concursantes
-- ============================================================================
-- Este script actualiza la tabla panel_votes para incluir contestant_id
-- ============================================================================

-- ============================================================================
-- 1. Agregar columna contestant_id
-- ============================================================================
ALTER TABLE public.panel_votes 
ADD COLUMN IF NOT EXISTS contestant_id uuid REFERENCES public.contestants(id) ON DELETE CASCADE;

-- ============================================================================
-- 2. Crear índice para contestant_id
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_panel_votes_contestant ON public.panel_votes(contestant_id);

-- ============================================================================
-- 3. Actualizar constraint único para permitir votar por diferentes concursantes
-- ============================================================================
-- Eliminar constraint antiguo
ALTER TABLE public.panel_votes 
DROP CONSTRAINT IF EXISTS panel_votes_user_id_schedule_item_id_key;

-- Crear nuevo constraint: un voto por usuario por concursante
ALTER TABLE public.panel_votes 
ADD CONSTRAINT panel_votes_user_contestant_unique 
UNIQUE(user_id, contestant_id);

-- ============================================================================
-- ✅ PANEL VOTES - Actualizado para concursantes
-- ============================================================================
