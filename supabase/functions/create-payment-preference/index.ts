// ============================================================================
// SUPABASE EDGE FUNCTION: create-payment-preference
// ============================================================================
// Esta función crea una preferencia de pago en Mercado Pago y registra
// el ticket en la base de datos con estado "pending"
// ============================================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parsear body de la request PRIMERO
    const { orderId, items, totalAmount, authToken } = await req.json()

    if (!orderId || !items || !totalAmount) {
      throw new Error('orderId, items y totalAmount son requeridos')
    }

    console.log('📦 Order ID:', orderId)
    console.log('🔐 Auth token received:', authToken ? 'YES' : 'NO')

    // Crear cliente de Supabase con SERVICE ROLE para queries admin
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Crear cliente con el JWT del usuario para validar autenticación
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: `Bearer ${authToken}` },
        },
      }
    )

    // Obtener usuario autenticado usando el token del body
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    console.log('👤 User from token:', user ? user.email : 'null')
    console.log('⚠️ User error:', userError ? userError.message : 'none')

    if (userError || !user) {
      throw new Error(`Auth failed! Error: ${userError?.message || 'No user'}`)
    }

    console.log('✅ User authenticated:', user.email)

    // Verificar que la orden existe y pertenece al usuario usando el cliente admin
    const { data: order, error: orderError } = await supabaseAdmin
      .from('orders')
      .select()
      .eq('id', orderId)
      .eq('user_id', user.id)
      .single()

    if (orderError || !order) {
      throw new Error('Orden no encontrada o no pertenece al usuario')
    }

    console.log('✅ Order found:', order.order_number)

    // Obtener el perfil del usuario para el email (tabla profiles)
    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('id')
      .eq('id', user.id)
      .single()

    if (!profile) {
      throw new Error('Perfil de usuario no encontrado')
    }

    // Usar el email del order (buyer_email) o el del auth
    const buyerEmail = order.buyer_email || user.email || 'user@comicfest.com'
    console.log('📧 Buyer email:', buyerEmail)

    // Obtener credenciales de Mercado Pago
    const MP_ACCESS_TOKEN = Deno.env.get('MERCADOPAGO_ACCESS_TOKEN')
    if (!MP_ACCESS_TOKEN) {
      throw new Error('MERCADOPAGO_ACCESS_TOKEN no configurado')
    }

    // Crear preferencia de pago en Mercado Pago
    const preference = {
      items: items.map((item: any) => ({
        title: item.title,
        description: item.description || item.title,
        quantity: item.quantity,
        unit_price: parseFloat(item.unit_price),
        currency_id: 'MXN',
      })),
      payer: {
        email: buyerEmail,
      },
      back_urls: {
        success: `${Deno.env.get('APP_URL') || 'https://app.comicfest.com'}/tickets?status=approved`,
        failure: `${Deno.env.get('APP_URL') || 'https://app.comicfest.com'}/tickets?status=failed`,
        pending: `${Deno.env.get('APP_URL') || 'https://app.comicfest.com'}/tickets?status=pending`,
      },
      auto_return: 'approved',
      external_reference: orderId,
      notification_url: `${Deno.env.get('SUPABASE_URL')}/functions/v1/mercadopago-webhook`,
      metadata: {
        order_id: orderId,
        user_id: user.id,
      },
    }

    // Llamar a la API de Mercado Pago
    console.log('🔄 Calling Mercado Pago API...')
    const mpResponse = await fetch('https://api.mercadopago.com/checkout/preferences', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${MP_ACCESS_TOKEN}`,
      },
      body: JSON.stringify(preference),
    })

    console.log('📡 MP Response status:', mpResponse.status)

    if (!mpResponse.ok) {
      const errorText = await mpResponse.text()
      console.error('❌ MP Error:', errorText)
      throw new Error(`Error de Mercado Pago (${mpResponse.status}): ${errorText}`)
    }

    const mpData = await mpResponse.json()

    console.log('✅ Preferencia creada:', mpData.id)
    console.log('🔗 Init point:', mpData.init_point)

    // Retornar init_point para redirigir al usuario
    return new Response(
      JSON.stringify({
        success: true,
        initPoint: mpData.init_point,
        sandboxInitPoint: mpData.sandbox_init_point,
        preferenceId: mpData.id,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('Error en create-payment-preference:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})
