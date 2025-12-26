-- SCRIPT DE LIMPIEZA TOTAL DE TRIGGERS (PROFILES)
-- Este script elimina TODOS los triggers de la tabla 'profiles' para asegurar que no haya lógica vieja interfiriendo.
-- Luego, reactiva SOLO el trigger de gamificación oficial.

-- 1. Eliminar triggers sospechosos (lista de nombres comunes)
DROP TRIGGER IF EXISTS on_auth_user_created ON public.profiles;
DROP TRIGGER IF EXISTS handle_new_user ON public.profiles;
DROP TRIGGER IF EXISTS on_profile_created ON public.profiles;
DROP TRIGGER IF EXISTS tr_gamification_welcome ON public.profiles;

-- 2. Eliminar el trigger de gamificación actual (para recrearlo limpio)
DROP TRIGGER IF EXISTS on_profile_created_gamification ON public.profiles;

-- 3. REACTIVAR SOLO EL TRIGGER OFICIAL
CREATE TRIGGER on_profile_created_gamification
    AFTER INSERT ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user_gamification();

-- 4. Verificación final
SELECT trigger_name 
FROM information_schema.triggers 
WHERE event_object_table = 'profiles';
