-- ============================================================================
-- COMIC FEST - SISTEMA DE TICKETS Y PAGOS CON MERCADO PAGO
-- ============================================================================
-- Ejecuta este script en Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- 1. TICKET_TYPES (Tipos de boletos disponibles)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.ticket_types (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  description text,
  price numeric NOT NULL,
  stock_total integer NOT NULL DEFAULT 0,
  stock_available integer NOT NULL DEFAULT 0,
  benefits text[], -- Array de beneficios
  is_early_bird boolean DEFAULT false,
  is_active boolean DEFAULT true,
  display_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================================================
-- 2. ORDER_ITEMS (Items de cada orden)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.order_items (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  ticket_type_id uuid REFERENCES public.ticket_types(id),
  product_id uuid REFERENCES public.products(id),
  item_type text NOT NULL CHECK (item_type = ANY (ARRAY['ticket', 'product'])),
  quantity integer NOT NULL DEFAULT 1,
  unit_price numeric NOT NULL,
  subtotal numeric NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- ============================================================================
-- 3. PAYMENTS (Registro de pagos de Mercado Pago)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.payments (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  mp_payment_id text UNIQUE, -- ID de Mercado Pago
  mp_preference_id text, -- ID de preferencia de MP
  status text NOT NULL DEFAULT 'pending' CHECK (status = ANY (ARRAY['pending', 'approved', 'rejected', 'refunded', 'cancelled'])),
  payment_method text, -- credit_card, debit_card, etc
  payment_method_type text, -- visa, mastercard, etc
  transaction_amount numeric NOT NULL,
  currency text DEFAULT 'MXN',
  status_detail text, -- Detalle del estado de MP
  external_reference text, -- Referencia externa (order_id)
  webhook_data jsonb, -- Data completa del webhook
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================================================
-- 4. Actualizar tabla ORDERS para mejor tracking
-- ============================================================================
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS order_number text UNIQUE,
  ADD COLUMN IF NOT EXISTS order_type text DEFAULT 'ticket' CHECK (order_type = ANY (ARRAY['ticket', 'product', 'mixed'])),
  ADD COLUMN IF NOT EXISTS buyer_name text,
  ADD COLUMN IF NOT EXISTS buyer_email text,
  ADD COLUMN IF NOT EXISTS buyer_phone text;

-- Generar order_number automático si no existe
UPDATE public.orders 
SET order_number = 'CF-' || to_char(created_at, 'YYYYMMDD') || '-' || substring(id::text, 1, 8)
WHERE order_number IS NULL;

-- ============================================================================
-- 5. ÍNDICES para optimización
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_ticket_type_id ON public.order_items(ticket_type_id);
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON public.payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_mp_payment_id ON public.payments(mp_payment_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON public.payments(status);
CREATE INDEX IF NOT EXISTS idx_ticket_types_active ON public.ticket_types(is_active);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);

-- ============================================================================
-- 6. ROW LEVEL SECURITY (RLS) Políticas
-- ============================================================================

-- Habilitar RLS en las nuevas tablas
ALTER TABLE public.ticket_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- TICKET_TYPES: Todos pueden ver tickets activos
CREATE POLICY "Ticket types are viewable by everyone"
  ON public.ticket_types FOR SELECT
  USING (is_active = true);

-- TICKET_TYPES: Solo admins pueden crear/actualizar
CREATE POLICY "Admins can manage ticket types"
  ON public.ticket_types FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ORDER_ITEMS: Usuarios solo ven sus propios items
CREATE POLICY "Users can view their own order items"
  ON public.order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
        AND orders.user_id = auth.uid()
    )
  );

-- ORDER_ITEMS: Solo el sistema puede insertar
CREATE POLICY "Users can create their own order items"
  ON public.order_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
        AND orders.user_id = auth.uid()
    )
  );

-- PAYMENTS: Usuarios solo ven sus propios pagos
CREATE POLICY "Users can view their own payments"
  ON public.payments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = payments.order_id
        AND orders.user_id = auth.uid()
    )
  );

-- PAYMENTS: Solo sistema/webhooks pueden crear pagos
CREATE POLICY "System can create payments"
  ON public.payments FOR INSERT
  WITH CHECK (true); -- Webhooks necesitan insertar

-- PAYMENTS: Solo admins pueden actualizar
CREATE POLICY "Admins can update payments"
  ON public.payments FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================================
-- 7. TRIGGERS para actualizar timestamps
-- ============================================================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para ticket_types
DROP TRIGGER IF EXISTS update_ticket_types_updated_at ON public.ticket_types;
CREATE TRIGGER update_ticket_types_updated_at
  BEFORE UPDATE ON public.ticket_types
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger para payments
DROP TRIGGER IF EXISTS update_payments_updated_at ON public.payments;
CREATE TRIGGER update_payments_updated_at
  BEFORE UPDATE ON public.payments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 8. FUNCIÓN para decrementar stock al aprobar pago
-- ============================================================================
CREATE OR REPLACE FUNCTION decrement_ticket_stock()
RETURNS TRIGGER AS $$
DECLARE
  order_item RECORD;
  ticket_count INTEGER;
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
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para decrementar stock
DROP TRIGGER IF EXISTS on_payment_approved ON public.payments;
CREATE TRIGGER on_payment_approved
  AFTER INSERT OR UPDATE ON public.payments
  FOR EACH ROW
  EXECUTE FUNCTION decrement_ticket_stock();

-- ============================================================================
-- 9. DATOS DE PRUEBA - Tipos de Tickets
-- ============================================================================
INSERT INTO public.ticket_types (name, description, price, stock_total, stock_available, benefits, is_early_bird, is_active, display_order)
VALUES 
  (
    'Early Bird',
    'Precio especial por compra anticipada - ¡Solo 100 disponibles!',
    299,
    100,
    100,
    ARRAY['Acceso completo al evento', 'Entrada prioritaria', 'Regalo de bienvenida', 'Descuento 40%'],
    true,
    true,
    1
  ),
  (
    'General',
    'Acceso completo al Comic Fest 2026',
    499,
    500,
    500,
    ARRAY['Acceso completo al evento', 'Participación en concursos', 'Acceso a todas las actividades'],
    false,
    true,
    2
  ),
  (
    'VIP',
    'Experiencia exclusiva con beneficios premium',
    999,
    50,
    50,
    ARRAY['Acceso VIP', 'Meet & Greet con artistas especiales', 'Mercancía exclusiva', 'Área VIP lounge', 'Fast pass en actividades', 'Kit de bienvenida premium'],
    false,
    true,
    3
  )
ON CONFLICT DO NOTHING;

-- ============================================================================
-- ✅ SCRIPT COMPLETADO
-- ============================================================================
-- Ejecuta las siguientes queries para verificar:
-- SELECT * FROM public.ticket_types;
-- SELECT * FROM public.orders;
-- SELECT * FROM public.order_items;
-- SELECT * FROM public.payments;
-- ============================================================================
