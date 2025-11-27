# 🎫 MVP FASE 1: Sistema de Tickets + Mercado Pago

## 🎯 Objetivo
Implementar un sistema completo de venta de boletos con integración de Mercado Pago para lanzar la app en Play Store y comenzar a vender entradas anticipadas.

---

## 📋 Plan de Implementación

### **1. Backend: Base de Datos y Tablas** ✅
- [x] Crear tabla `ticket_types` con tipos (VIP, General, Early Bird)
- [x] Crear tabla `orders` para gestionar compras (ya existía, actualizada)
- [x] Crear tabla `order_items` para items de cada orden
- [x] Crear tabla `payments` para tracking de pagos de Mercado Pago
- [x] Agregar RLS (Row Level Security) a todas las tablas
- [x] Crear índices para optimización de queries
- [x] Script SQL de migración: `11_tickets_payment_system.sql`

### **2. Backend: Supabase Edge Functions** 🔧
- [ ] Edge Function: `create-payment-preference` (crea preferencia en Mercado Pago)
- [ ] Edge Function: `handle-payment-webhook` (recibe notificaciones de pago)
- [ ] Edge Function: `validate-ticket` (valida QR codes en el evento)
- [ ] Configurar secrets en Supabase:
  - `MERCADOPAGO_ACCESS_TOKEN`
  - `MERCADOPAGO_PUBLIC_KEY`

### **3. Frontend: Modelos de Datos** 📦
- [x] `TicketModel` - Ya existe
- [x] `OrderModel` - Actualizado con campos nuevos
- [x] `TicketTypeModel` - Creado
- [x] `PaymentModel` - Creado
- [x] Métodos `toJson()`, `fromJson()`, `copyWith()` implementados

### **4. Frontend: Servicios** 🔌
- [x] `TicketService` - Actualizado con métodos para tipos
  - [x] `getAvailableTicketTypes()` - Tipos de tickets a la venta
  - [x] `getTicketTypeById()` - Detalles de un tipo
  - [x] `getUserTickets()` - Tickets del usuario (ya existía)
- [x] `OrderService` - Creado completamente
  - [x] `createTicketOrder()` - Crear nueva orden
  - [x] `getOrderById()` - Obtener orden
  - [x] `getUserOrders()` - Historial de órdenes
  - [x] `updateOrderStatus()` - Actualizar estado (pending → paid)
  - [x] `createPayment()` - Crear registro de pago
  - [x] `getPaymentByOrderId()` - Obtener pago de una orden
- [ ] `PaymentService` - Pendiente integración con Mercado Pago
  - [ ] `createPaymentPreference()` - Llamar edge function
  - [ ] `checkPaymentStatus()` - Consultar estado de pago

### **5. Frontend: Pantallas** 🖼️
- [x] **BuyTicketsScreen** - Tienda de boletos ✅
  - [x] Lista de tipos de tickets desde Supabase
  - [x] Cards con tipo, precio, descripción, beneficios
  - [x] Selector de cantidad (+/-)
  - [x] Carrito funcional con badge
  - [x] Botón flotante "Pagar"
  - [x] Indicador de stock (Early Bird, últimos, agotado)
  
- [x] **CheckoutScreen** - Pantalla de pago ✅
  - [x] Resumen de la orden con items
  - [x] Formulario de datos del comprador (nombre*, email*, teléfono)
  - [x] Validaciones de formulario
  - [x] Total a pagar destacado
  - [x] Botón "Pagar" (crea orden en Supabase)
  - [x] Loading states y dialogo de éxito
  - [ ] Integración con Mercado Pago (pendiente)
  
- [ ] **TicketsListScreen** - Actualizar para mostrar por estados
  - [ ] Filtros por estado (pending, paid, used)
  - [ ] Cards mejoradas con más info
  
- [ ] **TicketDetailScreen** - Ya existe, revisar
  - [ ] Verificar QR code display
  - [ ] Agregar más información del ticket

### **6. Configuración y Dependencias** ⚙️
- [x] `qr_flutter` - Ya instalado ✅
- [x] `url_launcher` - Ya instalado ✅
- [ ] Agregar dependencia `share_plus` para compartir tickets
- [ ] Configurar deep links para volver de Mercado Pago (cuando se integre MP)

### **7. Navegación y UX** 🧭
- [ ] Agregar sección "Boletos" en el menú principal
- [ ] Badge con número de tickets comprados
- [ ] Ruta de navegación: Home → Comprar → Checkout → Mis Boletos
- [ ] Mensajes de confirmación post-compra
- [ ] Manejo de errores (pago rechazado, timeout, etc.)

### **8. Admin Panel: Gestión de Tickets** 👨‍💼
- [ ] Tab "Tickets" en Admin Panel
  - Lista de todos los tickets vendidos
  - Filtros por tipo, estado, usuario
  - Búsqueda por email/nombre
  - Botón para marcar como "usado"
  - Estadísticas de ventas
  
- [ ] Tab "Órdenes" en Admin Panel
  - Lista de todas las órdenes
  - Estados de pago
  - Filtros por fecha, estado
  - Detalles de cada orden

### **9. Testing y Validación** 🧪
- [ ] Probar flujo completo de compra (sandbox Mercado Pago)
- [ ] Verificar generación de QR codes
- [ ] Validar RLS (usuarios solo ven sus tickets)
- [ ] Probar webhooks de Mercado Pago
- [ ] Testing de casos borde (pago fallido, timeout, etc.)

### **10. Datos de Prueba (Seed Data)** 🌱
- [ ] Crear tipos de tickets en `SeedService`:
  - Early Bird (limitado, descuento)
  - General Admission
  - VIP (beneficios exclusivos)
- [ ] Agregar descripciones y precios
- [ ] Poblar tabla de tickets disponibles

---

## 🔐 Seguridad y RLS

### Políticas de Row Level Security:
```sql
-- Tickets: usuarios solo ven sus propios tickets
-- Orders: usuarios solo ven sus propias órdenes
-- Payments: usuarios solo ven sus propios pagos
-- Admins: acceso completo a todo
```

---

## 💰 Estructura de Precios (Ejemplo)

| Tipo | Precio | Stock | Beneficios |
|------|--------|-------|------------|
| **Early Bird** | $299 MXN | 100 | Precio especial, acceso prioritario |
| **General** | $499 MXN | 500 | Acceso completo al evento |
| **VIP** | $999 MXN | 50 | Acceso VIP, meet & greet, mercancía exclusiva |

---

## 🚀 Orden de Ejecución

1. ✅ Crear este documento de plan
2. 🔧 Backend: SQL migrations (tablas + RLS)
3. 🔧 Backend: Edge Functions de Mercado Pago
4. 📱 Frontend: Modelos y servicios
5. 📱 Frontend: Pantallas de UI
6. 🌱 Seed data de tickets
7. 🧪 Testing completo
8. 🎉 Deploy y lanzamiento

---

## 📝 Notas Importantes

- **Mercado Pago Sandbox**: Usar credenciales de prueba primero
- **Deep Links**: Configurar para volver de checkout externo
- **QR Codes**: Usar UUID único + hash de seguridad
- **Estados de Ticket**: `pending` → `paid` → `used`
- **Idempotencia**: Evitar doble cobro con `order_id` único

---

## ⏱️ Tiempo Estimado
**Total: 4-6 horas** (dependiendo de configuración de Mercado Pago)

---

**Última actualización:** 2025-01-15
