-- ============================================================================
-- COMIC FEST - TRIGGERS Y FUNCIONES
-- ============================================================================
-- Ejecuta este script DESPUÉS de crear las tablas e índices
-- ============================================================================

-- ============================================================================
-- FUNCIÓN: Actualizar updated_at automáticamente
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGERS: Aplicar updated_at a todas las tablas relevantes
-- ============================================================================

-- Profiles
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Map Points
DROP TRIGGER IF EXISTS update_map_points_updated_at ON public.map_points;
CREATE TRIGGER update_map_points_updated_at
  BEFORE UPDATE ON public.map_points
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Schedule Items
DROP TRIGGER IF EXISTS update_schedule_items_updated_at ON public.schedule_items;
CREATE TRIGGER update_schedule_items_updated_at
  BEFORE UPDATE ON public.schedule_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Tickets
DROP TRIGGER IF EXISTS update_tickets_updated_at ON public.tickets;
CREATE TRIGGER update_tickets_updated_at
  BEFORE UPDATE ON public.tickets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Exhibitor Details
DROP TRIGGER IF EXISTS update_exhibitor_details_updated_at ON public.exhibitor_details;
CREATE TRIGGER update_exhibitor_details_updated_at
  BEFORE UPDATE ON public.exhibitor_details
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Products
DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Promotions
DROP TRIGGER IF EXISTS update_promotions_updated_at ON public.promotions;
CREATE TRIGGER update_promotions_updated_at
  BEFORE UPDATE ON public.promotions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Contests
DROP TRIGGER IF EXISTS update_contests_updated_at ON public.contests;
CREATE TRIGGER update_contests_updated_at
  BEFORE UPDATE ON public.contests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Orders
DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER: Crear perfil automáticamente cuando se registra un usuario
-- ============================================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, role, username, created_at, updated_at, points)
  VALUES (
    NEW.id,
    'attendee',
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    now(),
    now(),
    0
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Eliminar trigger existente si existe
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Crear trigger para nuevos usuarios
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
