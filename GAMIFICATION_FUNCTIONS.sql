-- ==============================================================================
-- GAMIFICATION LOGIC - STORED PROCEDURES & TRIGGERS
-- ==============================================================================
-- Ejecuta este script en el SQL Editor de Supabase para activar la lógica.

-- 1. Helper: Función para agregar puntos de forma segura
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
    -- Insertar en el log (historial)
    INSERT INTO public.points_log (user_id, points_change, reason, source_id, type)
    VALUES (target_user_id, points_amount, reason_text, source_ref, 'earn');

    -- Actualizar el saldo actual del usuario
    UPDATE public.profiles
    SET points = points + points_amount,
        updated_at = now()
    WHERE id = target_user_id;
END;
$$;


-- 2. Trigger: Al registrarse (Nuevo Usuario)
-- Asume que el referral_code viene en el metadata del usuario o se maneja aparte.
-- Esta función se dispara cuando se crea un profile.
CREATE OR REPLACE FUNCTION public.handle_new_user_gamification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- A) Dar bono de bienvenida (500 pts)
    PERFORM public.add_points(NEW.id, 500, 'Bono de Bienvenida: Nuevo Recluta', NEW.id);

    -- B) Intentar procesar referido si existe un código (esto depende de cómo guardes el código al registrarse)
    -- Si guardaste el 'referral_code' en una columna temporal o metadata, aquí lo procesarías.
    -- Por simplicidad, asumiremos que si existe la tabla referrals, ya se insertó ahí la relación 'pending'.
    
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_profile_created_gamification ON public.profiles;
CREATE TRIGGER on_profile_created_gamification
    AFTER INSERT ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user_gamification();


-- 3. Trigger: Al Pagar una Orden (Compras)
CREATE OR REPLACE FUNCTION public.handle_order_payment_gamification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    points_to_earn integer;
    referrer_uid uuid;
BEGIN
    -- Solo procesar si el status cambia a 'paid' y antes no lo estaba
    IF OLD.status <> 'paid' AND NEW.status = 'paid' THEN
        
        -- A) Calcular puntos base por compra
        -- Regla: 1 punto por cada peso gastado (simplificado de la tabla: 10pts/$10 = 1pt/$1)
        -- Puedes ajustar el multiplicador aquí.
        -- Tickets = 1.0x, Productos = 0.5x? Usaremos 1.0x genérico para empezar.
        points_to_earn := FLOOR(NEW.total_amount * 1); 

        IF points_to_earn > 0 THEN
            PERFORM public.add_points(NEW.user_id, points_to_earn, 'Compra completada: Orden #' || COALESCE(NEW.order_number, 'N/A'), NEW.id);
        END IF;

        -- B) Procesar SISTEMA DE REFERIDOS
        -- Verificar si este usuario fue referido por alguien y si el referral está 'pending'
        SELECT referrer_id INTO referrer_uid
        FROM public.referrals
        WHERE referred_id = NEW.user_id AND status = 'pending';

        IF FOUND THEN
            -- 1. Pagar al Padrino (Referrer) - 1000 pts
            PERFORM public.add_points(referrer_uid, 1000, 'Referido completó su primera misión (compra)', NEW.user_id);
            
            -- 2. Pagar al Ahijado (Referred user) - 500 pts extra de bono 'First Blood'
            PERFORM public.add_points(NEW.user_id, 500, 'Bono: Primera compra con Link de Oro', referrer_uid);

            -- 3. Marcar referral como completado
            UPDATE public.referrals SET status = 'completed' WHERE referred_id = NEW.user_id;
        END IF;

    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_order_paid_gamification ON public.orders;
CREATE TRIGGER on_order_paid_gamification
    AFTER UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_order_payment_gamification();


-- 4. Trigger: Al Votar (Engagement Diario)
-- Aplica para ambas tablas: votes (Concursos) y panel_votes (Paneles)
CREATE OR REPLACE FUNCTION public.handle_vote_gamification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    daily_votes_count integer;
    MAX_DAILY_VOTES constant integer := 5;
    POINTS_PER_VOTE constant integer := 50;
BEGIN
    -- Contar cuántos votos ha hecho hoy el usuario (sumando ambas tablas aprox o solo esta)
    -- Para hacerlo simple y rápido, contaremos solo entradas en points_log de tipo 'vote_reward' hoy.
    SELECT COUNT(*) INTO daily_votes_count
    FROM public.points_log
    WHERE user_id = NEW.user_id 
      AND reason LIKE 'Voto emitido%'
      AND created_at > current_date;

    IF daily_votes_count < MAX_DAILY_VOTES THEN
        PERFORM public.add_points(NEW.user_id, POINTS_PER_VOTE, 'Voto emitido', NEW.id);
    END IF;

    RETURN NEW;
END;
$$;

-- Trigger para Votos de Concursos
DROP TRIGGER IF EXISTS on_vote_cast_gamification ON public.votes;
CREATE TRIGGER on_vote_cast_gamification
    AFTER INSERT ON public.votes
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_vote_gamification();

-- Trigger para Votos de Paneles (si aplica)
DROP TRIGGER IF EXISTS on_panel_vote_gamification ON public.panel_votes;
CREATE TRIGGER on_panel_vote_gamification
    AFTER INSERT ON public.panel_votes
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_vote_gamification();


-- 5. Trigger: Passport Stamp (QR Check-in)
CREATE OR REPLACE FUNCTION public.handle_passport_scan()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Dar 150 puntos por encontrar un stand
    PERFORM public.add_points(NEW.user_id, 150, 'Passport Stamp: Stand encontrado', NEW.exhibitor_id);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_passport_stamp_gamification ON public.passport_stamps;
CREATE TRIGGER on_passport_stamp_gamification
    AFTER INSERT ON public.passport_stamps
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_passport_scan();
