-- ============================================================================
-- COMIC FEST - POLÍTICAS ADICIONALES PARA STAFF (VALIDACIÓN DE BOLETOS)
-- ============================================================================
-- Ejecuta este script para permitir que el staff pueda leer y validar boletos
-- ============================================================================

-- Política para que STAFF y ADMIN puedan ver TODOS los boletos (necesario para escaneo)
DROP POLICY IF EXISTS "tickets_select_staff" ON public.tickets;
CREATE POLICY "tickets_select_staff" ON public.tickets
  FOR SELECT USING (
    -- El usuario ve sus propios boletos
    auth.uid() = user_id 
    OR 
    -- O es staff/admin (para validación)
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  );

-- Política para que STAFF y ADMIN puedan actualizar el estado de validación
DROP POLICY IF EXISTS "tickets_update_staff" ON public.tickets;
CREATE POLICY "tickets_update_staff" ON public.tickets
  FOR UPDATE USING (
    -- El usuario puede actualizar sus propios boletos
    auth.uid() = user_id 
    OR 
    -- O es staff/admin (para marcar como validado)
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  )
  WITH CHECK (
    -- El usuario puede actualizar sus propios boletos
    auth.uid() = user_id 
    OR 
    -- O es staff/admin (para marcar como validado)
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'staff')
    )
  );

-- ============================================================================
-- NOTA: Asegúrate de que las políticas antiguas estén deshabilitadas
-- ============================================================================
-- Si ya existían policies "tickets_select_own" y "tickets_update_own", 
-- las nuevas las reemplazarán automáticamente con DROP POLICY IF EXISTS
-- ============================================================================
