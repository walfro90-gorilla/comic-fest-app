-- ============================================================================
-- COMIC FEST - CREACIÓN DE TABLAS
-- ============================================================================
-- Ejecuta este script en Supabase SQL Editor para crear todas las tablas
-- ============================================================================

-- ============================================================================
-- 1. PROFILES (Perfiles de usuarios)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY DEFAULT auth.uid(),
  role text NOT NULL DEFAULT 'attendee' CHECK (role = ANY (ARRAY['attendee', 'exhibitor', 'artist', 'admin', 'staff'])),
  username text,
  bio text,
  avatar_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  points integer NOT NULL DEFAULT 0
);

-- ============================================================================
-- 2. MAP_POINTS (Puntos del mapa - Escenarios, Booths, Servicios)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.map_points (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  type text NOT NULL CHECK (type = ANY (ARRAY['stage', 'booth', 'service', 'food', 'entrance', 'exit', 'other'])),
  details text,
  coordinates jsonb,
  is_public boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================================
-- 3. SCHEDULE_ITEMS (Eventos de la agenda)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.schedule_items (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  title text NOT NULL,
  description text,
  start_time timestamptz NOT NULL,
  end_time timestamptz NOT NULL,
  location_id uuid REFERENCES public.map_points(id),
  artist_id uuid REFERENCES public.profiles(id),
  is_active boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now(),
  category text CHECK (category = ANY (ARRAY['panel', 'firma', 'torneo', 'actividad', 'concurso'])),
  image_url text,
  featured_artists text[] DEFAULT '{}'
);

-- ============================================================================
-- 4. TICKETS (Boletos del festival)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.tickets (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  ticket_type text NOT NULL,
  price numeric NOT NULL,
  payment_status text NOT NULL DEFAULT 'pending' CHECK (payment_status = ANY (ARRAY['pending', 'approved', 'failed', 'refunded'])),
  payment_id_mp text,
  qr_code_data text NOT NULL UNIQUE,
  is_validated boolean NOT NULL DEFAULT false,
  validated_at timestamptz,
  purchase_date timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================================
-- 5. EXHIBITOR_DETAILS (Detalles de expositores)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.exhibitor_details (
  profile_id uuid PRIMARY KEY REFERENCES public.profiles(id),
  company_name text NOT NULL,
  booth_id uuid REFERENCES public.map_points(id),
  is_featured boolean NOT NULL DEFAULT false,
  promo_quota integer NOT NULL DEFAULT 0,
  website_url text,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================================
-- 6. PRODUCTS (Productos de la tienda)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.products (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  description text,
  price numeric NOT NULL,
  seller_id uuid REFERENCES public.exhibitor_details(profile_id),
  stock integer NOT NULL DEFAULT 0,
  shipping_option text NOT NULL DEFAULT 'stand_pickup' CHECK (shipping_option = ANY (ARRAY['stand_pickup', 'home_delivery', 'both'])),
  image_url text,
  is_active boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now(),
  points_price integer,
  is_exclusive boolean DEFAULT false
);

-- ============================================================================
-- 7. POINTS_LOG (Registro de transacciones de puntos)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.points_log (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  points_change integer NOT NULL,
  reason text NOT NULL,
  source_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  synced boolean DEFAULT true,
  type text CHECK (type = ANY (ARRAY['earn', 'spend']))
);

-- ============================================================================
-- 8. PROMOTIONS (Promociones de expositores)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.promotions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  exhibitor_id uuid NOT NULL REFERENCES public.exhibitor_details(profile_id),
  title text NOT NULL,
  description text NOT NULL,
  discount_percent integer,
  valid_until timestamptz NOT NULL,
  is_flash boolean DEFAULT false,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================================================
-- 9. CONTESTS (Concursos de cosplay, arte, etc)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.contests (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  category text NOT NULL,
  description text,
  voting_start timestamptz NOT NULL,
  voting_end timestamptz NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================================================
-- 10. CONTEST_ENTRIES (Participantes de concursos)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.contest_entries (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  contest_id uuid NOT NULL REFERENCES public.contests(id),
  participant_name text NOT NULL,
  image_url text,
  votes integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- ============================================================================
-- 11. VOTES (Votos de usuarios en concursos)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.votes (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  contest_id uuid NOT NULL REFERENCES public.contests(id),
  entry_id uuid NOT NULL REFERENCES public.contest_entries(id),
  created_at timestamptz DEFAULT now()
);

-- ============================================================================
-- 12. PASSPORT_STAMPS (Pasaporte virtual - gamificación)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.passport_stamps (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  exhibitor_id uuid NOT NULL REFERENCES public.exhibitor_details(profile_id),
  stamped_at timestamptz DEFAULT now()
);

-- ============================================================================
-- 13. ORDERS (Pedidos de productos)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.orders (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  items jsonb NOT NULL,
  total_amount numeric NOT NULL,
  payment_method text,
  delivery_method text CHECK (delivery_method = ANY (ARRAY['envio', 'recoger'])),
  status text DEFAULT 'pending' CHECK (status = ANY (ARRAY['pending', 'paid', 'shipped', 'completed', 'cancelled'])),
  payment_id_mp text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
