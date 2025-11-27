-- ============================================================================
-- MERCADO PAGO WEBHOOK INTEGRATION (FIXED)
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
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- ============================================================================
-- FUNCIÓN: Procesar Webhook de Mercado Pago
-- ============================================================================
-- Esta función debe ser llamada desde una Supabase Edge Function
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
    ticket_record RECORD;
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

    -- Buscar el pago en la tabla payments
    SELECT * INTO payment_record
    FROM payments
    WHERE mp_payment_id = payment_id::TEXT
    LIMIT 1;

    -- Si no encontramos en payments, buscar en tickets por payment_id_mp
    IF payment_record IS NULL THEN
        SELECT * INTO ticket_record
        FROM tickets
        WHERE payment_id_mp = payment_id::TEXT
        LIMIT 1;
        
        IF ticket_record IS NULL THEN
            RETURN jsonb_build_object(
                'success', FALSE,
                'message', 'Payment not found in database'
            );
        END IF;
    END IF;

    -- Nota: El estado real debe ser verificado por la Edge Function
    -- llamando a la API de Mercado Pago antes de actualizar el estado
    
    -- Marcar webhook como procesado
    UPDATE webhook_logs
    SET processed = TRUE
    WHERE payload->'data'->>'id' = payment_id;

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
    WHERE payload->'data'->>'id' = payment_id;

    RETURN jsonb_build_object(
        'success', FALSE,
        'message', SQLERRM
    );
END;
$$;

-- ============================================================================
-- FUNCIÓN: Verificar estado de pago manualmente (para tickets)
-- ============================================================================

CREATE OR REPLACE FUNCTION check_payment_status(
    ticket_uuid UUID
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    ticket_record RECORD;
BEGIN
    -- Verificar que el ticket existe y pertenece al usuario
    SELECT * INTO ticket_record
    FROM tickets
    WHERE id = ticket_uuid
    AND user_id = auth.uid();

    IF ticket_record IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 'Ticket not found or unauthorized'
        );
    END IF;

    -- Retornar información del ticket
    RETURN jsonb_build_object(
        'success', TRUE,
        'ticket', row_to_json(ticket_record)
    );
END;
$$;

-- ============================================================================
-- FUNCIÓN: Aprobar pago de ticket desde webhook
-- ============================================================================
-- Esta función debe ser llamada por la Edge Function después de verificar
-- el estado del pago en la API de Mercado Pago
-- ============================================================================

CREATE OR REPLACE FUNCTION approve_ticket_payment(
    mp_payment_id TEXT,
    mp_status TEXT
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    ticket_record RECORD;
BEGIN
    -- Buscar el ticket
    SELECT * INTO ticket_record
    FROM tickets
    WHERE payment_id_mp = mp_payment_id
    LIMIT 1;

    IF ticket_record IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 'Ticket not found for payment ID: ' || mp_payment_id
        );
    END IF;

    -- Actualizar estado del ticket según el estado de MP
    IF mp_status = 'approved' THEN
        UPDATE tickets
        SET 
            payment_status = 'approved',
            updated_at = NOW()
        WHERE payment_id_mp = mp_payment_id;
        
        RETURN jsonb_build_object(
            'success', TRUE,
            'message', 'Ticket payment approved',
            'ticket_id', ticket_record.id
        );
    ELSIF mp_status = 'rejected' OR mp_status = 'cancelled' THEN
        UPDATE tickets
        SET 
            payment_status = 'failed',
            updated_at = NOW()
        WHERE payment_id_mp = mp_payment_id;
        
        RETURN jsonb_build_object(
            'success', TRUE,
            'message', 'Ticket payment failed',
            'ticket_id', ticket_record.id
        );
    ELSE
        -- Estado pendiente u otro
        RETURN jsonb_build_object(
            'success', TRUE,
            'message', 'Payment status: ' || mp_status,
            'ticket_id', ticket_record.id
        );
    END IF;

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', FALSE,
        'message', SQLERRM
    );
END;
$$;

-- ============================================================================
-- FUNCIÓN: Aprobar pago de orden desde webhook
-- ============================================================================

CREATE OR REPLACE FUNCTION approve_order_payment(
    mp_payment_id TEXT,
    mp_status TEXT
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    order_record RECORD;
    payment_record RECORD;
BEGIN
    -- Buscar el pago
    SELECT * INTO payment_record
    FROM payments
    WHERE mp_payment_id = mp_payment_id
    LIMIT 1;

    IF payment_record IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 'Payment not found for payment ID: ' || mp_payment_id
        );
    END IF;

    -- Actualizar estado del pago
    IF mp_status = 'approved' THEN
        UPDATE payments
        SET 
            status = 'approved',
            updated_at = NOW()
        WHERE mp_payment_id = mp_payment_id;
        
        -- Actualizar orden
        UPDATE orders
        SET 
            status = 'paid',
            updated_at = NOW()
        WHERE id = payment_record.order_id;
        
        RETURN jsonb_build_object(
            'success', TRUE,
            'message', 'Order payment approved',
            'order_id', payment_record.order_id
        );
    ELSIF mp_status = 'rejected' OR mp_status = 'cancelled' THEN
        UPDATE payments
        SET 
            status = 'failed',
            updated_at = NOW()
        WHERE mp_payment_id = mp_payment_id;
        
        UPDATE orders
        SET 
            status = 'cancelled',
            updated_at = NOW()
        WHERE id = payment_record.order_id;
        
        RETURN jsonb_build_object(
            'success', TRUE,
            'message', 'Order payment failed',
            'order_id', payment_record.order_id
        );
    ELSE
        RETURN jsonb_build_object(
            'success', TRUE,
            'message', 'Payment status: ' || mp_status,
            'order_id', payment_record.order_id
        );
    END IF;

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', FALSE,
        'message', SQLERRM
    );
END;
$$;

-- ============================================================================
-- COMENTARIOS FINALES
-- ============================================================================
-- Pasos para integrar Mercado Pago:
--
-- 1. ✅ Ejecuta este SQL en Supabase SQL Editor
--
-- 2. 🔧 Crea Supabase Edge Functions:
--    
--    a) create-payment-preference:
--       - Recibe: { ticketTypeId, userId, amount }
--       - Llama a API de MP para crear preferencia
--       - Guarda payment_id_mp en tabla tickets
--       - Retorna: { init_point, preference_id }
--
--    b) mercadopago-webhook:
--       - Recibe: POST desde Mercado Pago
--       - Valida firma del webhook (seguridad)
--       - Llama a API de MP para obtener estado real del pago
--       - Llama a approve_ticket_payment() o approve_order_payment()
--       - Retorna: 200 OK
--
-- 3. 📱 En Flutter:
--    - Usuario presiona "Pagar"
--    - Llama a create-payment-preference
--    - Abre init_point en navegador (url_launcher)
--    - Usuario completa pago en MP
--    - MP envía webhook a tu Edge Function
--    - Usuario regresa a app
--    - App llama a check_payment_status() para actualizar UI
--
-- 4. 🔐 En Mercado Pago Dashboard:
--    - Ve a: Tu aplicación > Webhooks
--    - Agrega URL: https://tu-proyecto.supabase.co/functions/v1/mercadopago-webhook
--    - Selecciona eventos: payment
--    - Guarda
--
-- 5. 🧪 Testing:
--    - Usa credenciales de Sandbox primero
--    - Tarjetas de prueba: https://www.mercadopago.com.mx/developers/es/docs/checkout-pro/additional-content/test-cards
--    - Verifica logs en webhook_logs
-- ============================================================================
