-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.contest_entries (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  contest_id uuid NOT NULL,
  participant_name text NOT NULL,
  image_url text,
  votes integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT contest_entries_pkey PRIMARY KEY (id),
  CONSTRAINT contest_entries_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id)
);
CREATE TABLE public.contestants (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  schedule_item_id uuid NOT NULL,
  name text NOT NULL,
  description text,
  image_url text,
  contestant_number integer NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT contestants_pkey PRIMARY KEY (id),
  CONSTRAINT contestants_schedule_item_id_fkey FOREIGN KEY (schedule_item_id) REFERENCES public.schedule_items(id)
);
CREATE TABLE public.contests (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  category text NOT NULL,
  description text,
  voting_start timestamp with time zone NOT NULL,
  voting_end timestamp with time zone NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT contests_pkey PRIMARY KEY (id)
);
CREATE TABLE public.exhibitor_details (
  profile_id uuid NOT NULL,
  company_name text NOT NULL,
  booth_id uuid,
  is_featured boolean NOT NULL DEFAULT false,
  promo_quota integer NOT NULL DEFAULT 0,
  website_url text,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT exhibitor_details_pkey PRIMARY KEY (profile_id),
  CONSTRAINT exhibitor_details_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id),
  CONSTRAINT exhibitor_details_booth_id_fkey FOREIGN KEY (booth_id) REFERENCES public.map_points(id)
);
CREATE TABLE public.map_points (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  type text NOT NULL CHECK (type = ANY (ARRAY['stage'::text, 'booth'::text, 'service'::text, 'food'::text, 'entrance'::text, 'exit'::text, 'other'::text])),
  details text,
  coordinates jsonb,
  is_public boolean NOT NULL DEFAULT true,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT map_points_pkey PRIMARY KEY (id)
);
CREATE TABLE public.order_items (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  order_id uuid NOT NULL,
  ticket_type_id uuid,
  product_id uuid,
  item_type text NOT NULL CHECK (item_type = ANY (ARRAY['ticket'::text, 'product'::text])),
  quantity integer NOT NULL DEFAULT 1,
  unit_price numeric NOT NULL,
  subtotal numeric NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT order_items_pkey PRIMARY KEY (id),
  CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id),
  CONSTRAINT order_items_ticket_type_id_fkey FOREIGN KEY (ticket_type_id) REFERENCES public.ticket_types(id),
  CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.orders (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  items jsonb NOT NULL,
  total_amount numeric NOT NULL,
  payment_method text,
  delivery_method text CHECK (delivery_method = ANY (ARRAY['envio'::text, 'recoger'::text])),
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'paid'::text, 'shipped'::text, 'completed'::text, 'cancelled'::text])),
  payment_id_mp text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  order_number text UNIQUE,
  order_type text DEFAULT 'ticket'::text CHECK (order_type = ANY (ARRAY['ticket'::text, 'product'::text, 'mixed'::text])),
  buyer_name text,
  buyer_email text,
  buyer_phone text,
  CONSTRAINT orders_pkey PRIMARY KEY (id),
  CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.panel_votes (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  schedule_item_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  contestant_id uuid,
  points integer NOT NULL DEFAULT 1,
  synced boolean NOT NULL DEFAULT true,
  CONSTRAINT panel_votes_pkey PRIMARY KEY (id),
  CONSTRAINT panel_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT panel_votes_schedule_item_id_fkey FOREIGN KEY (schedule_item_id) REFERENCES public.schedule_items(id),
  CONSTRAINT panel_votes_contestant_id_fkey FOREIGN KEY (contestant_id) REFERENCES public.contestants(id)
);
CREATE TABLE public.passport_stamps (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  exhibitor_id uuid NOT NULL,
  stamped_at timestamp with time zone DEFAULT now(),
  CONSTRAINT passport_stamps_pkey PRIMARY KEY (id),
  CONSTRAINT passport_stamps_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT passport_stamps_exhibitor_id_fkey FOREIGN KEY (exhibitor_id) REFERENCES public.exhibitor_details(profile_id)
);
CREATE TABLE public.payments (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  order_id uuid NOT NULL,
  mp_payment_id text UNIQUE,
  mp_preference_id text,
  status text NOT NULL DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text, 'refunded'::text, 'cancelled'::text])),
  payment_method text,
  payment_method_type text,
  transaction_amount numeric NOT NULL,
  currency text DEFAULT 'MXN'::text,
  status_detail text,
  external_reference text,
  webhook_data jsonb,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT payments_pkey PRIMARY KEY (id),
  CONSTRAINT payments_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id)
);
CREATE TABLE public.points_log (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  points_change integer NOT NULL,
  reason text NOT NULL,
  source_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  synced boolean DEFAULT true,
  type text CHECK (type = ANY (ARRAY['earn'::text, 'spend'::text])),
  CONSTRAINT points_log_pkey PRIMARY KEY (id),
  CONSTRAINT points_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.products (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  description text,
  price numeric NOT NULL,
  seller_id uuid,
  stock integer NOT NULL DEFAULT 0,
  shipping_option text NOT NULL DEFAULT 'stand_pickup'::text CHECK (shipping_option = ANY (ARRAY['stand_pickup'::text, 'home_delivery'::text, 'both'::text])),
  image_url text,
  is_active boolean NOT NULL DEFAULT true,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  points_price integer,
  is_exclusive boolean DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT products_pkey PRIMARY KEY (id),
  CONSTRAINT products_seller_id_fkey FOREIGN KEY (seller_id) REFERENCES public.exhibitor_details(profile_id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL DEFAULT auth.uid(),
  role text NOT NULL DEFAULT 'attendee'::text CHECK (role = ANY (ARRAY['attendee'::text, 'exhibitor'::text, 'artist'::text, 'admin'::text, 'staff'::text])),
  username text,
  bio text,
  avatar_url text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  points integer NOT NULL DEFAULT 0,
  CONSTRAINT profiles_pkey PRIMARY KEY (id)
);
CREATE TABLE public.promotions (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  exhibitor_id uuid NOT NULL,
  title text NOT NULL,
  description text NOT NULL,
  discount_percent integer,
  valid_until timestamp with time zone NOT NULL,
  is_flash boolean DEFAULT false,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT promotions_pkey PRIMARY KEY (id),
  CONSTRAINT promotions_exhibitor_id_fkey FOREIGN KEY (exhibitor_id) REFERENCES public.exhibitor_details(profile_id)
);
CREATE TABLE public.schedule_items (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  title text NOT NULL,
  description text,
  start_time timestamp with time zone NOT NULL,
  end_time timestamp with time zone NOT NULL,
  location_id uuid,
  artist_id uuid,
  is_active boolean NOT NULL DEFAULT true,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  category text CHECK (category = ANY (ARRAY['panel'::text, 'firma'::text, 'torneo'::text, 'actividad'::text, 'concurso'::text])),
  image_url text,
  featured_artists ARRAY DEFAULT '{}'::text[],
  CONSTRAINT schedule_items_pkey PRIMARY KEY (id),
  CONSTRAINT schedule_items_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.map_points(id),
  CONSTRAINT schedule_items_artist_id_fkey FOREIGN KEY (artist_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.ticket_types (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  description text,
  price numeric NOT NULL,
  stock_total integer NOT NULL DEFAULT 0,
  stock_available integer NOT NULL DEFAULT 0,
  benefits ARRAY,
  is_early_bird boolean DEFAULT false,
  is_active boolean DEFAULT true,
  display_order integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ticket_types_pkey PRIMARY KEY (id)
);
CREATE TABLE public.tickets (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  ticket_type text NOT NULL,
  price numeric NOT NULL,
  payment_status text NOT NULL DEFAULT 'pending'::text CHECK (payment_status = ANY (ARRAY['pending'::text, 'approved'::text, 'failed'::text, 'refunded'::text])),
  payment_id_mp text,
  qr_code_data text NOT NULL UNIQUE,
  is_validated boolean NOT NULL DEFAULT false,
  validated_at timestamp with time zone,
  purchase_date timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT tickets_pkey PRIMARY KEY (id),
  CONSTRAINT tickets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.votes (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  contest_id uuid NOT NULL,
  entry_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT votes_pkey PRIMARY KEY (id),
  CONSTRAINT votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT votes_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id),
  CONSTRAINT votes_entry_id_fkey FOREIGN KEY (entry_id) REFERENCES public.contest_entries(id)
);
CREATE TABLE public.webhook_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  provider text NOT NULL DEFAULT 'mercadopago'::text,
  event_type text,
  payload jsonb NOT NULL,
  processed boolean DEFAULT false,
  error text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT webhook_logs_pkey PRIMARY KEY (id)
);