-- ============================================================================
-- FIX PAYMENT TRIGGER (FINAL VERSION)
-- ============================================================================
-- Este script soluciona el error "cannot extract elements from an object" (22023)
-- reemplazando el trigger defectuoso por uno robusto que NO depende de webhook_data.
-- ============================================================================

-- 1. Eliminar triggers y funciones antiguas que puedan estar causando el conflicto
DROP TRIGGER IF EXISTS on_payment_approved ON public.payments;
DROP FUNCTION IF EXISTS decrement_ticket_stock();

-- También eliminar otros posibles nombres de triggers que hayan quedado
DROP TRIGGER IF EXISTS on_payment_update ON public.payments;
DROP TRIGGER IF EXISTS handle_payment_update ON public.payments;
DROP FUNCTION IF EXISTS handle_payment_update();

-- 2. Crear la función corregida y robusta
CREATE OR REPLACE FUNCTION handle_payment_approval()
RETURNS TRIGGER AS $$
DECLARE
  order_item RECORD;
  ticket_count INTEGER;
  new_ticket_id uuid;
  existing_tickets_count INTEGER;
BEGIN
  -- Log para depuración
  RAISE NOTICE 'Trigger handle_payment_approval ejecutado para payment_id: %', NEW.id;

  -- Solo procesar si el pago fue aprobado y antes no lo estaba
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    
    RAISE NOTICE 'Procesando aprobación de pago para orden: %', NEW.order_id;

    -- Actualizar estado de la orden a 'paid'
    UPDATE public.orders
    SET status = 'paid', updated_at = now()
    WHERE id = NEW.order_id;
    
    -- Verificar si ya existen tickets para esta orden (Idempotencia)
    SELECT count(*) INTO existing_tickets_count
    FROM public.tickets
    WHERE payment_id_mp = NEW.mp_payment_id;

    IF existing_tickets_count > 0 THEN
      RAISE NOTICE 'Ya existen tickets para este pago. Omitiendo generación.';
      RETURN NEW;
    END IF;

    -- Procesar cada item de la orden (Tickets)
    -- Usamos order_items, NO webhook_data, para evitar errores de JSON
    FOR order_item IN 
      SELECT oi.*, o.user_id, tt.name as ticket_type_name
      FROM public.order_items oi
      JOIN public.orders o ON o.id = oi.order_id
      JOIN public.ticket_types tt ON tt.id = oi.ticket_type_id
      WHERE oi.order_id = NEW.order_id AND oi.item_type = 'ticket'
    LOOP
      
      RAISE NOTICE 'Generando % tickets de tipo %', order_item.quantity, order_item.ticket_type_name;

      -- Decrementar stock
      UPDATE public.ticket_types
      SET stock_available = stock_available - order_item.quantity
      WHERE id = order_item.ticket_type_id;
      
      -- Crear tickets individuales
      FOR ticket_count IN 1..order_item.quantity LOOP
        new_ticket_id := uuid_generate_v4();
        
        INSERT INTO public.tickets (
          id,
          user_id, 
          ticket_type, 
          price, 
          payment_status, 
          payment_id_mp, 
          qr_code_data, 
          purchase_date,
          updated_at
        )
        VALUES (
          new_ticket_id,
          order_item.user_id,
          order_item.ticket_type_name,
          order_item.unit_price,
          'approved',
          NEW.mp_payment_id,
          new_ticket_id::text, -- QR simple (solo ID)
          now(),
          now()
        );
      END LOOP;
    END LOOP;
  END IF;
  
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Capturar y loguear cualquier error, pero permitir que el update del pago proceda
  -- para no bloquear la transacción de Mercado Pago.
  RAISE WARNING 'Error en handle_payment_approval: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Crear el nuevo trigger
CREATE TRIGGER on_payment_approval_trigger
  AFTER INSERT OR UPDATE ON public.payments
  FOR EACH ROW
  EXECUTE FUNCTION handle_payment_approval();

-- ============================================================================
-- ✅ SCRIPT LISTO
-- Ejecuta este script completo en Supabase SQL Editor.
-- ============================================================================
