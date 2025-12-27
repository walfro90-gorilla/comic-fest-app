-- PROCESO DE CANJE DE RECOMPENSAS (REDEEM STORE)
-- Esta función maneja la transacción completa:
-- 1. Verifica saldo y stock.
-- 2. Resta stock.
-- 3. Resta puntos.
-- 4. Genera logs (gasto de puntos y orden).

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
    v_new_order_id uuid;
BEGIN
    -- 1. Obtener datos del producto (Bloqueo ROW SHARE para evitar race condition en stock)
    SELECT points_price, stock, name
    INTO v_product_price_points, v_product_stock, v_product_name
    FROM public.products
    WHERE id = p_product_id
    FOR UPDATE; -- Bloqueamos la fila del producto

    -- Validaciones Producto
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'message', 'Producto no encontrado');
    END IF;

    IF v_product_stock <= 0 THEN
        RETURN json_build_object('success', false, 'message', 'Agotado (Out of Stock)');
    END IF;

    IF v_product_price_points IS NULL OR v_product_price_points <= 0 THEN
        RETURN json_build_object('success', false, 'message', 'Este producto no está a la venta por puntos');
    END IF;

    -- 2. Obtener puntos del usuario (Bloqueo ROW SHARE)
    SELECT points INTO v_user_points
    FROM public.profiles
    WHERE id = p_user_id
    FOR UPDATE; -- Bloqueamos la fila del usuario

    -- Validaciones Usuario
    IF v_user_points < v_product_price_points THEN
        RETURN json_build_object('success', false, 'message', 'Puntos insuficientes');
    END IF;

    -- 3. EJECUTAR TRANSACCIÓN

    -- A) Restar Puntos al Usuario
    UPDATE public.profiles
    SET points = points - v_product_price_points,
        updated_at = now()
    WHERE id = p_user_id;

    -- B) Restar Stock al Producto
    UPDATE public.products
    SET stock = stock - 1,
        updated_at = now()
    WHERE id = p_product_id;

    -- C) Registrar en Log de Puntos ('spend')
    INSERT INTO public.points_log (user_id, points_change, reason, source_id, type)
    VALUES (p_user_id, -v_product_price_points, 'Canje: ' || v_product_name, p_product_id, 'spend');

    -- D) Crear Orden "Pagada" para seguimiento (Orden de tipo 'product' / 'redemption')
    INSERT INTO public.orders (user_id, total_amount, status, payment_method, items, order_type)
    VALUES (
        p_user_id, 
        0, -- Monto monetario es 0
        'paid', -- Ya está "pagada" con puntos
        'points', 
        jsonb_build_array(
            jsonb_build_object(
                'product_id', p_product_id,
                'name', v_product_name,
                'quantity', 1,
                'price', 0,
                'points_cost', v_product_price_points
            )
        ),
        'product'
    ) RETURNING id INTO v_new_order_id;

    RETURN json_build_object(
        'success', true, 
        'message', '¡Canje exitoso! Disfruta tu recompensa.',
        'new_points', v_user_points - v_product_price_points,
        'order_id', v_new_order_id
    );

EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'message', 'Error interno: ' || SQLERRM);
END;
$$;
