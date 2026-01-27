import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const FIREBASE_PROJECT_ID = "comic-fest-app"  // Must match google-services.json
const FIREBASE_PRIVATE_KEY = Deno.env.get("FIREBASE_PRIVATE_KEY")!
const FIREBASE_CLIENT_EMAIL = Deno.env.get("FIREBASE_CLIENT_EMAIL")!

serve(async (req) => {
    try {
        const { notification_id } = await req.json()

        // Crear cliente de Supabase
        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        // Obtener la notificación
        const { data: notification, error: notifError } = await supabaseClient
            .from('notifications')
            .select('*')
            .eq('id', notification_id)
            .single()

        if (notifError) throw notifError

        // Obtener tokens de dispositivos
        let tokensQuery = supabaseClient
            .from('user_push_tokens')
            .select('device_token')

        // Si la notificación es para un usuario específico
        if (notification.user_id) {
            tokensQuery = tokensQuery.eq('user_id', notification.user_id)
        }

        const { data: tokens, error: tokensError } = await tokensQuery

        if (tokensError) throw tokensError
        if (!tokens || tokens.length === 0) {
            return new Response(
                JSON.stringify({ message: 'No device tokens found' }),
                { status: 200, headers: { "Content-Type": "application/json" } }
            )
        }

        // Obtener access token de Google
        const accessToken = await getAccessToken()

        // Enviar notificación a cada dispositivo
        const results = await Promise.all(
            tokens.map(async ({ device_token }) => {
                try {
                    const response = await fetch(
                        `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
                        {
                            method: 'POST',
                            headers: {
                                'Authorization': `Bearer ${accessToken}`,
                                'Content-Type': 'application/json',
                            },
                            body: JSON.stringify({
                                message: {
                                    token: device_token,
                                    notification: {
                                        title: notification.title,
                                        body: notification.message,
                                    },
                                    data: notification.payload || {},
                                    android: {
                                        priority: 'high',
                                        notification: {
                                            sound: 'default',
                                            click_action: 'FLUTTER_NOTIFICATION_CLICK',
                                        },
                                    },
                                    apns: {
                                        payload: {
                                            aps: {
                                                sound: 'default',
                                                badge: 1,
                                            },
                                        },
                                    },
                                },
                            }),
                        }
                    )

                    const result = await response.json()
                    return { token: device_token, success: response.ok, result }
                } catch (error) {
                    return { token: device_token, success: false, error: error.message }
                }
            })
        )

        return new Response(
            JSON.stringify({ success: true, sent: results.length, results }),
            { status: 200, headers: { "Content-Type": "application/json" } }
        )
    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 500, headers: { "Content-Type": "application/json" } }
        )
    }
})

async function getAccessToken(): Promise<string> {
    // Helper function for URL-safe base64 encoding
    const base64urlEncode = (str: string) => {
        return btoa(str)
            .replace(/\+/g, '-')
            .replace(/\//g, '_')
            .replace(/=/g, '');
    };

    const jwtHeader = base64urlEncode(JSON.stringify({ alg: "RS256", typ: "JWT" }));

    const now = Math.floor(Date.now() / 1000);
    const jwtPayload = base64urlEncode(JSON.stringify({
        iss: FIREBASE_CLIENT_EMAIL,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
        aud: "https://oauth2.googleapis.com/token",
        exp: now + 3600,
        iat: now,
    }));

    const signatureInput = `${jwtHeader}.${jwtPayload}`;

    try {
        // Importar la clave privada
        const privateKey = await crypto.subtle.importKey(
            "pkcs8",
            pemToArrayBuffer(FIREBASE_PRIVATE_KEY),
            {
                name: "RSASSA-PKCS1-v1_5",
                hash: "SHA-256",
            },
            false,
            ["sign"]
        );

        // Firmar el JWT
        const signature = await crypto.subtle.sign(
            "RSASSA-PKCS1-v1_5",
            privateKey,
            new TextEncoder().encode(signatureInput)
        );

        // Convert signature to URL-safe base64
        const signatureBase64 = base64urlEncode(
            String.fromCharCode(...new Uint8Array(signature))
        );

        const jwt = `${signatureInput}.${signatureBase64}`;

        console.log('JWT generated, length:', jwt.length);

        // Intercambiar JWT por access token
        const response = await fetch("https://oauth2.googleapis.com/token", {
            method: "POST",
            headers: { "Content-Type": "application/x-www-form-urlencoded" },
            body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
        });

        const data = await response.json();

        if (!response.ok) {
            console.error('OAuth error:', data);
            throw new Error(`OAuth failed: ${JSON.stringify(data)}`);
        }

        if (!data.access_token) {
            throw new Error('No access_token in response');
        }

        console.log('✅ Access token obtained');
        return data.access_token;
    } catch (error) {
        console.error('getAccessToken error:', error);
        throw error;
    }
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
    // Replace literal \n with actual newlines first
    const normalizedPem = pem.replace(/\\n/g, '\n');

    const b64 = normalizedPem
        .replace(/-----BEGIN PRIVATE KEY-----/, "")
        .replace(/-----END PRIVATE KEY-----/, "")
        .replace(/\s/g, "")
        .replace(/\n/g, "");

    try {
        const binary = atob(b64);
        const bytes = new Uint8Array(binary.length);
        for (let i = 0; i < binary.length; i++) {
            bytes[i] = binary.charCodeAt(i);
        }
        return bytes.buffer;
    } catch (error) {
        console.error('Base64 decode error:', error);
        console.error('Base64 string length:', b64.length);
        console.error('First 50 chars:', b64.substring(0, 50));
        throw new Error('Failed to decode base64: ' + error.message);
    }
}
