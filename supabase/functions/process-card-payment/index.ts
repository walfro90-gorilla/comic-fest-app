// ============================================================================
// SUPABASE EDGE FUNCTION: process-card-payment
// ============================================================================
// Procesa pagos con tarjeta de crédito/débito usando Mercado Pago
// Evita problemas de CORS al hacer las llamadas desde el servidor
// ============================================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

const MERCADO_PAGO_ACCESS_TOKEN = 'TEST-609116576534644-111319-2a64ba9924fab4e9b158322d60311a64-479630144';
const MERCADO_PAGO_CARD_TOKEN_URL = 'https://api.mercadopago.com/v1/card_tokens';
const MERCADO_PAGO_PAYMENTS_URL = 'https://api.mercadopago.com/v1/payments';

interface CardData {
  cardNumber: string;
  cardholderName: string;
  expirationMonth: string;
  expirationYear: string;
  securityCode: string;
  identificationType: string;
  identificationNumber: string;
}

interface PaymentRequest {
  orderId: string;
  amount: number;
  payerEmail: string;
  cardData: CardData;
}

Deno.serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { status: 200, headers: corsHeaders });
  }

  try {
    console.log('🔐 Processing card payment...');

    // Obtener authorization header
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Missing authorization header');
    }

    // Parse request body
    const body: PaymentRequest = await req.json();
    console.log('📦 Raw body received:', JSON.stringify(body));
    
    const { orderId, amount, payerEmail, cardData } = body;

    console.log(`💳 Order: ${orderId}, Amount: $${amount}`);
    console.log(`👤 Payer: ${payerEmail}`);
    console.log(`🃏 CardData present: ${cardData ? 'YES' : 'NO'}`);
    
    if (cardData) {
      console.log(`🃏 CardData keys: ${Object.keys(cardData).join(', ')}`);
      console.log(`🃏 Card Number: ${cardData.cardNumber ? cardData.cardNumber.substring(0, 6) + '...' : 'MISSING'}`);
      console.log(`🃏 Cardholder Name: ${cardData.cardholderName || 'MISSING'}`);
      console.log(`🃏 Expiration: ${cardData.expirationMonth}/${cardData.expirationYear}`);
      console.log(`🃏 Security Code: ${cardData.securityCode ? '***' : 'MISSING'}`);
      console.log(`🃏 ID Type: ${cardData.identificationType || 'MISSING'}`);
      console.log(`🃏 ID Number: ${cardData.identificationNumber || 'MISSING'}`);
    }

    // Validar datos requeridos
    if (!orderId || !amount || !payerEmail || !cardData) {
      const missing = [];
      if (!orderId) missing.push('orderId');
      if (!amount) missing.push('amount');
      if (!payerEmail) missing.push('payerEmail');
      if (!cardData) missing.push('cardData');
      
      console.error(`❌ Missing fields: ${missing.join(', ')}`);
      
      return new Response(
        JSON.stringify({
          error: 'Missing required fields',
          missing: missing,
          received: Object.keys(body),
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // =================================================================
    // STEP 1: Tokenizar la tarjeta en Mercado Pago
    // =================================================================
    console.log('🔐 Step 1: Tokenizing card...');

    const tokenPayload = {
      card_number: cardData.cardNumber.replace(/\s/g, ''),
      cardholder: {
        name: cardData.cardholderName,
        identification: {
          type: cardData.identificationType,
          number: cardData.identificationNumber,
        },
      },
      expiration_month: parseInt(cardData.expirationMonth),
      expiration_year: parseInt(cardData.expirationYear),
      security_code: cardData.securityCode,
    };

    console.log('📤 Calling Mercado Pago card_tokens API...');

    const tokenResponse = await fetch(MERCADO_PAGO_CARD_TOKEN_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${MERCADO_PAGO_ACCESS_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(tokenPayload),
    });

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text();
      console.error('❌ Card token error:', errorText);
      throw new Error(`Failed to tokenize card: ${errorText}`);
    }

    const tokenData = await tokenResponse.json();
    const cardToken = tokenData.id;
    const paymentMethodId = tokenData.payment_method_id;

    console.log(`✅ Card token created: ${cardToken}`);
    console.log(`✅ Payment method detected: ${paymentMethodId}`);

    // =================================================================
    // STEP 2: Procesar el pago con el token
    // =================================================================
    console.log('💳 Step 2: Processing payment...');

    const paymentPayload = {
      token: cardToken,
      transaction_amount: amount,
      installments: 1,
      payment_method_id: paymentMethodId,
      payer: {
        email: payerEmail,
        identification: {
          type: cardData.identificationType,
          number: cardData.identificationNumber,
        },
      },
      external_reference: orderId,
      description: 'Boletos Comic Fest',
      statement_descriptor: 'COMIC FEST',
    };

    console.log('📤 Calling Mercado Pago payments API...');

    const paymentResponse = await fetch(MERCADO_PAGO_PAYMENTS_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${MERCADO_PAGO_ACCESS_TOKEN}`,
        'Content-Type': 'application/json',
        'X-Idempotency-Key': orderId, // Prevenir duplicados
      },
      body: JSON.stringify(paymentPayload),
    });

    const paymentData = await paymentResponse.json();

    if (!paymentResponse.ok) {
      console.error('❌ Payment error:', paymentData);
      return new Response(
        JSON.stringify({
          success: false,
          error: paymentData.message || 'Payment failed',
          details: paymentData,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const paymentId = paymentData.id;
    const status = paymentData.status;
    const statusDetail = paymentData.status_detail;

    console.log(`✅ Payment created: ${paymentId}`);
    console.log(`✅ Status: ${status} (${statusDetail})`);

    // =================================================================
    // STEP 3: El cliente creará la orden y actualizará el pago
    // =================================================================
    // Ya no guardamos nada en Supabase aquí. El cliente lo hará después
    // de recibir la respuesta exitosa de Mercado Pago.
    console.log('✅ Payment processed. Client will create order and save to database.');

    // =================================================================
    // RESPUESTA FINAL
    // =================================================================
    return new Response(
      JSON.stringify({
        success: true,
        payment_id: paymentId.toString(),
        status: status,
        status_detail: statusDetail,
        raw: paymentData,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error: any) {
    console.error('❌ Error processing payment:', error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Internal server error',
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
