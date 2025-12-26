# Instrucciones para el Agente AI - Comic Fest Admin Panel

Estas instrucciones son para crear un panel de administración moderno y funcional utilizando **Next.js (App Router)** y **Supabase** para el proyecto "Comic Fest".

## 1. Descripción del Proyecto
Crear un **Dashboard Administrativo** que permita gestionar los datos de la aplicación móvil "Comic Fest". La aplicación conecta a una base de datos Supabase ya existente.

**Tech Stack:**
*   **Framework:** Next.js 14+ (App Router)
*   **Lenguaje:** TypeScript
*   **Estilos:** Tailwind CSS (Diseño moderno, "Dark Mode" por defecto o elegante)
*   **Iconos:** Lucide React
*   **Base de Datos / Auth:** Supabase (`@supabase/supabase-js`, `@supabase/ssr`)
*   **Componentes UI:** shadcn/ui (recomendado para desarrollo rápido y estético)

## 2. Configuración de Conexión (Supabase)
El agente debe configurar el cliente de Supabase para Next.js.

**Variables de Entorno (.env.local):**
```bash
NEXT_PUBLIC_SUPABASE_URL=TU_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY=TU_SUPABASE_ANON_KEY
```
*Nota: El agente debe solicitar estas credenciales al usuario si no están proveídas.*

## 3. Autenticación y Seguridad
El panel debe ser **exclusivo para administradores**.

### Requisitos de Login:
1.  **Página de Login (`/login`)**:
    *   Formulario de **Email/Password**.
    *   Botón de **Login con Google** (OAuth).
2.  **Protección de Rutas (Middleware)**:
    *   Todas las rutas bajo `/admin/*` deben estar protegidas.
    *   **Verificación de Rol**: Al iniciar sesión, verificar en la tabla `public.profiles` si el usuario tiene `role = 'admin'` o `role = 'staff'`.
    *   Si el usuario no es admin, mostrar mensaje de "Acceso Denegado" y cerrar sesión.

## 4. Funcionalidades del Panel (Admin Dashboard)

El panel debe tener un Sidebar de navegación con las siguientes secciones:

### A. Dashboard General (`/admin`)
*   **Stats Cards**:
    *   Total de Usuarios Registrados.
    *   Entradas (Tickets) Vendidas.
    *   Total de Ventas (MXN).
    *   Usuarios activos recientemente.

### B. Gestión de Usuarios (`/admin/users`)
*   **Tabla de Usuarios**: Listar usuarios desde `public.profiles`.
*   **Columnas**: Avatar, Username, Email (join con `auth.users` si es posible, o mostrar info de perfil), Rol, Puntos.
*   **Acciones**:
    *   Editar Rol (Promover a Staff/Admin).
    *   Ver historial de puntos (`points_log`).

### C. Gestión de Contenido (Evento)
*   **Agenda / Cronograma (`/admin/schedule`)**:
    *   CRUD de `schedule_items`.
    *   Campos: Título, Hora Inicio/Fin, Lugar (`location_id`), Artista (`artist_id`), Categoría.
*   **Mapa / Lugares (`/admin/map`)**:
    *   CRUD de `map_points`.
    *   Gestionar coordenadas y tipo (Stand, Escenario, Baños).

### D. Tienda y Productos (`/admin/products`)
*   **Inventario**: CRUD de `products`.
*   **Campos**: Nombre, Precio, Stock, Imagen, Precio en Puntos.
*   **Pedidos**: Ver lista de `orders` y cambiar estatus (Pending -> Paid -> Completed).

### E. Gamificación (`/admin/gamification`)
*   **Logs**: Ver tabla `points_log` para auditar movimientos de puntos.
*   **Concursos**: Gestionar `contests` y ver `contest_entries` (Votos, Participantes).

## 5. Referencia del Esquema de Base de Datos
El agente debe basar sus consultas en este esquema existente:

```sql
-- TABLA DE PERFILES (Usuarios Extendidos)
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY, -- Link a auth.users
  role text DEFAULT 'attendee', -- 'admin', 'staff', 'attendee'
  username text,
  email text, -- A veces sincronizado, preferible usar auth
  points integer DEFAULT 0
);

-- ITEMS DE AGENDA
CREATE TABLE public.schedule_items (
  id uuid PRIMARY KEY,
  title text,
  start_time timestamptz,
  end_time timestamptz,
  category text, -- panel, firma, torneo...
  location_id uuid -- FK a map_points
);

-- PRODUCTOS
CREATE TABLE public.products (
  id uuid PRIMARY KEY,
  name text,
  price numeric,
  stock integer,
  image_url text
);

-- PEDIDOS
CREATE TABLE public.orders (
  id uuid PRIMARY KEY,
  user_id uuid, -- FK profiles
  total_amount numeric,
  status text -- pending, paid, completed
);
```

## 6. Instrucciones Adicionales para el Agente
1.  **UI/UX**: Usa una paleta de colores oscura ("Dark Mode") profesional, similar a la app móvil (Morados/Azules neon si aplica, o simplemente Slate/Zinc oscuro).
2.  **Data Fetching**: Usa Server Actions o React Query para traer los datos.
3.  **Bordes**: Maneja los errores de conexión a Supabase de forma elegante.

---
**Inicio**: Comienza creando la estructura del proyecto Next.js e instalando las dependencias de Supabase.



## 7. Database Schema
```sql
-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.comics (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  prompt text NOT NULL,
  image_url text,
  status text NOT NULL DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'completed'::text, 'failed'::text])),
  model_used text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT comics_pkey PRIMARY KEY (id),
  CONSTRAINT comics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
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
CREATE TABLE public.gamification_rules (
  action_key text NOT NULL,
  points_value integer NOT NULL,
  daily_limit integer,
  is_active boolean DEFAULT true,
  CONSTRAINT gamification_rules_pkey PRIMARY KEY (action_key)
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
  credits integer NOT NULL DEFAULT 0,
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
CREATE TABLE public.referrals (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  referrer_id uuid NOT NULL,
  referred_id uuid NOT NULL UNIQUE,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'completed'::text])),
  code_used text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT referrals_pkey PRIMARY KEY (id),
  CONSTRAINT referrals_referrer_id_fkey FOREIGN KEY (referrer_id) REFERENCES public.profiles(id),
  CONSTRAINT referrals_referred_id_fkey FOREIGN KEY (referred_id) REFERENCES public.profiles(id)
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
```