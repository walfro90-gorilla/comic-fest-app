-- SOLUCIÓN AL PROBLEMA DE "TRIPLE RESTA"
-- Encontramos 2 triggers en points_log + 1 update manual en la función SQL = 3 Updates.

-- 1. Eliminamos los triggers automáticos que actualizan el perfil al insertar un log.
--    (Ya estamos controlando la actualización MANUALMENTE y ATÓMICAMENTE en 'redeem_reward' y 'add_points').
DROP TRIGGER IF EXISTS on_points_change ON public.points_log;
DROP TRIGGER IF EXISTS trigger_update_user_points ON public.points_log;

-- 2. Limpieza adicional de funciones huérfanas (opcional pero recomendado)
-- DROP FUNCTION IF EXISTS handle_points_change;
-- DROP FUNCTION IF EXISTS update_user_points;
