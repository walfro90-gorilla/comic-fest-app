-- ============================================================================
-- MERCADO PAGO WEBHOOK INTEGRATION
-- ============================================================================
-- Este archivo contiene las funciones necesarias para recibir y procesar
-- webhooks de Mercado Pago cuando los pagos cambian de estado.
--
-- IMPORTANTE: Debes configurar esta URL en tu panel de Mercado Pago:
-- https://your-supabase-project.supabase.co/functions/v1/mercadopago-webhook
-- ============================================================================

-- Tabla para logs de webhooks (útil para debugging)
CREATE TABLE IF NOT EXISTS webhook_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider TEXT NOT NULL DEFAULT 'mercadopago',
    event_type TEXT,
    payload JSONB NOT NULL,
    processed BOOLEAN DEFAULT FALSE,
    error TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índice para buscar webhooks por tipo
CREATE INDEX IF NOT EXISTS idx_webhook_logs_event_type ON webhook_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_webhook_logs_created_at ON webhook_logs(created_at);

-- Habilitar RLS en webhook_logs
ALTER TABLE webhook_logs ENABLE ROW LEVEL SECURITY;

-- Solo admins pueden ver logs de webhooks
CREATE POLICY "Admins can view webhook logs" ON webhook_logs
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- ============================================================================
-- FUNCIÓN: Procesar Webhook de Mercado Pago
-- ============================================================================
-- Esta función debe ser llamada desde una Supabase Edge Function o API endpoint
-- que reciba los webhooks de Mercado Pago
-- ============================================================================

CREATE OR REPLACE FUNCTION process_mercadopago_webhook(
    webhook_payload JSONB
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    payment_id TEXT;
    payment_status TEXT;
    external_ref TEXT;
    order_uuid UUID;
    payment_record RECORD;
BEGIN
    -- Log del webhook recibido
    INSERT INTO webhook_logs (event_type, payload, processed)
    VALUES (
        webhook_payload->>'type',
        webhook_payload,
        FALSE
    );

    -- Extraer información del webhook
    payment_id := webhook_payload->'data'->>'id';
    payment_status := webhook_payload->>'action'; -- "payment.created", "payment.updated"
    
    -- Si no hay payment_id, salir
    IF payment_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 'No payment ID found in webhook'
        );
    END IF;

    -- Buscar el pago en nuestra base de datos
    SELECT * INTO payment_record
    FROM payments
    WHERE mp_payment_id = payment_id::TEXT
    LIMIT 1;

    -- Si no encontramos el pago, intentar buscarlo por preference_id
    IF payment_record IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 'Payment not found in database'
        );
    END IF;

    -- Actualizar estado del pago según lo que nos diga Mercado Pago
    -- Nota: Debes llamar a la API de Mercado Pago desde tu Edge Function
    -- para obtener el estado real del pago antes de actualizar
    
    -- Marcar webhook como procesado
    UPDATE webhook_logs
    SET processed = TRUE
    WHERE payload->>'id' = payment_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'message', 'Webhook processed successfully',
        'payment_id', payment_id
    );

EXCEPTION WHEN OTHERS THEN
    -- Log del error
    UPDATE webhook_logs
    SET 
        processed = TRUE,
        error = SQLERRM
    WHERE payload->>'id' = payment_id;

    RETURN jsonb_build_object(
        'success', FALSE,
        'message', SQLERRM
    );
END;
$$;

-- ============================================================================
-- FUNCIÓN: Verificar estado de pago manualmente
-- ============================================================================
-- Esta función permite al frontend verificar el estado de un pago
-- después de que el usuario regrese de Mercado Pago
-- ============================================================================

CREATE OR REPLACE FUNCTION check_payment_status(
    order_uuid UUID
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    payment_record RECORD;
    order_record RECORD;
BEGIN
    -- Verificar que la orden existe y pertenece al usuario
    SELECT * INTO order_record
    FROM orders
    WHERE id = order_uuid
    AND user_id = auth.uid();

    IF order_record IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 'Order not found or unauthorized'
        );
    END IF;

    -- Obtener el pago asociado
    SELECT * INTO payment_record
    FROM payments
    WHERE order_id = order_uuid
    ORDER BY created_at DESC
    LIMIT 1;

    IF payment_record IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 'Payment not found'
        );
    END IF;

    -- Retornar información del pago
    RETURN jsonb_build_object(
        'success', TRUE,
        'payment', row_to_json(payment_record),
        'order', row_to_json(order_record)
    );
END;
$$;

-- ============================================================================
-- COMENTARIOS FINALES
-- ============================================================================
-- Para integrar completamente Mercado Pago, necesitas:
--
-- 1. Crear una Supabase Edge Function que:
--    - Reciba webhooks POST de Mercado Pago
--    - Valide la firma del webhook (importante para seguridad)
--    - Llame a process_mercadopago_webhook()
--
-- 2. Configurar en Mercado Pago:
--    - URL del webhook
--    - Eventos a notificar: payment.created, payment.updated
--
-- 3. En el frontend:
--    - Después de crear la orden, llamar al endpoint que crea la preferencia
--    - Redirigir al usuario a init_point
--    - Cuando regrese, llamar a check_payment_status() para actualizar UI
-- ============================================================================
