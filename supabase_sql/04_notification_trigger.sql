-- Habilitar la extensión pg_net primero (requerida para hacer llamadas HTTP)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Función que se ejecuta automáticamente al insertar una notificación
CREATE OR REPLACE FUNCTION public.trigger_push_notification()
RETURNS TRIGGER AS $$
DECLARE
  project_url text := 'https://tlzkddmquytddhdeqdmo.supabase.co';
  -- IMPORTANTE: Reemplaza esto con tu SERVICE_ROLE_KEY (no la anon key)
  -- La puedes encontrar en: Settings > API > service_role key (secret)
  service_key text := 'YOUR_SERVICE_ROLE_KEY_HERE';
BEGIN
  -- Llamar a la Edge Function de forma asíncrona
  PERFORM
    net.http_post(
      url := project_url || '/functions/v1/send-push-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || service_key
      ),
      body := jsonb_build_object('notification_id', NEW.id)
    );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger que se activa al insertar una notificación
DROP TRIGGER IF EXISTS on_notification_insert ON public.notifications;
CREATE TRIGGER on_notification_insert
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_push_notification();
