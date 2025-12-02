-- ============================================================================
-- FIX: Infinite Recursion in order_items Policy (Code 42P17)
-- ============================================================================

-- 1. Eliminar políticas recursivas
DROP POLICY IF EXISTS "Users can view their own order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can create their own order items" ON public.order_items;

-- 2. Crear políticas simplificadas y no recursivas
-- En lugar de hacer JOIN con orders (que podría tener políticas que hagan JOIN con order_items),
-- verificamos directamente si el usuario es dueño de la orden mediante una subquery simple.

CREATE POLICY "Users can view their own order items"
  ON public.order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

-- Para INSERT, permitimos insertar si la orden asociada pertenece al usuario.
-- IMPORTANTE: Asegurarse de que la política de INSERT en 'orders' no dependa de 'order_items'.
CREATE POLICY "Users can create their own order items"
  ON public.order_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

-- 3. Política para Admins (para evitar bloqueos en el panel de admin)
CREATE POLICY "Admins can view all order items"
  ON public.order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 4. Revisar políticas de ORDERS para asegurar que no causen el ciclo
-- La política "orders_select_seller" que creamos antes hacía JOIN con order_items.
-- Si order_items hace JOIN con orders, tenemos un ciclo infinito.

-- SOLUCIÓN: Romper el ciclo en la política de VENDEDORES de ORDERS.
-- Usamos SECURITY DEFINER o una función, pero lo más simple es optimizar la query.

DROP POLICY IF EXISTS "orders_select_seller" ON public.orders;

CREATE POLICY "orders_select_seller" ON public.orders
  FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.order_items oi
      JOIN public.products p ON p.id = oi.product_id
      WHERE oi.order_id = orders.id 
      AND p.seller_id = auth.uid()
    )
  );
-- Nota: Esta política parece igual, pero el problema es si 'order_items' tiene RLS activado
-- y su política de SELECT depende de 'orders'.
-- Al consultar 'orders', se evalúa esta política -> consulta 'order_items' -> evalúa política de 'order_items' -> consulta 'orders' -> CICLO.

-- PARA ROMPER EL CICLO:
-- La política de 'order_items' NO debe consultar 'orders' si es posible, O
-- La política de 'orders' NO debe consultar 'order_items'.

-- En este caso, es mejor simplificar la política de 'order_items' para que confíe en el ID de la orden
-- si ya se verificó el acceso a la orden padre. Pero RLS no funciona así jerárquicamente.

-- MEJOR SOLUCIÓN: Bypass RLS para la verificación interna
-- Creamos una función SECURITY DEFINER para verificar propiedad del vendedor sin disparar RLS de order_items.

CREATE OR REPLACE FUNCTION auth_is_seller_of_order(order_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.order_items oi
    JOIN public.products p ON p.id = oi.product_id
    WHERE oi.order_id = order_uuid 
    AND p.seller_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-aplicar política usando la función segura
CREATE POLICY "orders_select_seller_safe" ON public.orders
  FOR SELECT 
  USING (
    auth.role() = 'authenticated' AND (
      -- Usuario dueño
      user_id = auth.uid() 
      OR 
      -- Vendedor (usando función segura)
      auth_is_seller_of_order(id)
    )
  );

-- Limpiar políticas anteriores conflictivas
DROP POLICY IF EXISTS "orders_select_own" ON public.orders; -- Reemplazada por la combinada arriba
DROP POLICY IF EXISTS "orders_select_seller" ON public.orders;

-- Restaurar política simple para INSERT (sin cambios)
-- CREATE POLICY "orders_insert_own" ... (ya existe)
