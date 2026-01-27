-- ============================================
-- SCRIPT DE DEBUG PARA NOTIFICACIONES PUSH
-- Ejecuta paso a paso para diagnosticar
-- ============================================

-- PASO 1: Verificar que existen tokens FCM
SELECT 
  user_id,
  LEFT(device_token, 20) || '...' as token_preview,
  platform,
  created_at
FROM public.user_push_tokens
ORDER BY created_at DESC
LIMIT 5;

-- PASO 2: Ver las últimas notificaciones insertadas
SELECT 
  id,
  user_id,
  title,
  message,
  type,
  created_at
FROM public.notifications
ORDER BY created_at DESC
LIMIT 5;

-- PASO 3: Ver las últimas respuestas HTTP de la Edge Function
SELECT 
  id,
  status_code,
  LEFT(content::text, 200) as content_preview,
  created
FROM net._http_response 
ORDER BY created DESC 
LIMIT 3;

-- PASO 4: Insertar una notificación de prueba
-- IMPORTANTE: Reemplaza 'TU_USER_ID' con el valor de PASO 1
/*
INSERT INTO public.notifications (user_id, title, message, type)
VALUES (
  'TU_USER_ID_AQUI',  -- Copia el user_id del PASO 1
  '🔥 Test ' || NOW()::text,
  'Timestamp: ' || NOW()::text,
  'general'
)
RETURNING id, title, created_at;
*/

-- PASO 5: Espera 2-3 segundos y vuelve a ejecutar PASO 3
-- Deberías ver una nueva entrada con la respuesta

-- PASO 6: Ver detalles del último intento de notificación
SELECT 
  nr.id as response_id,
  nr.status_code,
  nr.content,
  nr.error_msg,
  nr.created
FROM net._http_response nr
ORDER BY nr.created DESC
LIMIT 1;
