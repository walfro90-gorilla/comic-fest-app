-- ============================================================================
-- PANEL VOTES - Sistema de votación para paneles
-- ============================================================================
-- Este script crea la tabla panel_votes, índices y políticas RLS
-- ============================================================================

-- ============================================================================
-- 1. Crear tabla panel_votes
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.panel_votes (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  schedule_item_id uuid NOT NULL REFERENCES public.schedule_items(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, schedule_item_id)
);

-- ============================================================================
-- 2. Crear índices para optimización
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_panel_votes_user ON public.panel_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_panel_votes_schedule_item ON public.panel_votes(schedule_item_id);
CREATE INDEX IF NOT EXISTS idx_panel_votes_created_at ON public.panel_votes(created_at DESC);

-- ============================================================================
-- 3. Habilitar Row Level Security (RLS)
-- ============================================================================
ALTER TABLE public.panel_votes ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. Políticas de acceso
-- ============================================================================

-- Permitir a usuarios autenticados ver todos los votos
DROP POLICY IF EXISTS "panel_votes_select_all" ON public.panel_votes;
CREATE POLICY "panel_votes_select_all" ON public.panel_votes
  FOR SELECT
  USING (true);

-- Permitir a usuarios autenticados insertar sus propios votos
DROP POLICY IF EXISTS "panel_votes_insert_own" ON public.panel_votes;
CREATE POLICY "panel_votes_insert_own" ON public.panel_votes
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Permitir a usuarios eliminar sus propios votos (por si se implementa "desvotar")
DROP POLICY IF EXISTS "panel_votes_delete_own" ON public.panel_votes;
CREATE POLICY "panel_votes_delete_own" ON public.panel_votes
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- ✅ PANEL VOTES - Tabla creada exitosamente
-- ============================================================================
