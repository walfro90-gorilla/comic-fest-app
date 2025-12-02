-- ============================================================================
-- FIX: Sistema de Puntos - Trigger para acumulación automática
-- ============================================================================

-- 1. Función para manejar el cambio de puntos
CREATE OR REPLACE FUNCTION public.handle_points_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Actualizar los puntos del usuario sumando el cambio (puede ser positivo o negativo)
  UPDATE public.profiles
  SET points = points + NEW.points_change,
      updated_at = now()
  WHERE id = NEW.user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Trigger que se dispara al insertar en points_log
DROP TRIGGER IF EXISTS on_points_change ON public.points_log;

CREATE TRIGGER on_points_change
  AFTER INSERT ON public.points_log
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_points_change();

-- 3. Comentario de documentación
COMMENT ON FUNCTION public.handle_points_change IS 'Actualiza automáticamente el total de puntos del usuario cuando se registra una transacción en points_log';
