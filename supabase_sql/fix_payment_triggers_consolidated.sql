-- ============================================================================
-- FIX PAYMENT TRIGGERS (CONSOLIDATED & ROBUST)
-- ============================================================================
-- Este script corrige el error "trigger already exists" eliminando explícitamente
-- cualquier versión anterior del trigger antes de crearlo.
-- También incluye la lógica de generación de tickets más robusta.
-- ============================================================================

-- 1. LIMPIEZA TOTAL: Eliminar cualquier trigger o función previa con nombres similares
DROP TRIGGER IF EXISTS on_payment_approval_trigger ON public.payments;
DROP TRIGGER IF EXISTS on_payment_approved ON public.payments;
DROP TRIGGER IF EXISTS on_payment_update ON public.payments;

DROP FUNCTION IF EXISTS handle_payment_approval();
DROP FUNCTION IF EXISTS decrement_ticket_stock();

-- 2. CREAR FUNCIÓN (SECURITY DEFINER para permisos de admin)
CREATE OR REPLACE FUNCTION handle_payment_approval()
RETURNS TRIGGER AS $$
DECLARE
  order_item RECORD;
  ticket_count INTEGER;
  new_ticket_id uuid;
  existing_tickets_count INTEGER;
BEGIN
  RAISE NOTICE '🚀 Trigger handle_payment_approval INICIADO para payment_id: %', NEW.id;

  -- Solo procesar si el pago fue aprobado
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    
    RAISE NOTICE '✅ Pago aprobado detectado. Procesando orden: %', NEW.order_id;

    -- Actualizar estado de la orden
    UPDATE public.orders
    SET status = 'paid', updated_at = now()
    WHERE id = NEW.order_id;
    
    -- Verificar duplicados
    SELECT count(*) INTO existing_tickets_count
    FROM public.tickets
    WHERE payment_id_mp = NEW.mp_payment_id;

    IF existing_tickets_count > 0 THEN
      RAISE NOTICE '⚠️ Tickets ya existen. Omitiendo.';
      RETURN NEW;
    END IF;

    -- Generar Tickets
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
      
      -- Crear tickets
      FOR ticket_count IN 1..order_item.quantity LOOP
        new_ticket_id := gen_random_uuid();
        
        INSERT INTO public.tickets (
          id, user_id, ticket_type, price, payment_status, 
          payment_id_mp, qr_code_data, purchase_date, updated_at, is_validated
        )
        VALUES (
          new_ticket_id, order_item.user_id, order_item.ticket_type_name, order_item.unit_price, 'approved',
          NEW.mp_payment_id, new_ticket_id::text, now(), now(), false
        );
      END LOOP;
    END LOOP;
    
    RAISE NOTICE '✨ Tickets generados exitosamente.';
  END IF;
  
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '❌ Error en trigger: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. CREAR EL TRIGGER
CREATE TRIGGER on_payment_approval_trigger
  AFTER INSERT OR UPDATE ON public.payments
  FOR EACH ROW
  EXECUTE FUNCTION handle_payment_approval();

-- ============================================================================
-- 4. REPARACIÓN (BACKFILL) PARA PAGOS YA APROBADOS SIN TICKETS
-- ============================================================================
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
    WHERE p.status = 'approved'
      AND NOT EXISTS (SELECT 1 FROM public.tickets t WHERE t.payment_id_mp = p.mp_payment_id)
  LOOP
    RAISE NOTICE '🔧 Reparando tickets para pago: %', rec.mp_payment_id;
    
    FOR order_item IN 
      SELECT oi.*, o.user_id, tt.name as ticket_type_name
      FROM public.order_items oi
      JOIN public.orders o ON o.id = oi.order_id
      JOIN public.ticket_types tt ON tt.id = oi.ticket_type_id
      WHERE oi.order_id = rec.order_id AND oi.item_type = 'ticket'
    LOOP
      FOR ticket_count IN 1..order_item.quantity LOOP
        new_ticket_id := gen_random_uuid();
        INSERT INTO public.tickets (id, user_id, ticket_type, price, payment_status, payment_id_mp, qr_code_data, purchase_date, updated_at, is_validated)
        VALUES (new_ticket_id, order_item.user_id, order_item.ticket_type_name, order_item.unit_price, 'approved', rec.mp_payment_id, new_ticket_id::text, now(), now(), false);
      END LOOP;
    END LOOP;
  END LOOP;
END $$;
