# Configuración de Supabase para Comic Fest

## 1. Crear Proyecto en Supabase

1. Ve a [supabase.com](https://supabase.com) y crea una cuenta
2. Crea un nuevo proyecto llamado "comic-fest"
3. Anota tu **Project URL** y **Anon Key**

## 2. Configurar en la App

Abre `lib/core/supabase_service.dart` y actualiza las constantes:

```dart
static const String supabaseUrl = 'TU_SUPABASE_URL';
static const String supabaseAnonKey = 'TU_SUPABASE_ANON_KEY';
```

O inicializa en `main.dart`:

```dart
await SupabaseService.initialize(
  supabaseUrl: 'TU_SUPABASE_URL',
  supabaseAnonKey: 'TU_SUPABASE_ANON_KEY',
);
```

## 3. Crear Tablas en Supabase

Ejecuta estos scripts SQL en el SQL Editor de Supabase:

### Tabla: users
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  role TEXT NOT NULL DEFAULT 'asistente',
  points INTEGER NOT NULL DEFAULT 0,
  social_links JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can read their own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own data" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own data" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);
```

### Tabla: tickets
```sql
CREATE TABLE tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  ticket_type TEXT NOT NULL,
  qr_code TEXT NOT NULL UNIQUE,
  purchase_date TIMESTAMP WITH TIME ZONE NOT NULL,
  price NUMERIC(10,2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  validated_at TIMESTAMP WITH TIME ZONE,
  validated_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own tickets" ON tickets
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own tickets" ON tickets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Staff can validate tickets" ON tickets
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'staff'))
  );
```

### Tabla: events
```sql
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE NOT NULL,
  location TEXT NOT NULL,
  featured_artists TEXT[] DEFAULT '{}',
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read events" ON events
  FOR SELECT USING (true);

CREATE POLICY "Only admins can manage events" ON events
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

### Tabla: products
```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  price NUMERIC(10,2) NOT NULL,
  points_price INTEGER,
  image_url TEXT NOT NULL,
  stock INTEGER NOT NULL DEFAULT 0,
  is_exclusive BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read products" ON products
  FOR SELECT USING (true);

CREATE POLICY "Only admins can manage products" ON products
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

### Tabla: points_transactions
```sql
CREATE TABLE points_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  type TEXT NOT NULL,
  reason TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  synced BOOLEAN DEFAULT true
);

ALTER TABLE points_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own transactions" ON points_transactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own transactions" ON points_transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

## 4. Configurar Storage (Opcional)

Para fotos de perfil y eventos:

1. Ve a Storage en el dashboard de Supabase
2. Crea un bucket llamado `avatars` (público)
3. Crea un bucket llamado `events` (público)
4. Crea un bucket llamado `products` (público)

## 5. Habilitar Email Auth

1. Ve a Authentication > Providers
2. Habilita Email provider
3. Configura las plantillas de email

## 6. Habilitar Google Auth (Opcional)

1. Ve a Authentication > Providers
2. Habilita Google provider
3. Configura el OAuth Client ID de Google Cloud Console
4. Agrega la URL de callback de Supabase

## 7. Edge Functions para Pagos (MercadoPago)

Próximamente: Scripts para crear Edge Functions que manejen:
- Procesamiento de pagos con MercadoPago
- Validación de transacciones de puntos
- Webhooks de pagos

## 8. Realtime (Opcional)

Para actualizaciones en tiempo real de eventos y votaciones:

```sql
-- Habilitar realtime en las tablas necesarias
ALTER PUBLICATION supabase_realtime ADD TABLE events;
ALTER PUBLICATION supabase_realtime ADD TABLE contests;
```

## Notas Importantes

- La app está diseñada para funcionar **offline-first**
- Los datos se sincronizan automáticamente cuando hay conexión
- El QR del boleto se almacena de forma segura localmente
- Las transacciones de puntos usan una cola de sincronización
