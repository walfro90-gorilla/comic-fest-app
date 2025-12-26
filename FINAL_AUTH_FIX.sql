-- SOLUCIÓN FINAL Y ROBUSTA
-- 1. Eliminamos definitivamente el trigger problemático "on_profile_created_gamification".
DROP TRIGGER IF EXISTS on_profile_created_gamification ON public.profiles;

-- 2. Redefinimos handle_new_user para que haga TODO en un solo paso seguro:
--    - Crear perfil con datos de metadata (Nombre/Avatar).
--    - Asignar los 500 puntos INICIALES directamente (sin UPDATE posterior).
--    - Crear el registro en el log de puntos.

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
  -- Extraer datos de forma segura
  v_username := COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1));
  v_avatar := NEW.raw_user_meta_data->>'avatar_url';

  -- 1. Insertar Perfil con 500 Puntos DE UNA VEZ
  INSERT INTO public.profiles (id, email, username, avatar_url, role, points)
  VALUES (
    NEW.id,
    NEW.email,
    v_username,
    v_avatar,
    'attendee',
    500 -- 🔥 Puntos iniciales directos (House Wins / Welcome Bonus)
  )
  ON CONFLICT (id) DO NOTHING;

  -- 2. Registrar el log de puntos (Auditoría)
  -- Lo hacemos aquí directo para evitar llamadas externas complejas.
  INSERT INTO public.points_log (user_id, points_change, reason, source_id, type)
  VALUES (NEW.id, 500, 'Bono de Bienvenida: Nuevo Recluta', NEW.id, 'earn');

  RETURN NEW;
END;
$$;
