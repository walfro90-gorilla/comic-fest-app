// ============================================================================
// SUPABASE EDGE FUNCTION: mercadopago-webhook
// ============================================================================
// Esta función recibe webhooks de Mercado Pago cuando cambia el estado
// de un pago y actualiza el estado del ticket en la base de datos
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
    // Inicializar cliente de Supabase con service_role (sin auth)
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Parsear webhook de Mercado Pago
    const webhookData = await req.json()
    
    console.log('Webhook recibido de Mercado Pago:', webhookData)

    // Log del webhook
    await supabaseClient
      .from('webhook_logs')
      .insert({
        provider: 'mercadopago',
        event_type: webhookData.type || webhookData.action,
        payload: webhookData,
        processed: false,
      })

    // Solo procesar eventos de tipo "payment"
    if (webhookData.type !== 'payment') {
      console.log('Evento ignorado (no es payment):', webhookData.type)
      return new Response(
        JSON.stringify({ success: true, message: 'Event ignored' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    // Obtener ID del pago
    const paymentId = webhookData.data?.id
    if (!paymentId) {
      throw new Error('No se encontró payment ID en el webhook')
    }

    // Obtener credenciales de Mercado Pago
    const MP_ACCESS_TOKEN = Deno.env.get('MERCADOPAGO_ACCESS_TOKEN')
    if (!MP_ACCESS_TOKEN) {
      throw new Error('MERCADOPAGO_ACCESS_TOKEN no configurado')
    }

    // Consultar el estado real del pago en la API de Mercado Pago
    const mpResponse = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
      headers: {
        'Authorization': `Bearer ${MP_ACCESS_TOKEN}`,
      },
    })

    if (!mpResponse.ok) {
      throw new Error(`Error al consultar pago en MP: ${mpResponse.statusText}`)
    }

    const paymentData = await mpResponse.json()
    
    console.log('Estado del pago en MP:', paymentData.status)

    // Buscar los tickets asociados a este pago
    // Primero intentar por payment_id_mp (preference_id)
    let { data: tickets, error: ticketError } = await supabaseClient
      .from('tickets')
      .select('*')
      .eq('payment_id_mp', paymentData.preference_id || paymentId)

    // Si no encontramos por preference_id, buscar en metadata
    if (!tickets || tickets.length === 0) {
      const externalRef = paymentData.external_reference
      if (externalRef) {
        const { data: ticketsByRef, error } = await supabaseClient
          .from('tickets')
          .select('*')
          .eq('id', externalRef)
        
        tickets = ticketsByRef
        ticketError = error
      }
    }

    if (ticketError || !tickets || tickets.length === 0) {
      console.error('Tickets no encontrados para payment_id:', paymentId)
      return new Response(
        JSON.stringify({ success: false, error: 'Tickets no encontrados' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 404 }
      )
    }

    // Mapear estados de Mercado Pago a nuestros estados
    let newStatus = 'pending'
    if (paymentData.status === 'approved') {
      newStatus = 'approved'
    } else if (paymentData.status === 'rejected' || paymentData.status === 'cancelled') {
      newStatus = 'failed'
    } else if (paymentData.status === 'refunded') {
      newStatus = 'refunded'
    }

    console.log(`Actualizando ${tickets.length} tickets a estado: ${newStatus}`)

    // Actualizar todos los tickets encontrados
    for (const ticket of tickets) {
      // Generar QR code solo si el pago fue aprobado y no tiene QR
      let qrCodeData = ticket.qr_code_data
      if (newStatus === 'approved' && !qrCodeData) {
        qrCodeData = ticket.id // El QR ahora solo contiene el UUID del ticket
      }

      await supabaseClient
        .from('tickets')
        .update({
          payment_status: newStatus,
          qr_code_data: qrCodeData,
          updated_at: new Date().toISOString(),
        })
        .eq('id', ticket.id)
    }

    // Marcar webhook como procesado
    await supabaseClient
      .from('webhook_logs')
      .update({ processed: true })
      .eq('payload->data->>id', paymentId)

    console.log('Webhook procesado exitosamente')

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Webhook processed',
        payment_status: paymentData.status,
        tickets_updated: tickets.length,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('Error en mercadopago-webhook:', error)
    
    // Intentar logear el error
    try {
      const supabaseClient = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
      )
      
      await supabaseClient
        .from('webhook_logs')
        .update({
          processed: true,
          error: error.message,
        })
        .eq('processed', false)
        .order('created_at', { ascending: false })
        .limit(1)
    } catch (logError) {
      console.error('Error al logear el error:', logError)
    }

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})
