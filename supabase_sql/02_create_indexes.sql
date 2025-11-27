-- ============================================================================
-- COMIC FEST - ÍNDICES PARA MEJORAR PERFORMANCE
-- ============================================================================
-- Ejecuta este script DESPUÉS de crear las tablas
-- ============================================================================

-- Índices para profiles
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_points ON public.profiles(points DESC);

-- Índices para tickets
CREATE INDEX IF NOT EXISTS idx_tickets_user ON public.tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_tickets_payment_status ON public.tickets(payment_status);
CREATE INDEX IF NOT EXISTS idx_tickets_qr_code ON public.tickets(qr_code_data);
CREATE INDEX IF NOT EXISTS idx_tickets_validated ON public.tickets(is_validated);

-- Índices para schedule_items
CREATE INDEX IF NOT EXISTS idx_schedule_start_time ON public.schedule_items(start_time);
CREATE INDEX IF NOT EXISTS idx_schedule_active ON public.schedule_items(is_active);
CREATE INDEX IF NOT EXISTS idx_schedule_category ON public.schedule_items(category);
CREATE INDEX IF NOT EXISTS idx_schedule_location ON public.schedule_items(location_id);
CREATE INDEX IF NOT EXISTS idx_schedule_artist ON public.schedule_items(artist_id);

-- Índices para products
CREATE INDEX IF NOT EXISTS idx_products_exclusive ON public.products(is_exclusive);
CREATE INDEX IF NOT EXISTS idx_products_stock ON public.products(stock);
CREATE INDEX IF NOT EXISTS idx_products_seller ON public.products(seller_id);
CREATE INDEX IF NOT EXISTS idx_products_active ON public.products(is_active);

-- Índices para points_log
CREATE INDEX IF NOT EXISTS idx_points_log_user ON public.points_log(user_id);
CREATE INDEX IF NOT EXISTS idx_points_log_created ON public.points_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_points_log_type ON public.points_log(type);

-- Índices para promotions
CREATE INDEX IF NOT EXISTS idx_promotions_exhibitor ON public.promotions(exhibitor_id);
CREATE INDEX IF NOT EXISTS idx_promotions_active ON public.promotions(is_active, valid_until);

-- Índices para contests
CREATE INDEX IF NOT EXISTS idx_contests_active ON public.contests(is_active);
CREATE INDEX IF NOT EXISTS idx_contests_dates ON public.contests(voting_start, voting_end);

-- Índices para contest_entries
CREATE INDEX IF NOT EXISTS idx_contest_entries_contest ON public.contest_entries(contest_id);
CREATE INDEX IF NOT EXISTS idx_contest_entries_votes ON public.contest_entries(votes DESC);

-- Índices para votes
CREATE INDEX IF NOT EXISTS idx_votes_user ON public.votes(user_id);
CREATE INDEX IF NOT EXISTS idx_votes_contest ON public.votes(contest_id);
CREATE INDEX IF NOT EXISTS idx_votes_entry ON public.votes(entry_id);

-- Índices para passport_stamps
CREATE INDEX IF NOT EXISTS idx_passport_stamps_user ON public.passport_stamps(user_id);
CREATE INDEX IF NOT EXISTS idx_passport_stamps_exhibitor ON public.passport_stamps(exhibitor_id);

-- Índices para orders
CREATE INDEX IF NOT EXISTS idx_orders_user ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created ON public.orders(created_at DESC);
