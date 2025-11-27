-- ============================================================================
-- AGREGAR CATEGORÍA "CONCURSO" A SCHEDULE_ITEMS
-- ============================================================================
-- Ejecuta este script en Supabase SQL Editor para agregar la nueva categoría
-- ============================================================================

-- Eliminar el constraint existente
ALTER TABLE public.schedule_items 
DROP CONSTRAINT IF EXISTS schedule_items_category_check;

-- Agregar el nuevo constraint con la categoría "concurso"
ALTER TABLE public.schedule_items 
ADD CONSTRAINT schedule_items_category_check 
CHECK (category = ANY (ARRAY['panel'::text, 'firma'::text, 'torneo'::text, 'actividad'::text, 'concurso'::text]));

-- Verificar que el constraint se haya agregado correctamente
-- SELECT conname, pg_get_constraintdef(oid) 
-- FROM pg_constraint 
-- WHERE conrelid = 'public.schedule_items'::regclass 
-- AND conname = 'schedule_items_category_check';
