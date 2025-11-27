-- ============================================================================
-- COMIC FEST - SUPABASE TABLES SCHEMA
-- ============================================================================
-- IMPORTANT: Este esquema DEBE coincidir con tu base de datos existente.
-- Solo se incluyen las tablas necesarias para la app móvil.
-- ============================================================================

-- Tabla de perfiles de usuarios (vinculada a auth.users)
-- Nota: Esta tabla ya existe en tu base de datos
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username text,
  avatar_url text,
  bio text,
  role text NOT NULL DEFAULT 'attendee',
  points integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Índices para profiles
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_points ON public.profiles(points DESC);

-- ============================================================================
-- Tabla de boletos (tickets)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  ticket_type text NOT NULL,
  price numeric(10,2) NOT NULL,
  payment_status text NOT NULL DEFAULT 'pending',
  payment_id_mp text,
  qr_code_data text NOT NULL,
  is_validated boolean NOT NULL DEFAULT false,
  validated_at timestamptz,
  purchase_date timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Índices para tickets
CREATE INDEX IF NOT EXISTS idx_tickets_user ON public.tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_tickets_payment_status ON public.tickets(payment_status);
CREATE INDEX IF NOT EXISTS idx_tickets_qr_code ON public.tickets(qr_code_data);
CREATE INDEX IF NOT EXISTS idx_tickets_validated ON public.tickets(is_validated);

-- ============================================================================
-- Tabla de eventos (schedule_items)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.schedule_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  category text,
  start_time timestamptz NOT NULL,
  end_time timestamptz NOT NULL,
  location_id uuid,
  artist_id uuid,
  is_active boolean NOT NULL DEFAULT true,
  image_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Índices para schedule_items
CREATE INDEX IF NOT EXISTS idx_schedule_start_time ON public.schedule_items(start_time);
CREATE INDEX IF NOT EXISTS idx_schedule_active ON public.schedule_items(is_active);
CREATE INDEX IF NOT EXISTS idx_schedule_category ON public.schedule_items(category);

-- ============================================================================
-- Tabla de productos (tienda de mercancía)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text NOT NULL,
  price numeric(10,2) NOT NULL,
  points_price integer,
  image_url text NOT NULL,
  stock integer NOT NULL DEFAULT 0,
  is_exclusive boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Índices para products
CREATE INDEX IF NOT EXISTS idx_products_exclusive ON public.products(is_exclusive);
CREATE INDEX IF NOT EXISTS idx_products_stock ON public.products(stock);

-- ============================================================================
-- Tabla de transacciones de puntos
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.points_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount integer NOT NULL,
  type text NOT NULL CHECK (type IN ('earn', 'spend')),
  reason text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Índices para points_transactions
CREATE INDEX IF NOT EXISTS idx_points_transactions_user ON public.points_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_points_transactions_created ON public.points_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_points_transactions_type ON public.points_transactions(type);

-- ============================================================================
-- TRIGGERS para updated_at automático
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar triggers a todas las tablas con updated_at
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tickets_updated_at
  BEFORE UPDATE ON public.tickets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_schedule_items_updated_at
  BEFORE UPDATE ON public.schedule_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
