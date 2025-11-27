-- ============================================================================
-- ACTUALIZAR PANEL_VOTES - Agregar soporte para votación de concursos
-- ============================================================================
-- Agrega columnas contestant_id y points para soportar votación de concursos
-- ============================================================================

-- ============================================================================
-- 1. Agregar columnas para votación de concursos
-- ============================================================================
ALTER TABLE public.panel_votes 
  ADD COLUMN IF NOT EXISTS contestant_id uuid REFERENCES public.contestants(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS points integer NOT NULL DEFAULT 1;

-- ============================================================================
-- 2. Actualizar la restricción UNIQUE para permitir múltiples votos por evento
-- ============================================================================
-- Eliminar la restricción anterior
ALTER TABLE public.panel_votes DROP CONSTRAINT IF EXISTS panel_votes_user_id_schedule_item_id_key;

-- Crear nueva restricción: un usuario puede votar por varios concursantes en un evento
-- pero no puede votar dos veces por el mismo concursante
ALTER TABLE public.panel_votes 
  ADD CONSTRAINT panel_votes_user_contestant_unique 
  UNIQUE (user_id, schedule_item_id, contestant_id);

-- ============================================================================
-- 3. Crear índice para optimizar consultas por concursante
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_panel_votes_contestant ON public.panel_votes(contestant_id);

-- ============================================================================
-- 4. Agregar restricción CHECK para validar puntos (1-6)
-- ============================================================================
ALTER TABLE public.panel_votes 
  ADD CONSTRAINT check_points_range 
  CHECK (points >= 1 AND points <= 6);

-- ============================================================================
-- ✅ PANEL_VOTES - Actualizada para soportar votación de concursos
-- ============================================================================
