-- ============================================================================
-- FIX: Infinite Recursion in RLS Policies (Definitive Fix)
-- ============================================================================

-- 1. Eliminar TODAS las políticas conflictivas de 'orders' y 'order_items'
DROP POLICY IF EXISTS "orders_select_seller" ON public.orders;
DROP POLICY IF EXISTS "orders_update_seller" ON public.orders;
DROP POLICY IF EXISTS "orders_select_own" ON public.orders;
DROP POLICY IF EXISTS "orders_select_seller_safe" ON public.orders;
DROP POLICY IF EXISTS "Users can view their own order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can create their own order items" ON public.order_items;
DROP POLICY IF EXISTS "Admins can view all order items" ON public.order_items;

-- 2. Crear función SECURITY DEFINER para verificar acceso a order_items sin disparar RLS
-- Esta función verifica si el usuario es dueño de la orden padre de un item
CREATE OR REPLACE FUNCTION public.auth_is_owner_of_order_for_item(order_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  -- Consultamos la tabla orders directamente, ignorando RLS gracias a SECURITY DEFINER
  RETURN EXISTS (
    SELECT 1 FROM public.orders
    WHERE id = order_uuid
    AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Crear función SECURITY DEFINER para verificar si un usuario es vendedor de una orden
CREATE OR REPLACE FUNCTION public.auth_is_seller_of_order(order_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  -- Consultamos order_items y products directamente, ignorando RLS
  RETURN EXISTS (
    SELECT 1 FROM public.order_items oi
    JOIN public.products p ON p.id = oi.product_id
    WHERE oi.order_id = order_uuid 
    AND p.seller_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Recrear políticas de ORDERS usando las funciones seguras (o lógica simple)

-- SELECT: Usuario dueño O Vendedor O Admin
CREATE POLICY "orders_select_policy" ON public.orders
  FOR SELECT 
  USING (
    auth.uid() = user_id -- Dueño
    OR
    public.auth_is_seller_of_order(id) -- Vendedor (vía función segura)
    OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin') -- Admin
  );

-- UPDATE: Vendedor O Admin (Los usuarios normales no actualizan órdenes, solo el sistema/admin)
CREATE POLICY "orders_update_policy" ON public.orders
  FOR UPDATE
  USING (
    public.auth_is_seller_of_order(id) -- Vendedor
    OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin') -- Admin
  );

-- INSERT: Usuario autenticado puede crear orden propia
CREATE POLICY "orders_insert_policy" ON public.orders
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);


-- 5. Recrear políticas de ORDER_ITEMS usando la función segura

-- SELECT: Dueño de la orden O Admin (Los vendedores ven items a través de la orden, o podríamos añadir lógica aquí)
CREATE POLICY "order_items_select_policy" ON public.order_items
  FOR SELECT
  USING (
    public.auth_is_owner_of_order_for_item(order_id) -- Dueño (vía función segura)
    OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin') -- Admin
    OR
    -- Permitir a vendedores ver items de sus productos
    EXISTS (
      SELECT 1 FROM public.products p 
      WHERE p.id = product_id AND p.seller_id = auth.uid()
    )
  );

-- INSERT: Dueño de la orden (al crear la orden)
CREATE POLICY "order_items_insert_policy" ON public.order_items
  FOR INSERT
  WITH CHECK (
    public.auth_is_owner_of_order_for_item(order_id)
  );

-- 6. Asegurar permisos para PAYMENTS (que también se relacionan con orders)
-- Si payments consulta orders, y orders consulta payments (no debería), podría haber lío.
-- Pero payments suele ser simple. Revisamos por si acaso.

DROP POLICY IF EXISTS "Users can view their own payments" ON public.payments;
CREATE POLICY "payments_select_policy" ON public.payments
  FOR SELECT
  USING (
    -- Usamos la misma lógica segura: verificar si es dueño de la orden asociada
    public.auth_is_owner_of_order_for_item(order_id)
    OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

