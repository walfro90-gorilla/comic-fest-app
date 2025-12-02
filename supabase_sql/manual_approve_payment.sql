-- ============================================================================
-- MANUAL PAYMENT APPROVAL (SIMULATION)
-- ============================================================================
-- Este script simula que Mercado Pago (vía Webhook) aprobó finalmente el pago.
-- Al ejecutarlo, el estado cambiará a 'approved' y se generarán los tickets.
-- ============================================================================

DO $$
DECLARE
  -- 👇 ID del nuevo pago que está "pending_contingency"
  target_payment_id text := '1325548458'; 
  payment_record RECORD;
BEGIN
  -- 1. Verificar que el pago existe
  SELECT * INTO payment_record
  FROM public.payments
  WHERE mp_payment_id = target_payment_id;

  IF payment_record IS NULL THEN
    RAISE EXCEPTION '❌ No se encontró el pago con ID: %', target_payment_id;
  END IF;

  RAISE NOTICE '✅ Pago encontrado: % (Estado actual: %)', payment_record.id, payment_record.status;

  -- 2. Actualizar estado a 'approved'
  -- Esto disparará el trigger 'on_payment_approval_trigger' que genera los tickets
  UPDATE public.payments
  SET 
    status = 'approved',
    status_detail = 'accredited',
    updated_at = now()
  WHERE mp_payment_id = target_payment_id;

  RAISE NOTICE '🚀 Estado actualizado a APPROVED. Verificando tickets...';

  -- 3. Verificar si se generaron tickets
  IF EXISTS (SELECT 1 FROM public.tickets WHERE payment_id_mp = target_payment_id) THEN
    RAISE NOTICE '✨ ¡ÉXITO! Se han generado los tickets correctamente.';
  ELSE
    RAISE NOTICE '⚠️ ADVERTENCIA: No se encontraron tickets. Revisa el log del trigger.';
  END IF;

END $$;
