-- SOLUCIÓN "SET ABSOLUTO" PARA CANJE
-- En lugar de restar "points = points - X" (que si se ejecuta 3 veces resta 3X),
-- vamos a calcular el valor final y setearlo explicitamente.
-- "points = 400". Si se ejecuta 3 veces, sigue siendo 400.

CREATE OR REPLACE FUNCTION public.redeem_reward(
    p_user_id uuid,
    p_product_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_product_price_points int;
    v_product_stock int;
    v_product_name text;
    v_user_points int;
    v_new_points int; -- Variable para cálculo absoluto
    v_new_order_id uuid;
BEGIN
    -- 1. Obtener producto (Bloqueo Row Share)
    SELECT points_price, stock, name
    INTO v_product_price_points, v_product_stock, v_product_name
    FROM public.products
    WHERE id = p_product_id
    FOR UPDATE;

    -- Validaciones... (igual que antes)
    IF NOT FOUND THEN RETURN json_build_object('success', false, 'message', 'Producto no encontrado'); END IF;
    IF v_product_stock <= 0 THEN RETURN json_build_object('success', false, 'message', 'Agotado'); END IF;
    IF v_product_price_points IS NULL OR v_product_price_points <= 0 THEN RETURN json_build_object('success', false, 'message', 'No canjeable'); END IF;

    -- 2. Obtener puntos actuales (Bloqueo Row Share)
    SELECT points INTO v_user_points
    FROM public.profiles
    WHERE id = p_user_id
    FOR UPDATE;

    IF v_user_points < v_product_price_points THEN
        RETURN json_build_object('success', false, 'message', 'Puntos insuficientes');
    END IF;

    -- 3. CÁLCULO SEGURO (Anti-Rebote)
    v_new_points := v_user_points - v_product_price_points;

    -- 4. EJECUTAR UPDATE CON VALOR ABSOLUTO
    UPDATE public.profiles
    SET points = v_new_points, -- 🔥 CLAVE: Seteamos valor fijo (ej. 400), no relativo.
        updated_at = now()
    WHERE id = p_user_id;

    -- Update Stock
    UPDATE public.products
    SET stock = stock - 1,
        updated_at = now()
    WHERE id = p_product_id;

    -- Log
    INSERT INTO public.points_log (user_id, points_change, reason, source_id, type)
    VALUES (p_user_id, -v_product_price_points, 'Canje: ' || v_product_name, p_product_id, 'spend');

    -- Order
    INSERT INTO public.orders (user_id, total_amount, status, payment_method, items, order_type)
    VALUES (p_user_id, 0, 'paid', 'points', jsonb_build_array(jsonb_build_object('product_id', p_product_id, 'name', v_product_name, 'points_cost', v_product_price_points)), 'product') 
    RETURNING id INTO v_new_order_id;

    RETURN json_build_object('success', true, 'message', 'Canje exitoso', 'new_points', v_new_points);

EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'message', 'Error interno: ' || SQLERRM);
END;
$$;
