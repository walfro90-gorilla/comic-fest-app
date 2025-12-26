import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing Authorization header')
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { prompt } = await req.json()

    // 1. Get User
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      console.error('Auth Error:', userError)
      throw new Error(`Auth Failed: ${userError?.message || 'Unknown error'} | User: ${user ? 'Found' : 'Missing'} | Header: ${authHeader.substring(0, 10)}...`)
    }

    // 2. Check Credits
    const { data: profile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('credits')
      .eq('id', user.id)
      .single()

    if (profileError || !profile) {
      console.error('Profile Error:', profileError)
      throw new Error('Error al verificar créditos')
    }

    if (profile.credits < 1) {
      throw new Error('Créditos insuficientes')
    }

    // 3. Generate Image (Mock for now)
    const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')
    if (!GEMINI_API_KEY) {
      console.error('Missing GEMINI_API_KEY')
      throw new Error('Server configuration error')
    }

    // Mock generation
    const generatedImageUrl = `https://placehold.co/600x400?text=${encodeURIComponent(prompt)}`

    // 4. Deduct Credit
    const { error: updateError } = await supabaseClient
      .from('profiles')
      .update({ credits: profile.credits - 1 })
      .eq('id', user.id)

    if (updateError) throw new Error('Error al descontar créditos')

    // 5. Save Comic
    const { data: comic, error: comicError } = await supabaseClient
      .from('comics')
      .insert({
        user_id: user.id,
        prompt: prompt,
        image_url: generatedImageUrl,
        status: 'completed',
        model_used: 'gemini-pro'
      })
      .select()
      .single()

    if (comicError) {
      console.error('Save Comic Error:', comicError)
      throw new Error('Error al guardar el comic')
    }

    return new Response(
      JSON.stringify(comic),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )

  } catch (error) {
    console.error('Function Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
