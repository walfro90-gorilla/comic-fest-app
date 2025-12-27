-- LIMPIEZA DE TRIGGERS DUPLICADOS
-- En tu lista aparecía 'zzz_force_points_limit' DOS VECES y también 'handle_updated_at' junto con 'update_profiles_updated_at'.
-- Tener múltiples triggers haciendo lo mismo es receta para el desastre.

-- 1. Borrar triggers redundantes de update date
DROP TRIGGER IF EXISTS handle_updated_at ON public.profiles;
-- Dejamos solo 'update_profiles_updated_at' que parece ser el estándar de Supabase

-- 2. Borrar duplicados de zzz (si existen con nombres distintos apuntando a la misma funcion)
-- Pero en tu output tenían el mismo nombre... eso es raro. Borremos y recolocamos uno solo.
DROP TRIGGER IF EXISTS zzz_force_points_limit ON public.profiles;

CREATE TRIGGER zzz_force_points_limit
    BEFORE INSERT OR UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.force_initial_points_limit();
