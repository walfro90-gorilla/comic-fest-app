-- FIX CRÍTICO DE AUTH
-- Simplificamos la función para evitar cualquier posible error de sintaxis o JSON.
-- Si esto falla, el problema es de permisos.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, points)
  VALUES (
    NEW.id,
    NEW.email,
    'attendee',
    0 -- Forzamos 0 puntos
  )
  ON CONFLICT (id) DO NOTHING;
  
  -- Intentamos actualizar nombre y avatar si existen, en un paso separado para que no cause fallo bloqueante
  -- Si falla la extracción de JSON, la inserción principal ya ocurrió.
  BEGIN
      UPDATE public.profiles
      SET 
          username = COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
          avatar_url = NEW.raw_user_meta_data->>'avatar_url'
      WHERE id = NEW.id;
  EXCEPTION WHEN OTHERS THEN
      -- Ignoramos errores de metadata, lo importante es que el usuario se cree.
      NULL;
  END;

  RETURN NEW;
END;
$$;
