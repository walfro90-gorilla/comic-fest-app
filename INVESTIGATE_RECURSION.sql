-- INVESTIGACIÓN RECURSIVA
-- Sospecho que al actualizar 'updated_at' o alguna otra columna, se está disparando un trigger oculto.

-- 1. Ver TODOS los triggers DETALLADOS de la tabla profiles
SELECT 
    trigger_name, 
    event_manipulation, 
    action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'profiles';

-- 2. Ver si la función add_points está siendo llamada recursivamente
-- (Esto es difícil de ver directamente, pero revisaremos la lógica de updated_at)

-- 3. Crear función de pánico para ver quién está sumando
-- Pondremos un trigger dummy que lance una excepción con el stack trace si los puntos cambian inesperadamente
CREATE OR REPLACE FUNCTION public.debug_points_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.points > 500 AND OLD.points <= 500 THEN
       RAISE EXCEPTION 'ALERTA PUNTOS: Puntos cambiaron de % a % (Usuario: %). Stack: %', OLD.points, NEW.points, NEW.id, pg_catalog.pg_backend_pid();
    END IF;
    RETURN NEW;
END;
$$;

-- SOLO EJECUTAR ESTO SI ESTAMOS DESESPERADOS (Bloqueará updates > 500)
-- CREATE TRIGGER debug_points_monitor
-- BEFORE UPDATE ON public.profiles
-- FOR EACH ROW
-- EXECUTE FUNCTION public.debug_points_change();
