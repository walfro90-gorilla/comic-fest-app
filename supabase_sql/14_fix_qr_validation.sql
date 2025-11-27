-- ============================================================================
-- FIX: Actualizar QR codes existentes de COMICFEST2025 a COMICFEST2026
-- ============================================================================
-- El evento es en marzo 2026, no 2025
-- Este script actualiza todos los tickets existentes
-- ============================================================================

-- Actualizar tickets existentes que tengan el formato viejo
UPDATE public.tickets
SET 
  qr_code_data = REPLACE(qr_code_data, 'COMICFEST2025|', 'COMICFEST2026|'),
  updated_at = now()
WHERE qr_code_data LIKE 'COMICFEST2025|%';

-- ============================================================================
-- ✅ SCRIPT COMPLETADO
-- ============================================================================
-- Verifica los cambios con:
-- SELECT id, qr_code_data, purchase_date FROM public.tickets WHERE qr_code_data LIKE 'COMICFEST2026|%';
-- ============================================================================
