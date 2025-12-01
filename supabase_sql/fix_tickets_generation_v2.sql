-- ============================================================================
-- FIX TICKETS GENERATION (PERFECT VERSION V2)
-- ============================================================================
-- Este script asegura que los tickets se generen correctamente al aprobar el pago.
-- Incluye SECURITY DEFINER para evitar problemas de permisos y usa gen_random_uuid()
-- para mayor compatibilidad.
-- ============================================================================

-- 1. Eliminar el trigger y función anteriores para asegurar limpieza
DROP TRIGGER IF EXISTS on_payment_approval_trigger ON public.payments;
DROP FUNCTION IF EXISTS handle_payment_approval();

-- 2. Crear la función con permisos de SUPERUSER (SECURITY DEFINER)
-- Esto es crucial para que el trigger pueda leer/escribir en todas las tablas necesarias
-- sin importar los permisos del usuario actual (RLS).
CREATE OR REPLACE FUNCTION handle_payment_approval()
RETURNS TRIGGER AS $$
DECLARE
  order_item RECORD;
  ticket_count INTEGER;
  new_ticket_id uuid;
  existing_tickets_count INTEGER;
BEGIN
  -- Log para depuración (visible en Supabase Dashboard > Database > Postgres Logs)
  RAISE NOTICE '🚀 Trigger handle_payment_approval INICIADO para payment_id: %', NEW.id;

  -- Solo procesar si el pago fue aprobado
  -- (Ya sea que cambie a approved, o que se inserte como approved)
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    
    RAISE NOTICE '✅ Pago aprobado detectado. Procesando orden: %', NEW.order_id;

    -- 1. Actualizar estado de la orden a 'paid'
    UPDATE public.orders
    SET status = 'paid', updated_at = now()
    WHERE id = NEW.order_id;
    
    -- 2. Verificar idempotencia (evitar duplicados)
    SELECT count(*) INTO existing_tickets_count
    FROM public.tickets
    WHERE payment_id_mp = NEW.mp_payment_id;

    IF existing_tickets_count > 0 THEN
      RAISE NOTICE '⚠️ Tickets ya existen para este pago. Omitiendo generación.';
      RETURN NEW;
    END IF;

    -- 3. Generar Tickets
    -- Iteramos sobre los items de la orden que sean de tipo 'ticket'
    FOR order_item IN 
      SELECT oi.*, o.user_id, tt.name as ticket_type_name
      FROM public.order_items oi
      JOIN public.orders o ON o.id = oi.order_id
      JOIN public.ticket_types tt ON tt.id = oi.ticket_type_id
      WHERE oi.order_id = NEW.order_id AND oi.item_type = 'ticket'
    LOOP
      
      RAISE NOTICE '🎫 Generando % tickets de tipo %', order_item.quantity, order_item.ticket_type_name;

      -- Decrementar stock (opcional, pero recomendado)
      UPDATE public.ticket_types
      SET stock_available = stock_available - order_item.quantity
      WHERE id = order_item.ticket_type_id;
      
      -- Crear N tickets individuales
      FOR ticket_count IN 1..order_item.quantity LOOP
        -- Usamos gen_random_uuid() que es nativo de Postgres
        new_ticket_id := gen_random_uuid();
        
        INSERT INTO public.tickets (
          id,
          user_id, 
          ticket_type, 
          price, 
          payment_status, 
          payment_id_mp, 
          qr_code_data, 
          purchase_date,
          updated_at,
          is_validated
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
          now(),
          false
        );
      END LOOP;
    END LOOP;
    
    RAISE NOTICE '✨ Generación de tickets completada exitosamente.';
  END IF;
  
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- En caso de error, lo registramos pero NO bloqueamos la transacción del pago.
  -- Esto permite que el pago se guarde, y el error se pueda investigar en los logs.
  RAISE WARNING '❌ ERROR CRÍTICO en handle_payment_approval: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; -- <--- IMPORTANTE: Ejecuta como admin

-- 3. Crear el trigger
CREATE TRIGGER on_payment_approval_trigger
  AFTER INSERT OR UPDATE ON public.payments
  FOR EACH ROW
  EXECUTE FUNCTION handle_payment_approval();

-- ============================================================================
-- 4. REPARACIÓN AUTOMÁTICA (BACKFILL)
-- ============================================================================
-- Este bloque busca órdenes que ya están pagadas ('paid' o 'completed') 
-- pero NO tienen tickets, y los genera ahora mismo.
DO $$
DECLARE
  rec RECORD;
  order_item RECORD;
  ticket_count INTEGER;
  new_ticket_id uuid;
BEGIN
  FOR rec IN
    SELECT p.id, p.order_id, p.mp_payment_id
    FROM public.payments p
    JOIN public.orders o ON o.id = p.order_id
    WHERE p.status = 'approved'
      AND NOT EXISTS (SELECT 1 FROM public.tickets t WHERE t.payment_id_mp = p.mp_payment_id)
  LOOP
    RAISE NOTICE '🔧 Reparando tickets faltantes para pago: %', rec.mp_payment_id;
    
    -- (Misma lógica de generación que arriba)
    FOR order_item IN 
      SELECT oi.*, o.user_id, tt.name as ticket_type_name
      FROM public.order_items oi
      JOIN public.orders o ON o.id = oi.order_id
      JOIN public.ticket_types tt ON tt.id = oi.ticket_type_id
      WHERE oi.order_id = rec.order_id AND oi.item_type = 'ticket'
    LOOP
      UPDATE public.ticket_types
      SET stock_available = stock_available - order_item.quantity
      WHERE id = order_item.ticket_type_id;
      
      FOR ticket_count IN 1..order_item.quantity LOOP
        new_ticket_id := gen_random_uuid();
        INSERT INTO public.tickets (id, user_id, ticket_type, price, payment_status, payment_id_mp, qr_code_data, purchase_date, updated_at, is_validated)
        VALUES (new_ticket_id, order_item.user_id, order_item.ticket_type_name, order_item.unit_price, 'approved', rec.mp_payment_id, new_ticket_id::text, now(), now(), false);
      END LOOP;
    END LOOP;
  END LOOP;
END $$;

-- ============================================================================
-- ✅ SCRIPT COMPLETADO
-- ============================================================================
