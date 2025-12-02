-- ============================================================================
-- FIX: Otorgar Puntos por Compra de Boletos
-- ============================================================================

CREATE OR REPLACE FUNCTION decrement_ticket_stock()
RETURNS TRIGGER AS $$
DECLARE
  order_item RECORD;
  ticket_count INTEGER;
  points_to_award INTEGER;
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
        INSERT INTO public.tickets (
          user_id, 
          ticket_type, 
          price, 
          payment_status, 
          payment_id_mp, 
          qr_code_data, 
          purchase_date
        )
        VALUES (
          order_item.user_id,
          order_item.ticket_type_name,
          order_item.unit_price,
          'approved',
          NEW.mp_payment_id,
          'COMICFEST2026|' || uuid_generate_v4()::text || '|' || order_item.user_id::text || '|' || extract(epoch from now())::text,
          now()
        );
      END LOOP;

      -- CALCULAR Y OTORGAR PUNTOS (10% del valor de la compra)
      points_to_award := ROUND(order_item.unit_price * order_item.quantity * 0.10)::INTEGER;
      
      IF points_to_award > 0 THEN
        INSERT INTO public.points_log (
          user_id, 
          points_change, 
          reason, 
          type, 
          source_id
        )
        VALUES (
          order_item.user_id,
          points_to_award,
          'Compra de boleto: ' || order_item.ticket_type_name || ' (x' || order_item.quantity || ')',
          'earn',
          NEW.id -- Usamos el ID del pago como source_id
        );
        -- El trigger on_points_change se encargará de actualizar el total en profiles
      END IF;

    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
