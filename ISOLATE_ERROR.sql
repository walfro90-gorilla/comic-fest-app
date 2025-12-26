-- DIAGNÓSTICO: AISLAR EL ERROR
-- 1. Eliminamos el trigger de gamificación temporalmente. 
--    (Si esto arregla el login, el error está en la función 'add_points' o 'handle_new_user_gamification')
DROP TRIGGER IF EXISTS on_profile_created_gamification ON public.profiles;

-- 2. Simplificamos 'handle_new_user' al MÁXIMO ABSOLUTO.
--    Ni email, ni metadata, ni update. Solo ID y Puntos.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, points, role)
  VALUES (NEW.id, 0, 'attendee')
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$;
