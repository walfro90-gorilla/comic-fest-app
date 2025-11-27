-- ============================================================================
-- CONTESTANTS - Concursantes para paneles tipo concurso
-- ============================================================================
-- Este script crea la tabla contestants, índices y políticas RLS
-- ============================================================================

-- ============================================================================
-- 1. Crear tabla contestants
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.contestants (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  schedule_item_id uuid NOT NULL REFERENCES public.schedule_items(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  image_url text,
  contestant_number int NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================================
-- 2. Crear índices para optimización
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_contestants_schedule_item ON public.contestants(schedule_item_id);
CREATE INDEX IF NOT EXISTS idx_contestants_number ON public.contestants(schedule_item_id, contestant_number);

-- ============================================================================
-- 3. Habilitar Row Level Security (RLS)
-- ============================================================================
ALTER TABLE public.contestants ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. Políticas de acceso
-- ============================================================================

-- Permitir a todos ver los concursantes
DROP POLICY IF EXISTS "contestants_select_all" ON public.contestants;
CREATE POLICY "contestants_select_all" ON public.contestants
  FOR SELECT
  USING (true);

-- Solo admins pueden crear concursantes
DROP POLICY IF EXISTS "contestants_insert_admin" ON public.contestants;
CREATE POLICY "contestants_insert_admin" ON public.contestants
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo admins pueden actualizar concursantes
DROP POLICY IF EXISTS "contestants_update_admin" ON public.contestants;
CREATE POLICY "contestants_update_admin" ON public.contestants
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo admins pueden eliminar concursantes
DROP POLICY IF EXISTS "contestants_delete_admin" ON public.contestants;
CREATE POLICY "contestants_delete_admin" ON public.contestants
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================================
-- ✅ CONTESTANTS - Tabla creada exitosamente
-- ============================================================================
