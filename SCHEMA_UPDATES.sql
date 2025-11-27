-- Actualizaciones necesarias para el esquema de Supabase de Comic Fest
-- Ejecuta estos comandos en el SQL Editor de Supabase

-- 1. Agregar campo de puntos a profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS points integer NOT NULL DEFAULT 0;

-- 2. Agregar campos adicionales a schedule_items
ALTER TABLE public.schedule_items
ADD COLUMN IF NOT EXISTS category text CHECK (category = ANY (ARRAY['panel'::text, 'firma'::text, 'torneo'::text, 'actividad'::text])),
ADD COLUMN IF NOT EXISTS image_url text,
ADD COLUMN IF NOT EXISTS featured_artists text[] DEFAULT '{}';

-- 3. Agregar campos de puntos y exclusividad a products
ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS points_price integer,
ADD COLUMN IF NOT EXISTS is_exclusive boolean DEFAULT false;

-- 4. Agregar campos de sincronización y tipo a points_log
ALTER TABLE public.points_log
ADD COLUMN IF NOT EXISTS synced boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS type text CHECK (type = ANY (ARRAY['earn'::text, 'spend'::text]));

-- 5. Crear tabla de promociones
CREATE TABLE IF NOT EXISTS public.promotions (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  exhibitor_id uuid NOT NULL REFERENCES public.exhibitor_details(profile_id) ON DELETE CASCADE,
  title text NOT NULL,
  description text NOT NULL,
  discount_percent integer,
  valid_until timestamp with time zone NOT NULL,
  is_flash boolean DEFAULT false,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT promotions_pkey PRIMARY KEY (id)
);

-- 6. Crear tabla de concursos
CREATE TABLE IF NOT EXISTS public.contests (
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

-- 7. Crear tabla de participantes de concursos
CREATE TABLE IF NOT EXISTS public.contest_entries (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  contest_id uuid NOT NULL REFERENCES public.contests(id) ON DELETE CASCADE,
  participant_name text NOT NULL,
  image_url text,
  votes integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT contest_entries_pkey PRIMARY KEY (id)
);

-- 8. Crear tabla de votos
CREATE TABLE IF NOT EXISTS public.votes (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  contest_id uuid NOT NULL REFERENCES public.contests(id) ON DELETE CASCADE,
  entry_id uuid NOT NULL REFERENCES public.contest_entries(id) ON DELETE CASCADE,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT votes_pkey PRIMARY KEY (id),
  CONSTRAINT votes_unique UNIQUE (user_id, contest_id)
);

-- 9. Crear tabla de pasaporte virtual (gamificación)
CREATE TABLE IF NOT EXISTS public.passport_stamps (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  exhibitor_id uuid NOT NULL REFERENCES public.exhibitor_details(profile_id) ON DELETE CASCADE,
  stamped_at timestamp with time zone DEFAULT now(),
  CONSTRAINT passport_stamps_pkey PRIMARY KEY (id),
  CONSTRAINT passport_stamps_unique UNIQUE (user_id, exhibitor_id)
);

-- 10. Crear tabla de órdenes/pedidos
CREATE TABLE IF NOT EXISTS public.orders (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  items jsonb NOT NULL,
  total_amount numeric NOT NULL,
  payment_method text,
  delivery_method text CHECK (delivery_method = ANY (ARRAY['envio'::text, 'recoger'::text])),
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'paid'::text, 'shipped'::text, 'completed'::text, 'cancelled'::text])),
  payment_id_mp text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT orders_pkey PRIMARY KEY (id)
);

-- 11. Habilitar Row Level Security (RLS) en las nuevas tablas
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contest_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.passport_stamps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- 12. Políticas de seguridad para promotions
CREATE POLICY "Anyone can read active promotions" ON public.promotions
  FOR SELECT USING (is_active = true);

CREATE POLICY "Exhibitors can manage their own promotions" ON public.promotions
  FOR ALL USING (
    auth.uid() = exhibitor_id OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- 13. Políticas de seguridad para contests
CREATE POLICY "Anyone can read active contests" ON public.contests
  FOR SELECT USING (is_active = true);

CREATE POLICY "Only admins can manage contests" ON public.contests
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- 14. Políticas de seguridad para contest_entries
CREATE POLICY "Anyone can read contest entries" ON public.contest_entries
  FOR SELECT USING (true);

CREATE POLICY "Only admins can manage contest entries" ON public.contest_entries
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- 15. Políticas de seguridad para votes
CREATE POLICY "Users can read their own votes" ON public.votes
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own votes" ON public.votes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 16. Políticas de seguridad para passport_stamps
CREATE POLICY "Users can read their own stamps" ON public.passport_stamps
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users and exhibitors can create stamps" ON public.passport_stamps
  FOR INSERT WITH CHECK (
    auth.uid() = user_id OR
    EXISTS (SELECT 1 FROM public.exhibitor_details WHERE profile_id = auth.uid())
  );

-- 17. Políticas de seguridad para orders
CREATE POLICY "Users can read their own orders" ON public.orders
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own orders" ON public.orders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can manage all orders" ON public.orders
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- 18. Índices para mejorar performance
CREATE INDEX IF NOT EXISTS idx_promotions_exhibitor ON public.promotions(exhibitor_id);
CREATE INDEX IF NOT EXISTS idx_promotions_active ON public.promotions(is_active, valid_until);
CREATE INDEX IF NOT EXISTS idx_contest_entries_contest ON public.contest_entries(contest_id);
CREATE INDEX IF NOT EXISTS idx_votes_user ON public.votes(user_id);
CREATE INDEX IF NOT EXISTS idx_votes_contest ON public.votes(contest_id);
CREATE INDEX IF NOT EXISTS idx_passport_stamps_user ON public.passport_stamps(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_user ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_schedule_items_time ON public.schedule_items(start_time);

-- 19. Triggers para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_promotions_updated_at BEFORE UPDATE ON public.promotions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contests_updated_at BEFORE UPDATE ON public.contests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 20. Habilitar Realtime para actualizaciones en vivo (opcional)
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.schedule_items;
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.contests;
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.contest_entries;
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.promotions;
