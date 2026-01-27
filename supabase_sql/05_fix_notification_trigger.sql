-- ============================================
-- SCRIPT PARA RECREAR EL TRIGGER DE NOTIFICACIONES
-- Ejecuta este script completo en Supabase SQL Editor
-- ============================================

-- 1. Habilitar pg_net (requerido para llamadas HTTP)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Eliminar trigger y función existentes (por si acaso)
DROP TRIGGER IF EXISTS on_notification_insert ON public.notifications;
DROP FUNCTION IF EXISTS public.trigger_push_notification();

-- 3. Crear la función del trigger
CREATE OR REPLACE FUNCTION public.trigger_push_notification()
RETURNS TRIGGER AS $$
DECLARE
  project_url text := 'https://tlzkddmquytddhdeqdmo.supabase.co';
  -- IMPORTANTE: Debes reemplazar esto con tu SERVICE_ROLE_KEY
  -- La encuentras en: Settings > API > service_role key (secret)
  service_key text := 'TU_SERVICE_ROLE_KEY_AQUI';
  request_id bigint;
BEGIN
  -- Llamar a la Edge Function de forma asíncrona usando pg_net
  SELECT INTO request_id net.http_post(
    url := project_url || '/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || service_key
    ),
    body := jsonb_build_object('notification_id', NEW.id)
  );
  
  -- Log para debugging
  RAISE LOG 'Trigger ejecutado para notificación % - Request ID: %', NEW.id, request_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Crear el trigger
CREATE TRIGGER on_notification_insert
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_push_notification();

-- 5. Verificar que todo se creó correctamente
SELECT 
  'Función existe' as tipo,
  proname as nombre
FROM pg_proc 
WHERE proname = 'trigger_push_notification'

UNION ALL

SELECT 
  'Trigger existe' as tipo,
  tgname as nombre
FROM pg_trigger 
WHERE tgname = 'on_notification_insert';

-- 6. Probar con una notificación
-- REEMPLAZA 'TU_USER_ID' con tu ID de usuario real (lo puedes copiar de la tabla user_push_tokens)
-- Descomenta las siguientes líneas para probar:

/*
INSERT INTO public.notifications (user_id, title, message, type)
VALUES(
  'TU_USER_ID',
  '🎯 Test de Notificación Push',
  'Si ves esto en tu teléfono, ¡funciona!',
  'general'
);
*/
