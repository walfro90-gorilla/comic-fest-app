# 🎫 Configuración de Mercado Pago - Comic Fest

## ✅ Archivos Creados

### 1. **SQL Script Corregido**
- `supabase_sql/16_mercadopago_webhook_fixed.sql`

### 2. **Supabase Edge Functions**
- `supabase/functions/create-payment-preference/index.ts`
- `supabase/functions/mercadopago-webhook/index.ts`

### 3. **Servicios Flutter Actualizados**
- `lib/services/mercadopago_service.dart` - Reescrito para usar Edge Functions
- `lib/screens/tickets/checkout_screen.dart` - Actualizado para usar el nuevo servicio

---

## 📋 Instrucciones de Configuración

### **PASO 1: Ejecutar SQL en Supabase**

1. Ve a tu proyecto Supabase: https://app.supabase.com
2. Abre el **SQL Editor**
3. Ejecuta el archivo: `supabase_sql/16_mercadopago_webhook_fixed.sql`

Este script crea:
- ✅ Tabla `webhook_logs` para debugging
- ✅ Funciones RPC para procesar webhooks
- ✅ Políticas de seguridad (RLS)

---

### **PASO 2: Desplegar Edge Functions**

**Requisito:** Tener instalado Supabase CLI
```bash
# Instalar Supabase CLI si no lo tienes
npm install -g supabase

# Login
supabase login

# Linkear tu proyecto (usa tu Project ID)
supabase link --project-ref tlzkddmquytddhdeqdmo
```

**Desplegar las funciones:**
```bash
# Desde la raíz del proyecto (/hologram/data/workspace/project)

# 1. Crear preferencia de pago
supabase functions deploy create-payment-preference

# 2. Webhook de Mercado Pago
supabase functions deploy mercadopago-webhook
```

---

### **PASO 3: Configurar Variables de Entorno en Supabase**

1. Ve a: **Settings** > **Edge Functions** > **Secrets**
2. Agrega estas variables:

```env
MERCADOPAGO_ACCESS_TOKEN=TEST-1234567890-abcdef  # Tu token de MP (sandbox o producción)
APP_URL=https://tu-app.com  # URL de tu app para deep links
```

**Cómo obtener el token:**
1. Ve a: https://www.mercadopago.com.mx/developers/panel/app
2. Crea o selecciona una aplicación
3. Copia el **Access Token** (usa **Sandbox** para pruebas)

---

### **PASO 4: Configurar Webhook en Mercado Pago**

1. Ve a: https://www.mercadopago.com.mx/developers/panel/app
2. Selecciona tu aplicación
3. Ve a: **Webhooks** > **Configurar notificaciones**
4. Agrega esta URL:
   ```
   https://tlzkddmquytddhdeqdmo.supabase.co/functions/v1/mercadopago-webhook
   ```
5. Selecciona eventos: **Payments**
6. Guarda

---

## 🧪 Probar la Integración

### **Opción 1: Usar Mercado Pago Sandbox (Recomendado)**

1. **Configura credenciales de prueba** en las variables de entorno
2. **Compra un ticket** en la app
3. Serás redirigido a Mercado Pago
4. **Usa una tarjeta de prueba:**
   - Tarjeta: `4509 9535 6623 3704` (Visa)
   - Vencimiento: `11/25`
   - CVV: `123`
   - Nombre: `APRO` (para aprobar) o `OTHE` (para rechazar)

5. **Verifica:**
   - El webhook debe llegar automáticamente
   - El ticket debe cambiar a `payment_status = 'approved'`
   - El `qr_code_data` debe contener el UUID del ticket

### **Opción 2: Simulación de Desarrollo**

Si las Edge Functions no están configuradas:
1. La app detectará el error automáticamente
2. Mostrará un diálogo preguntando si quieres **simular el pago**
3. Al confirmar, el pago se marca como aprobado localmente

---

## 🔍 Debugging

### **Ver logs de las Edge Functions:**
```bash
# Terminal 1: Logs de create-payment-preference
supabase functions logs create-payment-preference

# Terminal 2: Logs de mercadopago-webhook
supabase functions logs mercadopago-webhook
```

### **Ver webhooks recibidos (SQL Editor):**
```sql
SELECT * FROM webhook_logs 
ORDER BY created_at DESC 
LIMIT 10;
```

### **Verificar tickets pendientes:**
```sql
SELECT id, ticket_type, payment_status, created_at 
FROM tickets 
WHERE payment_status = 'pending'
ORDER BY created_at DESC;
```

---

## 📱 Flujo Completo de Pago

```
1. Usuario presiona "Pagar" en CheckoutScreen
2. App llama a create-payment-preference Edge Function
3. Edge Function crea tickets en DB (status=pending) y preferencia en MP
4. App abre init_point en navegador
5. Usuario completa pago en Mercado Pago
6. MP envía webhook a mercadopago-webhook Edge Function
7. Edge Function verifica estado real del pago y actualiza ticket (approved + QR)
8. Usuario regresa a app y ve sus tickets actualizados con QR
```

---

## ⚠️ Importante

1. **Nunca expongas el Access Token de Mercado Pago en el código Flutter**
   - Las Edge Functions manejan esto de forma segura
   
2. **Los webhooks son esenciales para producción**
   - Sin webhooks, los pagos no se actualizarán automáticamente
   
3. **Prueba primero en Sandbox**
   - Usa credenciales de prueba antes de usar producción
   
4. **El QR code ahora es solo el UUID del ticket**
   - Más simple y seguro
   - Se valida contra la base de datos real

---

## 🎯 Checklist de Configuración

- [ ] Ejecutar `16_mercadopago_webhook_fixed.sql` en Supabase SQL Editor
- [ ] Instalar Supabase CLI
- [ ] Desplegar Edge Function: `create-payment-preference`
- [ ] Desplegar Edge Function: `mercadopago-webhook`
- [ ] Configurar variable: `MERCADOPAGO_ACCESS_TOKEN`
- [ ] Configurar variable: `APP_URL`
- [ ] Configurar webhook en panel de Mercado Pago
- [ ] Probar con tarjetas de test
- [ ] Verificar logs de webhooks en `webhook_logs`

---

## 📚 Referencias

- [Mercado Pago Docs](https://www.mercadopago.com.mx/developers/es/docs)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Tarjetas de Prueba](https://www.mercadopago.com.mx/developers/es/docs/checkout-pro/additional-content/test-cards)
