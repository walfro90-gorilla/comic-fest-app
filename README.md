# 🎭 Comic Fest App

**Tu Compañero Digital Oficial para Comic Fest en Ciudad Juárez, Chihuahua**

Una app móvil completa para festivales de cómics estilo Comic-Con, con arquitectura **offline-first** que permite funcionar sin conexión a internet.

## 🌟 Características

### Para Asistentes (Fans)
- 🎫 **Boletaje Digital**: Compra y gestión de boletos con QR único
- 📅 **Agenda Interactiva**: Lista completa de paneles, firmas y torneos
- ⭐ **Sistema de Puntos**: Acumula puntos por participar y canjéalos por premios
- 🗳️ **Votación de Concursos**: Vota en concursos de cosplay y dibujo
- 🛍️ **Tienda Oficial**: Compra mercancía exclusiva
- 🎁 **Promociones Exclusivas**: Accede a ofertas flash y descuentos
- 🗺️ **Mapa Interactivo**: Navega por el centro de convenciones
- 🤖 **Comi-Bot IA**: Asistente virtual powered by Gemini

### Para Expositores
- 🏪 Gestión de perfil de stand
- 📢 Publicar promociones flash
- 📊 Ver estadísticas de visitas
- 🎯 Interactuar con asistentes mediante QR

### Para Artistas/Invitados
- 📆 Gestionar agenda de firmas y paneles
- 🎨 Promocionar trabajo
- 👥 Conectar con fans

### Para Organizadores (Admin)
- 🎛️ Control total del contenido
- ✅ Validar entradas con escáner QR
- 📈 Analytics en tiempo real
- 🔧 Gestión de todos los módulos

## 🏗️ Arquitectura

### Offline-First
La app está diseñada para funcionar **completamente sin conexión**:
- ✅ Todos los datos críticos se guardan localmente primero
- 🔄 Sincronización automática cuando hay conexión
- 📱 El QR del boleto funciona 100% offline
- 📊 Cola de operaciones pendientes para sincronizar

### Stack Tecnológico
- **Flutter/Dart**: Framework multiplataforma
- **Supabase**: Backend (Auth, Database, Realtime, Storage)
- **Hive**: Base de datos local offline
- **Secure Storage**: Almacenamiento encriptado de QR
- **MercadoPago**: Procesamiento de pagos
- **Google Maps**: Mapas interactivos
- **Gemini API**: Chatbot IA (próximamente)

### Estructura de Datos
```
lib/
├── core/
│   ├── connectivity_service.dart   # Monitoreo de conexión
│   ├── supabase_service.dart       # Wrapper de Supabase
│   └── sync_queue.dart             # Cola de sincronización
├── models/
│   ├── user_model.dart
│   ├── ticket_model.dart
│   ├── event_model.dart
│   ├── product_model.dart
│   └── points_transaction_model.dart
├── services/
│   ├── user_service.dart
│   ├── event_service.dart
│   ├── ticket_service.dart
│   └── points_service.dart
├── screens/
│   ├── auth/                       # Login y registro
│   ├── home/                       # Dashboard y navegación
│   ├── events/                     # Agenda
│   ├── map/                        # Mapa
│   ├── shop/                       # Tienda
│   └── profile/                    # Perfil
└── widgets/                        # Componentes reutilizables
```

## 🚀 Instalación

### Prerrequisitos
- Flutter SDK 3.6.0 o superior
- Dart SDK 3.6.0 o superior
- Cuenta de Supabase
- (Opcional) Google Cloud Console para Google Sign-In
- (Opcional) MercadoPago API keys

### Pasos

1. **Clonar e instalar dependencias**
```bash
flutter pub get
```

2. **Generar adaptadores de Hive**
```bash
dart run build_runner build --delete-conflicting-outputs
```

3. **Configurar Supabase**
   - Sigue las instrucciones en `SUPABASE_SETUP.md`
   - Crea las tablas necesarias
   - Obtén tu Project URL y Anon Key

4. **Configurar credenciales**

Actualiza en `lib/main.dart` antes de `runApp()`:
```dart
await SupabaseService.initialize(
  supabaseUrl: 'TU_SUPABASE_URL',
  supabaseAnonKey: 'TU_SUPABASE_ANON_KEY',
);
```

5. **Ejecutar la app**
```bash
flutter run
```

## 🎨 Diseño UI/UX

### Paleta de Colores
- **Primario**: Púrpura vibrante (#8B5CF6) - Creatividad y energía
- **Secundario**: Cian eléctrico (#06B6D4) - Tecnología
- **Acento**: Amarillo neón (#FBBF24) - Llamadas a acción

### Principios de Diseño
- ✨ Interfaz moderna y vibrante (estilo comic/pop)
- 🎯 Diseño limpio con espaciado generoso
- 🌓 Soporte completo de modo oscuro
- 📱 Componentes con esquinas redondeadas
- 🎭 Sin Material Design tradicional

## 📋 Roadmap

### Fase 1: MVP ✅
- [x] Autenticación y perfiles
- [x] Estructura de navegación
- [x] Sistema offline-first
- [x] Lista de eventos
- [x] UI/UX base

### Fase 2: Boletaje 🚧
- [ ] Integración MercadoPago
- [ ] Generación de QR seguro
- [ ] Validación de boletos
- [ ] Vista para staff

### Fase 3: Gamificación 📅
- [ ] Sistema de puntos completo
- [ ] Escaneo de QRs
- [ ] Pasaporte virtual
- [ ] Recompensas

### Fase 4: Comercio 📅
- [ ] Catálogo de productos
- [ ] Carrito de compras
- [ ] Integración de pagos
- [ ] Historial de pedidos

### Fase 5: Social y Extras 📅
- [ ] Votación de concursos
- [ ] Feed de promociones
- [ ] Mapa con Google Maps
- [ ] Comi-Bot (Gemini AI)

## 🔒 Seguridad

- 🔐 Autenticación via Supabase (Email, Google, Apple)
- 🎫 QR encriptados almacenados en Secure Storage
- 🛡️ Row Level Security (RLS) en todas las tablas
- 🔒 Validación server-side de transacciones críticas
- 🚫 Rate limiting para prevenir abuso

## 📱 Plataformas Soportadas

- ✅ Android (API 21+)
- ✅ iOS (12.0+)
- 🔜 Web (próximamente)

## 🤝 Contribuir

Este es un proyecto privado para Comic Fest. Para solicitudes de colaboración, contacta al equipo organizador.

## 📄 Licencia

© 2025 Comic Fest. Todos los derechos reservados.

## 📞 Soporte

Para soporte técnico o preguntas:
- 📧 Email: support@comicfest.mx
- 🌐 Web: https://comicfest.mx
- 📱 Twitter: @ComicFestJuarez

---

**¡Desarrollado con ❤️ para la comunidad geek de Ciudad Juárez!**
