-- ============================================================================
-- COMIC FEST - ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- ============================================================================
-- PROFILES (Perfiles de usuarios)
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Permitir SELECT: usuarios pueden ver todos los perfiles
CREATE POLICY "profiles_select_all" ON public.profiles
  FOR SELECT USING (true);

-- Permitir INSERT: usuarios pueden crear su propio perfil O si son admin pueden crear cualquiera
CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT WITH CHECK (
    auth.uid() = id OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Permitir UPDATE: usuarios pueden actualizar su propio perfil O si son admin pueden actualizar cualquiera
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (
    auth.uid() = id OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    auth.uid() = id OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Permitir DELETE: usuarios solo pueden eliminar su propio perfil O si son admin pueden eliminar cualquiera
CREATE POLICY "profiles_delete_own" ON public.profiles
  FOR DELETE USING (
    auth.uid() = id OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================================
-- TICKETS (Boletos)
-- ============================================================================
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;

-- Permitir SELECT: usuarios solo ven sus propios boletos
CREATE POLICY "tickets_select_own" ON public.tickets
  FOR SELECT USING (auth.uid() = user_id);

-- Permitir INSERT: usuarios solo pueden crear boletos para sí mismos
CREATE POLICY "tickets_insert_own" ON public.tickets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Permitir UPDATE: usuarios solo pueden actualizar sus propios boletos
CREATE POLICY "tickets_update_own" ON public.tickets
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Permitir DELETE: usuarios solo pueden eliminar sus propios boletos
CREATE POLICY "tickets_delete_own" ON public.tickets
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- SCHEDULE_ITEMS (Eventos de la agenda)
-- ============================================================================
ALTER TABLE public.schedule_items ENABLE ROW LEVEL SECURITY;

-- Permitir SELECT: todos pueden ver eventos activos
CREATE POLICY "schedule_items_select_all" ON public.schedule_items
  FOR SELECT USING (is_active = true);

-- Insertar: solo administradores y staff
CREATE POLICY "schedule_items_insert_admin" ON public.schedule_items
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  );

-- Actualizar: solo administradores y staff
CREATE POLICY "schedule_items_update_admin" ON public.schedule_items
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  );

-- Eliminar: solo administradores y staff
CREATE POLICY "schedule_items_delete_admin" ON public.schedule_items
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  );

-- ============================================================================
-- PRODUCTS (Productos de la tienda)
-- ============================================================================
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Permitir SELECT: todos pueden ver productos
CREATE POLICY "products_select_all" ON public.products
  FOR SELECT USING (true);

-- Insertar productos: administradores y staff
CREATE POLICY "products_insert_admin" ON public.products
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  );

-- Actualizar productos: administradores y staff
CREATE POLICY "products_update_admin" ON public.products
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  );

-- Eliminar productos: administradores y staff
CREATE POLICY "products_delete_admin" ON public.products
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  );

-- ============================================================================
-- POINTS_TRANSACTIONS (Transacciones de puntos)
-- ============================================================================
ALTER TABLE public.points_transactions ENABLE ROW LEVEL SECURITY;

-- Permitir SELECT: usuarios solo ven sus propias transacciones
CREATE POLICY "points_transactions_select_own" ON public.points_transactions
  FOR SELECT USING (auth.uid() = user_id);

-- Permitir INSERT: usuarios solo pueden crear transacciones para sí mismos
CREATE POLICY "points_transactions_insert_own" ON public.points_transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- UPDATE y DELETE: deshabilitados (las transacciones son inmutables)
