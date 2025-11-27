-- ============================================================================
-- COMIC FEST - Función SQL para actualizar estado de pagos
-- ============================================================================
-- Esta función permite actualizar el estado de un pago evitando problemas
-- con campos JSONB en updates directos
-- ============================================================================

-- Crear función para actualizar estado de pago
CREATE OR REPLACE FUNCTION update_payment_status(
  payment_uuid uuid,
  new_status text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- Ejecuta con privilegios del dueño de la función
AS $$
BEGIN
  -- Validar que el status sea válido
  IF new_status NOT IN ('pending', 'approved', 'rejected', 'refunded', 'cancelled') THEN
    RAISE EXCEPTION 'Invalid payment status: %', new_status;
  END IF;

  -- Actualizar el pago
  UPDATE public.payments
  SET 
    status = new_status,
    updated_at = now()
  WHERE id = payment_uuid;

  -- Si el pago fue aprobado, también actualizar la orden
  IF new_status = 'approved' THEN
    UPDATE public.orders
    SET 
      status = 'completed',
      updated_at = now()
    WHERE id = (SELECT order_id FROM public.payments WHERE id = payment_uuid);
  END IF;
END;
$$;

-- Grant permisos para que usuarios autenticados puedan ejecutar la función
GRANT EXECUTE ON FUNCTION update_payment_status(uuid, text) TO authenticated;

-- ============================================================================
-- NOTA: Esta función usa SECURITY DEFINER, lo que significa que se ejecuta
-- con los privilegios del dueño (postgres), bypaseando RLS.
-- En producción, considera agregar verificaciones adicionales de permisos.
-- ============================================================================
