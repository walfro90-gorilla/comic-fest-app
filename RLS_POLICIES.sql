-- ================================================================================================
-- SCRIPT DE POLÍTICAS RLS PARA COMIC FEST APP
-- ================================================================================================
-- IMPORTANTE: Este script asume que RLS ya está habilitado en todas las tablas.
-- Para habilitar RLS: ALTER TABLE nombre_tabla ENABLE ROW LEVEL SECURITY;
-- ================================================================================================

-- ================================================================================================
-- 1. POLÍTICAS PARA 'profiles' (Usuarios)
-- ================================================================================================

-- Todos los usuarios autenticados pueden ver todos los perfiles (para mostrar avatares, nombres, etc.)
CREATE POLICY "profiles_select_authenticated" ON public.profiles
  FOR SELECT 
  USING (auth.role() = 'authenticated');

-- Los usuarios solo pueden actualizar su propio perfil
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE 
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Solo el sistema puede insertar perfiles (se crean automáticamente con triggers)
CREATE POLICY "profiles_insert_system" ON public.profiles
  FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- Nadie puede eliminar perfiles (solo marcar como inactivo si fuera necesario)
CREATE POLICY "profiles_delete_denied" ON public.profiles
  FOR DELETE 
  USING (FALSE);

-- ================================================================================================
-- 2. POLÍTICAS PARA 'map_points' (Mapa del evento)
-- ================================================================================================

-- Todos pueden ver puntos públicos del mapa
CREATE POLICY "map_points_select_public" ON public.map_points
  FOR SELECT 
  USING (is_public = TRUE);

-- Solo admins pueden insertar puntos
CREATE POLICY "map_points_insert_admin" ON public.map_points
  FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo admins pueden actualizar puntos
CREATE POLICY "map_points_update_admin" ON public.map_points
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo admins pueden eliminar puntos
CREATE POLICY "map_points_delete_admin" ON public.map_points
  FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ================================================================================================
-- 3. POLÍTICAS PARA 'schedule_items' (Agenda de eventos)
-- ================================================================================================

-- Todos pueden ver items activos del schedule
CREATE POLICY "schedule_items_select_active" ON public.schedule_items
  FOR SELECT 
  USING (is_active = TRUE);

-- Solo admins pueden insertar items
CREATE POLICY "schedule_items_insert_admin" ON public.schedule_items
  FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo admins pueden actualizar items
CREATE POLICY "schedule_items_update_admin" ON public.schedule_items
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo admins pueden eliminar items
CREATE POLICY "schedule_items_delete_admin" ON public.schedule_items
  FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ================================================================================================
-- 4. POLÍTICAS PARA 'exhibitor_details' (Detalles de expositores)
-- ================================================================================================

-- Todos pueden ver detalles de expositores
CREATE POLICY "exhibitor_details_select_all" ON public.exhibitor_details
  FOR SELECT 
  USING (TRUE);

-- Solo admins pueden insertar expositores
CREATE POLICY "exhibitor_details_insert_admin" ON public.exhibitor_details
  FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Los expositores pueden actualizar su propia información
CREATE POLICY "exhibitor_details_update_own" ON public.exhibitor_details
  FOR UPDATE 
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- Solo admins pueden eliminar expositores
CREATE POLICY "exhibitor_details_delete_admin" ON public.exhibitor_details
  FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ================================================================================================
-- 5. POLÍTICAS CRÍTICAS PARA 'tickets' (Boletaje)
-- ================================================================================================

-- Los usuarios solo pueden ver sus propios boletos
CREATE POLICY "tickets_select_own" ON public.tickets
  FOR SELECT 
  USING (auth.uid() = user_id);

-- Staff y admins pueden ver todos los boletos (para validación)
CREATE POLICY "tickets_select_staff" ON public.tickets
  FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role IN ('staff', 'admin')
    )
  );

-- Nadie puede insertar boletos directamente desde la app (solo via backend/webhook de MP)
CREATE POLICY "tickets_insert_denied" ON public.tickets
  FOR INSERT 
  WITH CHECK (FALSE);

-- Solo staff puede actualizar boletos (para validación)
CREATE POLICY "tickets_update_staff" ON public.tickets
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role IN ('staff', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role IN ('staff', 'admin')
    )
  );

-- Nadie puede eliminar boletos
CREATE POLICY "tickets_delete_denied" ON public.tickets
  FOR DELETE 
  USING (FALSE);

-- ================================================================================================
-- 6. POLÍTICAS PARA 'products' (Productos/Merchandising)
-- ================================================================================================

-- Todos pueden ver productos activos
CREATE POLICY "products_select_active" ON public.products
  FOR SELECT 
  USING (is_active = TRUE);

-- Los vendedores (expositores) pueden insertar sus propios productos
CREATE POLICY "products_insert_seller" ON public.products
  FOR INSERT 
  WITH CHECK (
    auth.uid() = seller_id AND
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role IN ('exhibitor', 'admin')
    )
  );

-- Los vendedores pueden actualizar sus propios productos
CREATE POLICY "products_update_seller" ON public.products
  FOR UPDATE 
  USING (auth.uid() = seller_id)
  WITH CHECK (auth.uid() = seller_id);

-- Los vendedores pueden eliminar sus propios productos
CREATE POLICY "products_delete_seller" ON public.products
  FOR DELETE 
  USING (auth.uid() = seller_id);

-- ================================================================================================
-- 7. POLÍTICAS PARA 'orders' (Órdenes de compra)
-- ================================================================================================

-- Los usuarios solo pueden ver sus propias órdenes
CREATE POLICY "orders_select_own" ON public.orders
  FOR SELECT 
  USING (auth.uid() = user_id);

-- Los vendedores pueden ver órdenes de sus productos
CREATE POLICY "orders_select_seller" ON public.orders
  FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'exhibitor'
    ) AND
    EXISTS (
      SELECT 1 FROM jsonb_array_elements(items) AS item
      INNER JOIN public.products p ON p.id = (item->>'product_id')::uuid
      WHERE p.seller_id = auth.uid()
    )
  );

-- Los usuarios pueden crear sus propias órdenes
CREATE POLICY "orders_insert_own" ON public.orders
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Los vendedores pueden actualizar el estado de órdenes de sus productos
CREATE POLICY "orders_update_seller" ON public.orders
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM jsonb_array_elements(items) AS item
      INNER JOIN public.products p ON p.id = (item->>'product_id')::uuid
      WHERE p.seller_id = auth.uid()
    )
  );

-- Nadie puede eliminar órdenes
CREATE POLICY "orders_delete_denied" ON public.orders
  FOR DELETE 
  USING (FALSE);

-- ================================================================================================
-- 8. POLÍTICAS PARA 'points_log' (Historial de puntos)
-- ================================================================================================

-- Los usuarios solo pueden ver su propio historial de puntos
CREATE POLICY "points_log_select_own" ON public.points_log
  FOR SELECT 
  USING (auth.uid() = user_id);

-- Los usuarios pueden insertar transacciones de puntos (offline-first)
CREATE POLICY "points_log_insert_own" ON public.points_log
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Los usuarios pueden actualizar sus propias transacciones (para sincronización)
CREATE POLICY "points_log_update_own" ON public.points_log
  FOR UPDATE 
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Nadie puede eliminar transacciones de puntos
CREATE POLICY "points_log_delete_denied" ON public.points_log
  FOR DELETE 
  USING (FALSE);

-- ================================================================================================
-- 9. POLÍTICAS PARA 'passport_stamps' (Sellos del pasaporte)
-- ================================================================================================

-- Los usuarios pueden ver sus propios sellos
CREATE POLICY "passport_stamps_select_own" ON public.passport_stamps
  FOR SELECT 
  USING (auth.uid() = user_id);

-- Los expositores pueden ver sellos de su stand
CREATE POLICY "passport_stamps_select_exhibitor" ON public.passport_stamps
  FOR SELECT 
  USING (auth.uid() = exhibitor_id);

-- Los expositores pueden insertar sellos para usuarios que visiten su stand
CREATE POLICY "passport_stamps_insert_exhibitor" ON public.passport_stamps
  FOR INSERT 
  WITH CHECK (
    auth.uid() = exhibitor_id AND
    EXISTS (
      SELECT 1 FROM public.exhibitor_details 
      WHERE profile_id = auth.uid()
    )
  );

-- Nadie puede actualizar sellos (son inmutables)
CREATE POLICY "passport_stamps_update_denied" ON public.passport_stamps
  FOR UPDATE 
  USING (FALSE);

-- Nadie puede eliminar sellos
CREATE POLICY "passport_stamps_delete_denied" ON public.passport_stamps
  FOR DELETE 
  USING (FALSE);

-- ================================================================================================
-- 10. POLÍTICAS PARA 'promotions' (Promociones)
-- ================================================================================================

-- Todos pueden ver promociones activas
CREATE POLICY "promotions_select_active" ON public.promotions
  FOR SELECT 
  USING (is_active = TRUE);

-- Los expositores pueden insertar sus propias promociones
CREATE POLICY "promotions_insert_exhibitor" ON public.promotions
  FOR INSERT 
  WITH CHECK (
    auth.uid() = exhibitor_id AND
    EXISTS (
      SELECT 1 FROM public.exhibitor_details 
      WHERE profile_id = auth.uid()
    )
  );

-- Los expositores pueden actualizar sus propias promociones
CREATE POLICY "promotions_update_exhibitor" ON public.promotions
  FOR UPDATE 
  USING (auth.uid() = exhibitor_id)
  WITH CHECK (auth.uid() = exhibitor_id);

-- Los expositores pueden eliminar sus propias promociones
CREATE POLICY "promotions_delete_exhibitor" ON public.promotions
  FOR DELETE 
  USING (auth.uid() = exhibitor_id);

-- ================================================================================================
-- 11. POLÍTICAS PARA 'contests' (Concursos)
-- ================================================================================================

-- Todos pueden ver concursos activos
CREATE POLICY "contests_select_active" ON public.contests
  FOR SELECT 
  USING (is_active = TRUE);

-- Solo admins pueden insertar concursos
CREATE POLICY "contests_insert_admin" ON public.contests
  FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo admins pueden actualizar concursos
CREATE POLICY "contests_update_admin" ON public.contests
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo admins pueden eliminar concursos
CREATE POLICY "contests_delete_admin" ON public.contests
  FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ================================================================================================
-- 12. POLÍTICAS PARA 'contest_entries' (Entradas de concursos)
-- ================================================================================================

-- Todos pueden ver entradas de concursos activos
CREATE POLICY "contest_entries_select_all" ON public.contest_entries
  FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.contests 
      WHERE id = contest_id AND is_active = TRUE
    )
  );

-- Usuarios autenticados pueden insertar entradas
CREATE POLICY "contest_entries_insert_authenticated" ON public.contest_entries
  FOR INSERT 
  WITH CHECK (
    auth.role() = 'authenticated' AND
    EXISTS (
      SELECT 1 FROM public.contests 
      WHERE id = contest_id AND is_active = TRUE
    )
  );

-- Solo admins pueden actualizar entradas (para moderar contenido)
CREATE POLICY "contest_entries_update_admin" ON public.contest_entries
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo admins pueden eliminar entradas (para moderar contenido)
CREATE POLICY "contest_entries_delete_admin" ON public.contest_entries
  FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ================================================================================================
-- 13. POLÍTICAS PARA 'votes' (Votos de concursos)
-- ================================================================================================

-- Los usuarios solo pueden ver sus propios votos
CREATE POLICY "votes_select_own" ON public.votes
  FOR SELECT 
  USING (auth.uid() = user_id);

-- Los usuarios pueden votar (insertar)
CREATE POLICY "votes_insert_own" ON public.votes
  FOR INSERT 
  WITH CHECK (
    auth.uid() = user_id AND
    -- Verificar que el concurso esté activo y dentro del período de votación
    EXISTS (
      SELECT 1 FROM public.contests 
      WHERE id = contest_id 
        AND is_active = TRUE
        AND NOW() BETWEEN voting_start AND voting_end
    )
  );

-- Nadie puede actualizar votos (son inmutables)
CREATE POLICY "votes_update_denied" ON public.votes
  FOR UPDATE 
  USING (FALSE);

-- Los usuarios pueden eliminar sus propios votos (para cambiar de opinión)
CREATE POLICY "votes_delete_own" ON public.votes
  FOR DELETE 
  USING (auth.uid() = user_id);

-- ================================================================================================
-- FIN DEL SCRIPT DE POLÍTICAS RLS
-- ================================================================================================
-- NOTAS IMPORTANTES:
-- 1. Este script usa EXISTS con subqueries en lugar de auth.jwt() ->> 'role' para mejor rendimiento
--    y mayor seguridad, ya que lee directamente de la tabla profiles.
-- 2. Todas las políticas están separadas por operación (SELECT, INSERT, UPDATE, DELETE) para
--    mayor claridad y control granular.
-- 3. Las políticas para tickets son especialmente estrictas para evitar fraudes.
-- 4. El sistema de puntos permite operaciones offline-first con sincronización posterior.
-- 5. Las órdenes no se pueden eliminar para mantener el historial de transacciones.
-- ================================================================================================
