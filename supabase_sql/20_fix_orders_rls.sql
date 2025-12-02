-- ============================================================================
-- FIX: RLS Policies for Orders (Fix JSONB error 22023)
-- ============================================================================

-- 1. Eliminar políticas problemáticas que usan jsonb_array_elements en objetos
DROP POLICY IF EXISTS "orders_select_seller" ON public.orders;
DROP POLICY IF EXISTS "orders_update_seller" ON public.orders;

-- 2. Recrear políticas usando la tabla relacional order_items (más seguro y eficiente)

-- Los vendedores pueden ver órdenes que contienen sus productos
CREATE POLICY "orders_select_seller" ON public.orders
  FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'exhibitor'
    ) AND
    EXISTS (
      SELECT 1 FROM public.order_items oi
      JOIN public.products p ON p.id = oi.product_id
      WHERE oi.order_id = orders.id AND p.seller_id = auth.uid()
    )
  );

-- Los vendedores pueden actualizar órdenes de sus productos
CREATE POLICY "orders_update_seller" ON public.orders
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'exhibitor'
    ) AND
    EXISTS (
      SELECT 1 FROM public.order_items oi
      JOIN public.products p ON p.id = oi.product_id
      WHERE oi.order_id = orders.id AND p.seller_id = auth.uid()
    )
  );

-- 3. Asegurar que los ADMINS tengan acceso total a orders (faltaba explícitamente)
CREATE POLICY "Admins can view all orders" ON public.orders
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update all orders" ON public.orders
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
