-- ACTIVAR 500 PUNTOS DE BIENVENIDA (VERSIÓN DEFINITIVA)
-- Habiendo confirmado que tenemos control total, establecemos el bono oficial.

-- 1. Redefinimos handle_new_user para insertar 500 puntos.
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
  -- Preparar datos (sin email, que no existe en profile)
  v_username := COALESCE(NEW.raw_user_meta_data->>'full_name', 'Usuario Nuevo');
  v_avatar := NEW.raw_user_meta_data->>'avatar_url';

  -- A) INSERTAR USUARIO CON 500 PUNTOS
  INSERT INTO public.profiles (id, username, avatar_url, role, points)
  VALUES (
    NEW.id,
    v_username,
    v_avatar,
    'attendee',
    500 -- 🔥 BONO CONFIRMADO
  )
  ON CONFLICT (id) DO NOTHING;

  -- B) CREAR LOG (Safe Mode)
  BEGIN
    INSERT INTO public.points_log (user_id, points_change, reason, source_id, type)
    VALUES (NEW.id, 500, 'Bono de Bienvenida: Nuevo Recluta', NEW.id, 'earn');
  EXCEPTION WHEN OTHERS THEN
    -- Log fallido no detiene el registro
    NULL;
  END;

  RETURN NEW;
END;
$$;


-- 2. Restaurar la función 'add_points' original 
-- (La habíamos desactivado antes para pruebas, hay que dejarla funcional para futuras compras/votos)
CREATE OR REPLACE FUNCTION public.add_points(
    target_user_id uuid,
    points_amount integer,
    reason_text text,
    source_ref uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Insertar en log
    INSERT INTO public.points_log (user_id, points_change, reason, source_id, type)
    VALUES (target_user_id, points_amount, reason_text, source_ref, 'earn');

    -- Actualizar saldo (Ahora sí, REACTIVADO)
    UPDATE public.profiles
    SET points = points + points_amount,
        updated_at = now()
    WHERE id = target_user_id;
END;
$$;


-- 3. Asegurar que NO existan triggers de gamificación antiguos (doble seguridad)
DROP TRIGGER IF EXISTS on_profile_created_gamification ON public.profiles;

