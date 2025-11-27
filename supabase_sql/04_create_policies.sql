-- ============================================================================
-- COMIC FEST - ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
-- Ejecuta este script DESPUÉS de crear tablas, índices y triggers
-- ============================================================================

-- ============================================================================
-- 1. PROFILES - Perfiles de usuarios
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- SELECT: Todos pueden ver todos los perfiles
DROP POLICY IF EXISTS "profiles_select_all" ON public.profiles;
CREATE POLICY "profiles_select_all" ON public.profiles
  FOR SELECT USING (true);

-- INSERT: Usuarios pueden crear su propio perfil O admins pueden crear cualquiera
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT WITH CHECK (
    auth.uid() = id OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- UPDATE: Usuarios pueden actualizar su propio perfil O admins pueden actualizar cualquiera
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
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

-- DELETE: Usuarios pueden eliminar su propio perfil O admins pueden eliminar cualquiera
DROP POLICY IF EXISTS "profiles_delete_own" ON public.profiles;
CREATE POLICY "profiles_delete_own" ON public.profiles
  FOR DELETE USING (
    auth.uid() = id OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================================
-- 2. TICKETS - Boletos
-- ============================================================================
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;

-- SELECT: Usuarios solo ven sus propios boletos
DROP POLICY IF EXISTS "tickets_select_own" ON public.tickets;
CREATE POLICY "tickets_select_own" ON public.tickets
  FOR SELECT USING (auth.uid() = user_id);

-- INSERT: Usuarios solo pueden crear boletos para sí mismos
DROP POLICY IF EXISTS "tickets_insert_own" ON public.tickets;
CREATE POLICY "tickets_insert_own" ON public.tickets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- UPDATE: Usuarios solo pueden actualizar sus propios boletos
DROP POLICY IF EXISTS "tickets_update_own" ON public.tickets;
CREATE POLICY "tickets_update_own" ON public.tickets
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- DELETE: Usuarios solo pueden eliminar sus propios boletos
DROP POLICY IF EXISTS "tickets_delete_own" ON public.tickets;
CREATE POLICY "tickets_delete_own" ON public.tickets
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- 3. SCHEDULE_ITEMS - Eventos de la agenda
-- ============================================================================
ALTER TABLE public.schedule_items ENABLE ROW LEVEL SECURITY;

-- SELECT: Todos pueden ver eventos activos
DROP POLICY IF EXISTS "schedule_items_select_all" ON public.schedule_items;
CREATE POLICY "schedule_items_select_all" ON public.schedule_items
  FOR SELECT USING (is_active = true);

-- INSERT: Solo administradores y staff
DROP POLICY IF EXISTS "schedule_items_insert_admin" ON public.schedule_items;
CREATE POLICY "schedule_items_insert_admin" ON public.schedule_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  );

-- UPDATE: Solo administradores y staff
DROP POLICY IF EXISTS "schedule_items_update_admin" ON public.schedule_items;
CREATE POLICY "schedule_items_update_admin" ON public.schedule_items
  FOR UPDATE USING (
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

-- DELETE: Solo administradores y staff
DROP POLICY IF EXISTS "schedule_items_delete_admin" ON public.schedule_items;
CREATE POLICY "schedule_items_delete_admin" ON public.schedule_items
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  );

-- ============================================================================
-- 4. PRODUCTS - Productos de la tienda
-- ============================================================================
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- SELECT: Todos pueden ver productos
DROP POLICY IF EXISTS "products_select_all" ON public.products;
CREATE POLICY "products_select_all" ON public.products
  FOR SELECT USING (true);

-- INSERT: Administradores y staff
DROP POLICY IF EXISTS "products_insert_admin" ON public.products;
CREATE POLICY "products_insert_admin" ON public.products
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  );

-- UPDATE: Administradores y staff
DROP POLICY IF EXISTS "products_update_admin" ON public.products;
CREATE POLICY "products_update_admin" ON public.products
  FOR UPDATE USING (
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

-- DELETE: Administradores y staff
DROP POLICY IF EXISTS "products_delete_admin" ON public.products;
CREATE POLICY "products_delete_admin" ON public.products
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  );

-- ============================================================================
-- 5. POINTS_LOG - Transacciones de puntos
-- ============================================================================
ALTER TABLE public.points_log ENABLE ROW LEVEL SECURITY;

-- SELECT: Usuarios solo ven sus propias transacciones
DROP POLICY IF EXISTS "points_log_select_own" ON public.points_log;
CREATE POLICY "points_log_select_own" ON public.points_log
  FOR SELECT USING (auth.uid() = user_id);

-- INSERT: Usuarios solo pueden crear transacciones para sí mismos
DROP POLICY IF EXISTS "points_log_insert_own" ON public.points_log;
CREATE POLICY "points_log_insert_own" ON public.points_log
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- UPDATE y DELETE: Deshabilitados (las transacciones son inmutables)

-- ============================================================================
-- 6. MAP_POINTS - Puntos del mapa
-- ============================================================================
ALTER TABLE public.map_points ENABLE ROW LEVEL SECURITY;

-- SELECT: Todos pueden ver puntos públicos del mapa
DROP POLICY IF EXISTS "map_points_select_public" ON public.map_points;
CREATE POLICY "map_points_select_public" ON public.map_points
  FOR SELECT USING (is_public = true);

-- INSERT/UPDATE/DELETE: Solo admins y staff
DROP POLICY IF EXISTS "map_points_admin_all" ON public.map_points;
CREATE POLICY "map_points_admin_all" ON public.map_points
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  );

-- ============================================================================
-- 7. EXHIBITOR_DETAILS - Detalles de expositores
-- ============================================================================
ALTER TABLE public.exhibitor_details ENABLE ROW LEVEL SECURITY;

-- SELECT: Todos pueden ver detalles de expositores
DROP POLICY IF EXISTS "exhibitor_details_select_all" ON public.exhibitor_details;
CREATE POLICY "exhibitor_details_select_all" ON public.exhibitor_details
  FOR SELECT USING (true);

-- INSERT/UPDATE/DELETE: Solo admins, staff y el propio expositor
DROP POLICY IF EXISTS "exhibitor_details_manage" ON public.exhibitor_details;
CREATE POLICY "exhibitor_details_manage" ON public.exhibitor_details
  FOR ALL USING (
    auth.uid() = profile_id OR
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  );

-- ============================================================================
-- 8. PROMOTIONS - Promociones
-- ============================================================================
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;

-- SELECT: Todos pueden ver promociones activas
DROP POLICY IF EXISTS "promotions_select_active" ON public.promotions;
CREATE POLICY "promotions_select_active" ON public.promotions
  FOR SELECT USING (is_active = true);

-- INSERT/UPDATE/DELETE: Admins, staff y el propio expositor
DROP POLICY IF EXISTS "promotions_manage" ON public.promotions;
CREATE POLICY "promotions_manage" ON public.promotions
  FOR ALL USING (
    auth.uid() = exhibitor_id OR
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  );

-- ============================================================================
-- 9. CONTESTS - Concursos
-- ============================================================================
ALTER TABLE public.contests ENABLE ROW LEVEL SECURITY;

-- SELECT: Todos pueden ver concursos activos
DROP POLICY IF EXISTS "contests_select_active" ON public.contests;
CREATE POLICY "contests_select_active" ON public.contests
  FOR SELECT USING (is_active = true);

-- INSERT/UPDATE/DELETE: Solo admins
DROP POLICY IF EXISTS "contests_admin_only" ON public.contests;
CREATE POLICY "contests_admin_only" ON public.contests
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  );

-- ============================================================================
-- 10. CONTEST_ENTRIES - Participantes de concursos
-- ============================================================================
ALTER TABLE public.contest_entries ENABLE ROW LEVEL SECURITY;

-- SELECT: Todos pueden ver participantes
DROP POLICY IF EXISTS "contest_entries_select_all" ON public.contest_entries;
CREATE POLICY "contest_entries_select_all" ON public.contest_entries
  FOR SELECT USING (true);

-- INSERT/UPDATE/DELETE: Solo admins
DROP POLICY IF EXISTS "contest_entries_admin_only" ON public.contest_entries;
CREATE POLICY "contest_entries_admin_only" ON public.contest_entries
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  );

-- ============================================================================
-- 11. VOTES - Votos en concursos
-- ============================================================================
ALTER TABLE public.votes ENABLE ROW LEVEL SECURITY;

-- SELECT: Usuarios solo ven sus propios votos
DROP POLICY IF EXISTS "votes_select_own" ON public.votes;
CREATE POLICY "votes_select_own" ON public.votes
  FOR SELECT USING (auth.uid() = user_id);

-- INSERT: Usuarios solo pueden votar por sí mismos
DROP POLICY IF EXISTS "votes_insert_own" ON public.votes;
CREATE POLICY "votes_insert_own" ON public.votes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- UPDATE/DELETE: No permitidos (votos son inmutables)

-- ============================================================================
-- 12. PASSPORT_STAMPS - Pasaporte virtual
-- ============================================================================
ALTER TABLE public.passport_stamps ENABLE ROW LEVEL SECURITY;

-- SELECT: Usuarios solo ven sus propios sellos
DROP POLICY IF EXISTS "passport_stamps_select_own" ON public.passport_stamps;
CREATE POLICY "passport_stamps_select_own" ON public.passport_stamps
  FOR SELECT USING (auth.uid() = user_id);

-- INSERT: Usuarios y expositores pueden crear sellos
DROP POLICY IF EXISTS "passport_stamps_insert" ON public.passport_stamps;
CREATE POLICY "passport_stamps_insert" ON public.passport_stamps
  FOR INSERT WITH CHECK (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM public.exhibitor_details
      WHERE profile_id = auth.uid()
    )
  );

-- UPDATE/DELETE: No permitidos (sellos son inmutables)

-- ============================================================================
-- 13. ORDERS - Pedidos
-- ============================================================================
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- SELECT: Usuarios solo ven sus propios pedidos
DROP POLICY IF EXISTS "orders_select_own" ON public.orders;
CREATE POLICY "orders_select_own" ON public.orders
  FOR SELECT USING (auth.uid() = user_id);

-- INSERT: Usuarios solo pueden crear pedidos para sí mismos
DROP POLICY IF EXISTS "orders_insert_own" ON public.orders;
CREATE POLICY "orders_insert_own" ON public.orders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- UPDATE: Usuarios pueden actualizar sus propios pedidos O admins pueden actualizar cualquiera
DROP POLICY IF EXISTS "orders_update" ON public.orders;
CREATE POLICY "orders_update" ON public.orders
  FOR UPDATE USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  );

-- DELETE: Solo admins
DROP POLICY IF EXISTS "orders_delete_admin" ON public.orders;
CREATE POLICY "orders_delete_admin" ON public.orders
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  );
