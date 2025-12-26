-- MODIFICAR ADD_POINTS PARA EVITAR SUMAR (SOLO LOG)
-- Si el problema es que la función add_points está sumando SOBRE el valor insertado,
-- esto lo confirmará.

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
    -- Loguear PERO NO SUMAR A PERFILES
    INSERT INTO public.points_log (user_id, points_change, reason, source_id, type)
    VALUES (target_user_id, points_amount, reason_text, source_ref, 'earn');
    
    -- (Comentamos el update para ver si así se queda en 500)
    -- UPDATE public.profiles
    -- SET points = points + points_amount,
    --     updated_at = now()
    -- WHERE id = target_user_id;
END;
$$;
