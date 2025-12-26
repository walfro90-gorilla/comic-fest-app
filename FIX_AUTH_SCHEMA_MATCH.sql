-- SOLUCIÓN DEFINITIVA (ERROR DE COLUMNA CORREGIDO)
-- El error era que intentábamos insertar 'email' en la tabla 'profiles', pero esa columna NO existe en tu esquema.
-- Solo existe en auth.users.

-- 1. Asegurar limpieza de triggers viejos
DROP TRIGGER IF EXISTS on_profile_created_gamification ON public.profiles;

-- 2. Función corregida (SIN COLUMNA EMAIL)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_username text;
  v_avatar text;
BEGIN
  -- Preparar datos
  v_username := COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', 'Usuario Nuevo');
  v_avatar := NEW.raw_user_meta_data->>'avatar_url';

  -- 1. Insertar Perfil (SIN EMAIL, solo datos válidos)
  INSERT INTO public.profiles (id, username, avatar_url, role, points)
  VALUES (
    NEW.id,
    v_username,
    v_avatar,
    'attendee',
    500 -- ✅ 500 Puntos Iniciales
  )
  ON CONFLICT (id) DO NOTHING;

  -- 2. Registrar Log (Safe Mode)
  BEGIN
    INSERT INTO public.points_log (user_id, points_change, reason, source_id, type)
    VALUES (NEW.id, 500, 'Bono de Bienvenida', NEW.id, 'earn');
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  RETURN NEW;
END;
$$;
