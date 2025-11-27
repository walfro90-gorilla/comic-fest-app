-- ============================================================================
-- COMIC FEST - FIX: Permitir actualizar estados de pago para usuarios
-- ============================================================================
-- Ejecuta este script en Supabase SQL Editor
-- ============================================================================

-- Eliminar la política restrictiva anterior
DROP POLICY IF EXISTS "Admins can update payments" ON public.payments;

-- Nueva política: Usuarios pueden actualizar sus propios pagos (para simulación)
-- En producción real, solo webhooks de MP actualizarán pagos
CREATE POLICY "Users can update their own payments"
  ON public.payments FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = payments.order_id
        AND orders.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = payments.order_id
        AND orders.user_id = auth.uid()
    )
  );

-- Política adicional: Admins pueden actualizar cualquier pago
CREATE POLICY "Admins can update any payment"
  ON public.payments FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================================
-- NOTA: En producción, considera crear una edge function para procesar
-- webhooks de Mercado Pago con una service role key que bypasee RLS
-- ============================================================================
