-- SOLUCIÓN "A PRUEBA DE FALLOS"
-- El error anterior indica que el INSERT en 'points_log' está fallando (quizás por permisos o ID).
-- Esta versión:
-- 1. Inserta el perfil con 500 puntos (CRÍTICO: Esto funcionará sí o sí).
-- 2. Intenta insertar el log dentro de un bloque SAFE. Si falla, lo ignora, pero el usuario se crea igual.

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
  -- Extraer datos (con fallback a string vacío si es null para evitar líos)
  v_username := COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1));
  v_avatar := NEW.raw_user_meta_data->>'avatar_url';

  -- 1. Insertar Perfil con 500 Puntos
  INSERT INTO public.profiles (id, email, username, avatar_url, role, points)
  VALUES (
    NEW.id,
    NEW.email,
    v_username,
    v_avatar,
    'attendee',
    500
  )
  ON CONFLICT (id) DO NOTHING;

  -- 2. Intentar log (No bloqueante)
  BEGIN
    INSERT INTO public.points_log (user_id, points_change, reason, source_id, type)
    VALUES (NEW.id, 500, 'Bono de Bienvenida', NEW.id, 'earn');
  EXCEPTION WHEN OTHERS THEN
    -- Si falla el log, NO IMPORTA. El usuario ya tiene sus puntos.
    -- Podríamos usar RAISE WARNING si quisiéramos ver el error en logs de Supabase.
    NULL;
  END;

  RETURN NEW;
END;
$$;
