# Comic Fest App - Arquitectura Offline-First

## 🎯 Visión General
App oficial del festival Comic Fest en Ciudad Juárez, Chihuahua. "Tu Compañero Digital Oficial" para el evento estilo Comic-Con.

**Filosofía Clave**: Offline-First - La app debe funcionar completamente sin conexión, sincronizando datos cuando hay señal disponible.

## 🎭 Roles de Usuario

### 1. Asistente (Fan) - Usuario Principal
- Comprar y gestionar boletos digitales con QR
- Ver agenda del evento y crear calendario personal
- Participar en votaciones de concursos
- Acumular y canjear puntos por promociones
- Comprar mercancía oficial
- Acceder al chatbot IA "Comi-Bot"
- Ver mapa interactivo del evento

### 2. Expositor (Vendedor)
- Crear y gestionar perfil de stand
- Publicar promociones flash
- Escanear QRs de asistentes para dar puntos
- Ver estadísticas de visitas

### 3. Artista/Invitado (Talento)
- Gestionar agenda de firmas y paneles
- Promocionar trabajo
- Interactuar con fans

### 4. Organizador (Admin)
- Control total de contenido
- Escanear QRs para validar entradas
- Ver analytics en tiempo real
- Gestionar todos los módulos

## 📦 Módulos Principales

### Módulo 1: Autenticación y Perfil (Core)
**Prioridad**: CRÍTICA
- Supabase Auth (Email, Google, Apple)
- Perfil de usuario con foto, biografía, redes sociales
- Gestión de roles (asistente/expositor/artista/admin)
- **Offline**: Caché de perfil local, sincronización bidireccional

**Tecnologías**: Supabase Auth, shared_preferences para caché

### Módulo 2: Boletaje Digital
**Prioridad**: CRÍTICA
- Compra de boletos vía MercadoPago
- Generación de QR único por boleto
- **Offline-First CRÍTICO**: QR debe estar disponible sin conexión
- Validación de QR por staff (app separada o vista especial)
- Historial de compras

**Tecnologías**: 
- Supabase Edge Functions para procesamiento de pagos
- QR local encriptado
- Sincronización de estado de boleto

### Módulo 3: Agenda del Evento
**Prioridad**: ALTA
- Lista completa de paneles, firmas, torneos, actividades
- Filtros por categoría, artista, hora
- Agregar eventos a "Mi Agenda"
- Notificaciones antes de eventos favoritos
- **Offline**: Caché completo de agenda, sincronización periódica

**Tecnologías**: Supabase Realtime, local database (Hive)

### Módulo 4: Sistema de Puntos (Gamificación)
**Prioridad**: ALTA
- Acumular puntos por:
  - Check-in en paneles (escanear QR)
  - Visitar stands de expositores
  - Participar en trivias
  - Comprar mercancía
- Canjear puntos por:
  - Descuentos en tienda
  - Mercancía exclusiva
  - Fast-Pass para firmas
- **Offline**: Cola de transacciones, sincronización al conectarse

**Tecnologías**: Supabase Edge Functions (anti-trampas), cola local

### Módulo 5: Votación de Concursos
**Prioridad**: MEDIA
- Ver participantes (Cosplay, Dibujo, etc.)
- Sistema de votación (1 voto por usuario por categoría)
- Resultados en tiempo real
- **Offline**: Votos en cola, validación al sincronizar

**Tecnologías**: Supabase Realtime, validación server-side

### Módulo 6: Tienda de Mercancía
**Prioridad**: MEDIA
- Catálogo de productos oficiales
- Carrito de compras
- Integración MercadoPago
- Opciones: Envío a domicilio o "Recoger en Stand"
- **Offline**: Catálogo en caché, compras en cola

### Módulo 7: Promociones y Pasaporte Virtual
**Prioridad**: MEDIA
- Feed de promociones de expositores
- Ofertas flash con countdown
- "Pasaporte Virtual": Escanear QRs de 10 stands → premio
- **Offline**: Promociones en caché, progreso de pasaporte local

### Módulo 8: Mapa Interactivo
**Prioridad**: MEDIA-BAJA
- Mapa del centro de convenciones
- Pines para stands, baños, escenarios, salidas
- Navegación básica
- **Offline**: Mapa estático con pines pre-cargados

**Tecnologías**: Google Maps API (o mapa estático custom)

### Módulo 9: Comi-Bot (Asistente IA)
**Prioridad**: BAJA (Feature Premium)
- Chatbot con Gemini API
- Entrenado con información del evento
- Responde: horarios, ubicaciones, reglas, FAQ
- **Offline**: Respuestas básicas pre-cargadas, IA solo online

**Tecnologías**: Gemini API

## 🗄️ Arquitectura de Datos (Supabase)

### Tablas Principales

#### `users`
```
- id (uuid, PK)
- email (text)
- full_name (text)
- avatar_url (text)
- bio (text)
- role (enum: asistente/expositor/artista/admin)
- points (integer)
- created_at (timestamp)
- updated_at (timestamp)
```

#### `tickets`
```
- id (uuid, PK)
- user_id (uuid, FK)
- ticket_type (text)
- qr_code (text, encrypted)
- purchase_date (timestamp)
- price (numeric)
- status (enum: active/used/cancelled)
- validated_at (timestamp, nullable)
- validated_by (uuid, FK, nullable)
```

#### `events`
```
- id (uuid, PK)
- title (text)
- description (text)
- category (enum: panel/firma/torneo/actividad)
- start_time (timestamp)
- end_time (timestamp)
- location (text)
- featured_artists (jsonb)
- image_url (text)
```

#### `exhibitors`
```
- id (uuid, PK)
- user_id (uuid, FK)
- stand_name (text)
- stand_number (text)
- description (text)
- logo_url (text)
- location_x (numeric)
- location_y (numeric)
```

#### `products`
```
- id (uuid, PK)
- name (text)
- description (text)
- price (numeric)
- points_price (integer, nullable)
- image_url (text)
- stock (integer)
- is_exclusive (boolean)
```

#### `orders`
```
- id (uuid, PK)
- user_id (uuid, FK)
- items (jsonb)
- total_amount (numeric)
- payment_method (text)
- delivery_method (enum: envio/recoger)
- status (enum: pending/paid/shipped/completed)
- created_at (timestamp)
```

#### `contests`
```
- id (uuid, PK)
- name (text)
- category (text)
- description (text)
- voting_start (timestamp)
- voting_end (timestamp)
```

#### `contest_entries`
```
- id (uuid, PK)
- contest_id (uuid, FK)
- participant_name (text)
- image_url (text)
- votes (integer)
```

#### `votes`
```
- id (uuid, PK)
- user_id (uuid, FK)
- contest_id (uuid, FK)
- entry_id (uuid, FK)
- created_at (timestamp)
```

#### `promotions`
```
- id (uuid, PK)
- exhibitor_id (uuid, FK)
- title (text)
- description (text)
- discount_percent (integer)
- valid_until (timestamp)
- is_flash (boolean)
```

#### `points_transactions`
```
- id (uuid, PK)
- user_id (uuid, FK)
- amount (integer)
- type (enum: earn/spend)
- reason (text)
- created_at (timestamp)
- synced (boolean)
```

#### `passport_stamps`
```
- id (uuid, PK)
- user_id (uuid, FK)
- exhibitor_id (uuid, FK)
- stamped_at (timestamp)
```

## 🔄 Estrategia Offline-First

### Principios de Diseño
1. **Local-First Storage**: Todos los datos se guardan primero localmente
2. **Sync Queue**: Cola de operaciones pendientes de sincronización
3. **Conflict Resolution**: Estrategias para resolver conflictos (last-write-wins para la mayoría)
4. **Critical Path**: Boletaje QR debe funcionar 100% offline

### Tecnologías de Caché Local
- **Hive**: Base de datos local para entidades grandes (agenda, productos, etc.)
- **shared_preferences**: Configuración y datos pequeños
- **Secure Storage**: QR codes encriptados de boletos

### Proceso de Sincronización
1. **Al abrir app**: Intentar sincronizar datos críticos
2. **Background Periodic**: Cada 15 minutos si hay conexión
3. **User-Triggered**: Pull-to-refresh en listas
4. **Queue Processing**: Enviar operaciones pendientes (votos, compras, puntos)

### Indicadores UI
- Badge de "Modo Offline"
- Indicador de sincronización en progreso
- Notificación cuando datos están desactualizados

## 🎨 Diseño UI/UX

### Paleta de Colores (Temática Comic/Pop)
- **Primario**: Púrpura vibrante (#8B5CF6) - energía y creatividad
- **Secundario**: Cian eléctrico (#06B6D4) - tecnología
- **Acento**: Amarillo neón (#FBBF24) - llamadas a acción
- **Fondo Claro**: #FAFAFA
- **Fondo Oscuro**: #0F172A
- **Texto**: Alto contraste

### Tipografía
- **Títulos**: Montserrat Bold (estilo comic moderno)
- **Cuerpo**: Inter Regular (legibilidad)
- **Etiquetas**: Inter Medium

### Componentes Clave
- Cards con sombras suaves y esquinas redondeadas
- Bottom sheets en lugar de dialogs
- Animaciones de transición fluidas
- Tab bar inferior para navegación principal
- Floating Action Button para acciones rápidas (escanear QR)

### Navegación Principal (Bottom Tab)
1. **Inicio**: Dashboard con agenda destacada, puntos, promociones
2. **Agenda**: Lista completa de eventos
3. **Mapa**: Plano interactivo
4. **Tienda**: Catálogo de productos
5. **Perfil**: Usuario, boletos, configuración

## 🔐 Seguridad

### Boletos
- QR encriptado con clave única por evento
- Validación requiere conexión a internet (staff)
- Prevención de screenshots falsos (marca de agua con timestamp)

### Transacciones
- Todas las operaciones de puntos y pagos procesadas server-side
- Edge Functions validan permisos y lógica de negocio
- Rate limiting para prevenir abuso

### Sincronización
- HTTPS obligatorio
- Tokens JWT con expiración corta
- Refresh tokens en Secure Storage

## 📱 Implementación por Fases

### Fase 1: MVP (Semana 1-2)
- [ ] Autenticación y perfiles básicos
- [ ] Estructura de navegación
- [ ] Caché offline básico
- [ ] Lista de agenda (read-only)
- [ ] Sistema de temas

### Fase 2: Boletaje (Semana 2-3)
- [ ] Integración MercadoPago
- [ ] Generación de QR
- [ ] Almacenamiento seguro offline
- [ ] Vista de validación para staff

### Fase 3: Gamificación (Semana 3-4)
- [ ] Sistema de puntos
- [ ] Cola de transacciones offline
- [ ] Escaneo de QRs para check-in
- [ ] Pasaporte virtual

### Fase 4: Comercio (Semana 4-5)
- [ ] Catálogo de productos
- [ ] Carrito de compras
- [ ] Integración de pagos
- [ ] Historial de pedidos

### Fase 5: Social y Extras (Semana 5-6)
- [ ] Votación de concursos
- [ ] Feed de promociones
- [ ] Mapa interactivo
- [ ] Comi-Bot (si tiempo permite)

## 🧪 Testing y QA
- Test de conectividad intermitente
- Validación de sincronización bidireccional
- Test de carga (muchos usuarios simultáneos)
- Seguridad del QR
- UX en diferentes tamaños de pantalla

## 🚀 Deployment
- Flutter build para Android/iOS
- Supabase Edge Functions deployed
- Configuración de entorno (dev/prod)
- App Store y Google Play setup

---

**Estado Actual**: Fase 1 - Inicio de implementación
**Última Actualización**: Hoy
