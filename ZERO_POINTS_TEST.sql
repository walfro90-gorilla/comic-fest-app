-- LA PRUEBA DEFINITIVA DE SANIDAD
-- Si insertamos 0 y sigue apareciendo 1500, hay magia negra (o un trigger fantasma en AWS/Supabase oculto).

-- 1. Redefinir handle_new_user para insertar CERO puntos.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_username text;
BEGIN
  v_username := COALESCE(NEW.raw_user_meta_data->>'full_name', 'User');

  -- INSERTAR CERO PUNTOS EXPLICITAMENTE
  INSERT INTO public.profiles (id, username, role, points)
  VALUES (NEW.id, v_username, 'attendee', 0); -- CERO. NADA. ZERO.

  -- NI SIQUIERA LOGUEAMOS PUNTOS
  RETURN NEW;
END;
$$;
