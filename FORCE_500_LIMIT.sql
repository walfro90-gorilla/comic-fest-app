-- SOLUCIÓN "MARTILLAZO FINAL"
-- Si no podemos encontrar el fantasma que suma 1000...
-- Vamos a crear un trigger que detecte si alguien tiene más de 500 puntos al nacer y lo CORRIJA a la fuerza.

-- Este trigger se ejecutará AL FINAL de todo.
CREATE OR REPLACE FUNCTION public.force_initial_points_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Si es una inserción nueva y tiene más de 500 puntos (ej. 1500)
    -- Y no tiene historial de compras (es decir, es nuevo de verdad)
    IF NEW.points > 500 THEN
        -- Verificar si tiene otros logs de puntos aparte del de bienvenida
        IF NOT EXISTS (SELECT 1 FROM public.points_log WHERE user_id = NEW.id AND reason NOT LIKE 'Bono de Bienvenida%') THEN
             NEW.points := 500; -- 🔥 TE ATRAPÉ. CORREGIDO A 500.
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS zzz_force_points_limit ON public.profiles;
CREATE TRIGGER zzz_force_points_limit
    BEFORE INSERT OR UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.force_initial_points_limit();
