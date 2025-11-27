-- ============================================================================
-- SIMPLIFICAR FORMATO DE QR CODES
-- ============================================================================
-- Cambio: El QR ahora contiene solo el ID del ticket
-- Esto hace la validación más simple y segura
-- ============================================================================

-- Actualizar todos los tickets existentes para que el QR sea solo el ID
UPDATE public.tickets
SET 
  qr_code_data = id::text,
  updated_at = now()
WHERE qr_code_data != id::text;

-- ============================================================================
-- Actualizar el trigger para generar QR simples en el futuro
-- ============================================================================
CREATE OR REPLACE FUNCTION decrement_ticket_stock()
RETURNS TRIGGER AS $$
DECLARE
  order_item RECORD;
  ticket_count INTEGER;
  new_ticket_id uuid;
BEGIN
  -- Solo decrementar si el pago fue aprobado
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    
    -- Actualizar estado de la orden
    UPDATE public.orders
    SET status = 'paid', updated_at = now()
    WHERE id = NEW.order_id;
    
    -- Procesar cada item de la orden
    FOR order_item IN 
      SELECT oi.*, o.user_id, tt.name as ticket_type_name
      FROM public.order_items oi
      JOIN public.orders o ON o.id = oi.order_id
      JOIN public.ticket_types tt ON tt.id = oi.ticket_type_id
      WHERE oi.order_id = NEW.order_id AND oi.item_type = 'ticket'
    LOOP
      -- Decrementar stock
      UPDATE public.ticket_types
      SET stock_available = stock_available - order_item.quantity
      WHERE id = order_item.ticket_type_id;
      
      -- Crear tickets individuales (uno por cada cantidad)
      FOR ticket_count IN 1..order_item.quantity LOOP
        -- Generar un nuevo UUID para el ticket
        new_ticket_id := uuid_generate_v4();
        
        INSERT INTO public.tickets (
          id,
          user_id, 
          ticket_type, 
          price, 
          payment_status, 
          payment_id_mp, 
          qr_code_data, 
          purchase_date
        )
        VALUES (
          new_ticket_id,
          order_item.user_id,
          order_item.ticket_type_name,
          order_item.unit_price,
          'approved',
          NEW.mp_payment_id,
          new_ticket_id::text, -- El QR es simplemente el ID del ticket
          now()
        );
      END LOOP;
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recrear el trigger
DROP TRIGGER IF EXISTS on_payment_approved ON public.payments;
CREATE TRIGGER on_payment_approved
  AFTER INSERT OR UPDATE ON public.payments
  FOR EACH ROW
  EXECUTE FUNCTION decrement_ticket_stock();

-- ============================================================================
-- ✅ SCRIPT COMPLETADO
-- ============================================================================
-- Verifica los cambios con:
-- SELECT id, qr_code_data, is_validated FROM public.tickets LIMIT 5;
-- 
-- El QR ahora contiene solo el ID del ticket (UUID)
-- La validación se hace consultando directamente la base de datos
-- ============================================================================
