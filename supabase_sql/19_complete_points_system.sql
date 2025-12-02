-- ============================================================================
-- FIX: Sistema de Puntos Completo (Productos y Check-ins)
-- ============================================================================

-- 1. Actualizar la función de procesamiento de pagos para incluir Productos (5%)
CREATE OR REPLACE FUNCTION handle_order_payment()
RETURNS TRIGGER AS $$
DECLARE
  order_item RECORD;
  ticket_count INTEGER;
  points_to_award INTEGER;
BEGIN
  -- Solo procesar si el pago fue aprobado
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    
    -- Actualizar estado de la orden
    UPDATE public.orders
    SET status = 'paid', updated_at = now()
    WHERE id = NEW.order_id;
    
    -- Procesar cada item de la orden
    FOR order_item IN 
      SELECT oi.*, o.user_id, 
             tt.name as ticket_type_name,
             p.name as product_name
      FROM public.order_items oi
      JOIN public.orders o ON o.id = oi.order_id
      LEFT JOIN public.ticket_types tt ON tt.id = oi.ticket_type_id
      LEFT JOIN public.products p ON p.id = oi.product_id
      WHERE oi.order_id = NEW.order_id
    LOOP
      
      -- CASO 1: TICKETS
      IF order_item.item_type = 'ticket' THEN
        -- Decrementar stock de tickets
        UPDATE public.ticket_types
        SET stock_available = stock_available - order_item.quantity
        WHERE id = order_item.ticket_type_id;
        
        -- Crear tickets individuales
        FOR ticket_count IN 1..order_item.quantity LOOP
          INSERT INTO public.tickets (
            user_id, ticket_type, price, payment_status, 
            payment_id_mp, qr_code_data, purchase_date
          )
          VALUES (
            order_item.user_id,
            order_item.ticket_type_name,
            order_item.unit_price,
            'approved',
            NEW.mp_payment_id,
            'CF-TICKET-' || uuid_generate_v4()::text,
            now()
          );
        END LOOP;

        -- Puntos por Tickets: 10%
        points_to_award := ROUND(order_item.unit_price * order_item.quantity * 0.10)::INTEGER;
        IF points_to_award > 0 THEN
          INSERT INTO public.points_log (user_id, points_change, reason, type, source_id)
          VALUES (
            order_item.user_id,
            points_to_award,
            'Compra de boleto: ' || order_item.ticket_type_name,
            'earn',
            NEW.id
          );
        END IF;

      -- CASO 2: PRODUCTOS
      ELSIF order_item.item_type = 'product' THEN
        -- Decrementar stock de productos
        UPDATE public.products
        SET stock = stock - order_item.quantity
        WHERE id = order_item.product_id;

        -- Puntos por Productos: 5%
        points_to_award := ROUND(order_item.unit_price * order_item.quantity * 0.05)::INTEGER;
        IF points_to_award > 0 THEN
          INSERT INTO public.points_log (user_id, points_change, reason, type, source_id)
          VALUES (
            order_item.user_id,
            points_to_award,
            'Compra de producto: ' || order_item.product_name,
            'earn',
            NEW.id
          );
        END IF;
      END IF;

    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Reemplazar el trigger anterior para usar la nueva función
DROP TRIGGER IF EXISTS on_payment_approved ON public.payments;
CREATE TRIGGER on_payment_approved
  AFTER INSERT OR UPDATE ON public.payments
  FOR EACH ROW
  EXECUTE FUNCTION handle_order_payment();


-- 2. Trigger para Check-ins (Passport Stamps) -> +10 puntos
CREATE OR REPLACE FUNCTION handle_new_stamp()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.points_log (
    user_id,
    points_change,
    reason,
    type,
    source_id
  )
  VALUES (
    NEW.user_id,
    10, -- 10 puntos por check-in
    'Check-in en evento/stand',
    'earn',
    NEW.id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_stamp_created ON public.passport_stamps;
CREATE TRIGGER on_stamp_created
  AFTER INSERT ON public.passport_stamps
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_stamp();

-- NOTA: La votación (+5 puntos) ya se maneja desde la app insertando en points_log,
-- lo cual dispara el trigger on_points_change que actualiza el perfil.
