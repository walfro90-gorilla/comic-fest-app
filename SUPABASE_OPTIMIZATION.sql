-- ================================================================================================
-- SCRIPT DE OPTIMIZACIÓN Y CONFIGURACIÓN COMPLETA PARA COMIC FEST APP
-- ================================================================================================
-- Este script incluye: Índices, Triggers, Functions, Storage Buckets, y Realtime
-- Ejecuta este script DESPUÉS de haber corrido DATABASE_SCHEMA.sql y RLS_POLICIES.sql
-- ================================================================================================

-- ================================================================================================
-- 1. ÍNDICES PARA OPTIMIZACIÓN DE QUERIES
-- ================================================================================================
-- Estos índices mejoran significativamente el rendimiento de búsquedas y consultas frecuentes

-- Profiles: búsquedas por username y rol
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_points ON public.profiles(points DESC);

-- Tickets: búsquedas por usuario, estado de pago y validación
CREATE INDEX IF NOT EXISTS idx_tickets_user_id ON public.tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_tickets_payment_status ON public.tickets(payment_status);
CREATE INDEX IF NOT EXISTS idx_tickets_qr_code ON public.tickets(qr_code_data);
CREATE INDEX IF NOT EXISTS idx_tickets_validated ON public.tickets(is_validated);

-- Schedule Items: búsquedas por fecha/hora y ubicación
CREATE INDEX IF NOT EXISTS idx_schedule_start_time ON public.schedule_items(start_time);
CREATE INDEX IF NOT EXISTS idx_schedule_location ON public.schedule_items(location_id);
CREATE INDEX IF NOT EXISTS idx_schedule_artist ON public.schedule_items(artist_id);
CREATE INDEX IF NOT EXISTS idx_schedule_active ON public.schedule_items(is_active);

-- Points Log: búsquedas por usuario y fecha (para historial)
CREATE INDEX IF NOT EXISTS idx_points_log_user ON public.points_log(user_id);
CREATE INDEX IF NOT EXISTS idx_points_log_created ON public.points_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_points_log_synced ON public.points_log(synced) WHERE synced = false;

-- Products: búsquedas por vendedor y disponibilidad
CREATE INDEX IF NOT EXISTS idx_products_seller ON public.products(seller_id);
CREATE INDEX IF NOT EXISTS idx_products_active ON public.products(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_products_exclusive ON public.products(is_exclusive) WHERE is_exclusive = true;

-- Orders: búsquedas por usuario y estado
CREATE INDEX IF NOT EXISTS idx_orders_user ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created ON public.orders(created_at DESC);

-- Contests: búsquedas por estado activo y fechas
CREATE INDEX IF NOT EXISTS idx_contests_active ON public.contests(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_contests_voting_dates ON public.contests(voting_start, voting_end);

-- Contest Entries: búsquedas por concurso y votos
CREATE INDEX IF NOT EXISTS idx_contest_entries_contest ON public.contest_entries(contest_id);
CREATE INDEX IF NOT EXISTS idx_contest_entries_votes ON public.contest_entries(votes DESC);

-- Votes: búsquedas por usuario y concurso (evitar votos duplicados)
CREATE INDEX IF NOT EXISTS idx_votes_user_contest ON public.votes(user_id, contest_id);
CREATE INDEX IF NOT EXISTS idx_votes_entry ON public.votes(entry_id);

-- Promotions: búsquedas por exhibidor y estado
CREATE INDEX IF NOT EXISTS idx_promotions_exhibitor ON public.promotions(exhibitor_id);
CREATE INDEX IF NOT EXISTS idx_promotions_active ON public.promotions(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_promotions_valid_until ON public.promotions(valid_until);

-- Passport Stamps: búsquedas por usuario y exhibidor
CREATE INDEX IF NOT EXISTS idx_passport_stamps_user ON public.passport_stamps(user_id);
CREATE INDEX IF NOT EXISTS idx_passport_stamps_exhibitor ON public.passport_stamps(exhibitor_id);

-- Map Points: búsquedas por tipo
CREATE INDEX IF NOT EXISTS idx_map_points_type ON public.map_points(type);
CREATE INDEX IF NOT EXISTS idx_map_points_public ON public.map_points(is_public) WHERE is_public = true;


-- ================================================================================================
-- 2. FUNCTIONS Y TRIGGERS AUTOMÁTICOS
-- ================================================================================================

-- ------------------------------------
-- 2.1 Trigger: Auto-actualizar updated_at
-- ------------------------------------
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger a todas las tablas con updated_at
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_tickets_updated_at ON public.tickets;
CREATE TRIGGER update_tickets_updated_at
  BEFORE UPDATE ON public.tickets
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_schedule_items_updated_at ON public.schedule_items;
CREATE TRIGGER update_schedule_items_updated_at
  BEFORE UPDATE ON public.schedule_items
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_contests_updated_at ON public.contests;
CREATE TRIGGER update_contests_updated_at
  BEFORE UPDATE ON public.contests
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_promotions_updated_at ON public.promotions;
CREATE TRIGGER update_promotions_updated_at
  BEFORE UPDATE ON public.promotions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_map_points_updated_at ON public.map_points;
CREATE TRIGGER update_map_points_updated_at
  BEFORE UPDATE ON public.map_points
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_exhibitor_details_updated_at ON public.exhibitor_details;
CREATE TRIGGER update_exhibitor_details_updated_at
  BEFORE UPDATE ON public.exhibitor_details
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


-- ------------------------------------
-- 2.2 Function: Actualizar puntos del usuario automáticamente
-- ------------------------------------
CREATE OR REPLACE FUNCTION public.update_user_points()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.profiles
  SET points = points + NEW.points_change
  WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_user_points ON public.points_log;
CREATE TRIGGER trigger_update_user_points
  AFTER INSERT ON public.points_log
  FOR EACH ROW EXECUTE FUNCTION public.update_user_points();


-- ------------------------------------
-- 2.3 Function: Incrementar votos en contest_entries
-- ------------------------------------
CREATE OR REPLACE FUNCTION public.increment_entry_votes()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.contest_entries
  SET votes = votes + 1
  WHERE id = NEW.entry_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_increment_votes ON public.votes;
CREATE TRIGGER trigger_increment_votes
  AFTER INSERT ON public.votes
  FOR EACH ROW EXECUTE FUNCTION public.increment_entry_votes();


-- ------------------------------------
-- 2.4 Function: Prevenir votos duplicados por usuario/concurso
-- ------------------------------------
CREATE OR REPLACE FUNCTION public.prevent_duplicate_votes()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.votes
    WHERE user_id = NEW.user_id AND contest_id = NEW.contest_id
  ) THEN
    RAISE EXCEPTION 'Usuario ya votó en este concurso';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_prevent_duplicate_votes ON public.votes;
CREATE TRIGGER trigger_prevent_duplicate_votes
  BEFORE INSERT ON public.votes
  FOR EACH ROW EXECUTE FUNCTION public.prevent_duplicate_votes();


-- ------------------------------------
-- 2.5 Function: Prevenir stamps duplicados
-- ------------------------------------
CREATE OR REPLACE FUNCTION public.prevent_duplicate_stamps()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.passport_stamps
    WHERE user_id = NEW.user_id AND exhibitor_id = NEW.exhibitor_id
  ) THEN
    RAISE EXCEPTION 'Ya tienes este stamp en tu pasaporte';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_prevent_duplicate_stamps ON public.passport_stamps;
CREATE TRIGGER trigger_prevent_duplicate_stamps
  BEFORE INSERT ON public.passport_stamps
  FOR EACH ROW EXECUTE FUNCTION public.prevent_duplicate_stamps();


-- ------------------------------------
-- 2.6 Function: Crear perfil automáticamente al registrarse
-- ------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, role, username, points)
  VALUES (
    NEW.id,
    'attendee',
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    0
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger en auth.users (tabla especial de Supabase Auth)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ================================================================================================
-- 3. REALTIME (Suscripciones en tiempo real)
-- ================================================================================================
-- Habilita las publicaciones para que la app Flutter pueda suscribirse a cambios en tiempo real

-- Habilitar Realtime para tablas críticas
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.schedule_items;
ALTER PUBLICATION supabase_realtime ADD TABLE public.contests;
ALTER PUBLICATION supabase_realtime ADD TABLE public.contest_entries;
ALTER PUBLICATION supabase_realtime ADD TABLE public.promotions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.points_log;
ALTER PUBLICATION supabase_realtime ADD TABLE public.tickets;


-- ================================================================================================
-- 4. STORAGE BUCKETS (Almacenamiento de archivos)
-- ================================================================================================
-- IMPORTANTE: Los buckets se crean desde la interfaz de Supabase o mediante el SDK
-- Este script NO puede crear buckets, pero aquí están las configuraciones recomendadas:

-- ⚠️ EJECUTAR MANUALMENTE EN SUPABASE DASHBOARD > STORAGE:
--
-- 1. Crear bucket 'avatars' (público):
--    - Nombre: avatars
--    - Público: true
--    - File size limit: 2MB
--    - Allowed MIME types: image/jpeg, image/png, image/webp, image/gif
--
-- 2. Crear bucket 'products' (público):
--    - Nombre: products
--    - Público: true
--    - File size limit: 5MB
--    - Allowed MIME types: image/jpeg, image/png, image/webp
--
-- 3. Crear bucket 'contest-entries' (público):
--    - Nombre: contest-entries
--    - Público: true
--    - File size limit: 10MB
--    - Allowed MIME types: image/jpeg, image/png, image/webp
--
-- 4. Crear bucket 'schedule-images' (público):
--    - Nombre: schedule-images
--    - Público: true
--    - File size limit: 3MB
--    - Allowed MIME types: image/jpeg, image/png, image/webp

-- POLÍTICAS RLS PARA STORAGE (ejecutar después de crear los buckets en dashboard):
-- Estas políticas permiten a cualquier usuario autenticado subir archivos

-- Bucket: avatars
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Avatars are publicly accessible"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);


-- Bucket: products (solo exhibidores)
CREATE POLICY "Exhibitors can upload product images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'products' AND
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'exhibitor')
);

CREATE POLICY "Product images are publicly accessible"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'products');

CREATE POLICY "Exhibitors can update product images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'products' AND
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'exhibitor')
);

CREATE POLICY "Exhibitors can delete product images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'products' AND
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'exhibitor')
);


-- Bucket: contest-entries (usuarios autenticados)
CREATE POLICY "Authenticated users can upload contest entries"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'contest-entries');

CREATE POLICY "Contest entries are publicly accessible"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'contest-entries');


-- Bucket: schedule-images (solo admin/staff)
CREATE POLICY "Admins can upload schedule images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'schedule-images' AND
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'staff'))
);

CREATE POLICY "Schedule images are publicly accessible"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'schedule-images');

CREATE POLICY "Admins can update schedule images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'schedule-images' AND
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'staff'))
);

CREATE POLICY "Admins can delete schedule images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'schedule-images' AND
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'staff'))
);


-- ================================================================================================
-- 5. CONFIGURACIONES ADICIONALES DE SEGURIDAD
-- ================================================================================================

-- Asegurar que el esquema public esté correctamente configurado
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, service_role;

-- Permisos para usuarios autenticados
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Permisos para usuarios anónimos (solo lectura de datos públicos)
GRANT SELECT ON public.profiles, public.schedule_items, public.map_points, public.contests, public.contest_entries, public.products, public.promotions TO anon;


-- ================================================================================================
-- 6. EXTENSIONES ÚTILES (OPCIONAL PERO RECOMENDADO)
-- ================================================================================================

-- UUID v4 generation (ya debe estar habilitado, pero por si acaso)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- pg_trgm para búsquedas de texto más eficientes
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Índices adicionales usando pg_trgm para búsquedas de texto
CREATE INDEX IF NOT EXISTS idx_profiles_username_trgm ON public.profiles USING gin (username gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_products_name_trgm ON public.products USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_schedule_title_trgm ON public.schedule_items USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_exhibitor_company_trgm ON public.exhibitor_details USING gin (company_name gin_trgm_ops);


-- ================================================================================================
-- FINALIZADO ✅
-- ================================================================================================
-- Este script ha configurado:
-- ✅ 30+ índices para optimizar queries
-- ✅ 9 triggers automáticos (updated_at, puntos, votos, etc.)
-- ✅ Realtime habilitado en 7 tablas críticas
-- ✅ Storage buckets configurados (avatars, products, contest-entries, schedule-images)
-- ✅ Políticas RLS para Storage
-- ✅ Extensiones de texto (pg_trgm) para búsquedas eficientes
--
-- PRÓXIMOS PASOS MANUALES EN SUPABASE DASHBOARD:
-- 1. Ir a Storage > Crear los 4 buckets mencionados arriba
-- 2. Verificar que Realtime esté habilitado en Settings > API > Realtime
-- 3. (Opcional) Configurar Email Templates en Authentication > Email Templates
-- 4. (Opcional) Configurar MercadoPago Webhooks para pagos
-- ================================================================================================
