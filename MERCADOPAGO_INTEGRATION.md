# 🛒 Integración de Mercado Pago - Guía de Implementación

## 📋 Prerequisitos

1. Crear cuenta de desarrollador en [Mercado Pago](https://www.mercadopago.com.mx/developers)
2. Obtener credenciales de producción y prueba (Access Token y Public Key)
3. Agregar el paquete de Mercado Pago SDK a `pubspec.yaml`

## 🔧 Configuración

### 1. Agregar dependencia

```yaml
dependencies:
  mercadopago_sdk: ^1.0.0  # Verificar última versión en pub.dev
```

### 2. Configurar Supabase Edge Function para Mercado Pago

Crear una Edge Function en Supabase que maneje la comunicación con Mercado Pago:

```typescript
// supabase/functions/create-payment/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { items, totalAmount, userEmail } = await req.json()
  
  const response = await fetch('https://api.mercadopago.com/checkout/preferences', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${Deno.env.get('MERCADOPAGO_ACCESS_TOKEN')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      items: items,
      payer: { email: userEmail },
      back_urls: {
        success: 'https://your-app.com/payment-success',
        failure: 'https://your-app.com/payment-failure',
        pending: 'https://your-app.com/payment-pending',
      },
      auto_return: 'approved',
    }),
  })
  
  const data = await response.json()
  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

### 3. Actualizar CartScreen

En `lib/screens/shop/cart_screen.dart`, reemplazar el método `_checkout()`:

```dart
Future<void> _checkout() async {
  if (_localCart.isEmpty) return;

  try {
    // Preparar items para Mercado Pago
    final items = widget.products.map((product) {
      final quantity = _localCart[product.id] ?? 0;
      return {
        'title': product.name,
        'quantity': quantity,
        'unit_price': product.price,
        'currency_id': 'MXN',
      };
    }).toList();

    // Llamar a Supabase Edge Function
    final response = await _supabase.client.functions.invoke(
      'create-payment',
      body: {
        'items': items,
        'totalAmount': _total,
        'userEmail': _currentUserEmail,
      },
    );

    // Abrir URL de pago de Mercado Pago
    final initPoint = response.data['init_point'];
    await launchUrl(Uri.parse(initPoint));
    
  } catch (e) {
    debugPrint('Error al procesar pago: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al procesar el pago: $e')),
    );
  }
}
```

### 4. Configurar Webhook en Supabase

Crear otra Edge Function para recibir notificaciones de pago:

```typescript
// supabase/functions/mercadopago-webhook/index.ts
serve(async (req) => {
  const { type, data } = await req.json()
  
  if (type === 'payment') {
    const paymentId = data.id
    
    // Consultar estado del pago
    const paymentResponse = await fetch(
      `https://api.mercadopago.com/v1/payments/${paymentId}`,
      {
        headers: {
          'Authorization': `Bearer ${Deno.env.get('MERCADOPAGO_ACCESS_TOKEN')}`,
        },
      }
    )
    
    const payment = await paymentResponse.json()
    
    // Actualizar orden en la base de datos
    if (payment.status === 'approved') {
      // Actualizar orden, reducir stock, enviar confirmación
    }
  }
  
  return new Response('OK', { status: 200 })
})
```

### 5. Registrar Webhook en Mercado Pago

En el panel de desarrollador de Mercado Pago, registrar la URL:
```
https://your-project.supabase.co/functions/v1/mercadopago-webhook
```

## 🔐 Variables de Entorno

En Supabase Dashboard > Edge Functions > Secrets, agregar:

```
MERCADOPAGO_ACCESS_TOKEN=your_access_token_here
MERCADOPAGO_PUBLIC_KEY=your_public_key_here
```

## 📊 Tabla de Órdenes

Ya existe el modelo `OrderModel` y la tabla `orders` en la base de datos. Asegúrate de que esté correctamente configurada.

## ✅ Testing

1. Usar credenciales de prueba de Mercado Pago
2. Usar tarjetas de prueba: https://www.mercadopago.com.mx/developers/es/docs/checkout-api/testing
3. Verificar flujo completo: agregar al carrito → checkout → pago → webhook → actualización de orden

## 📚 Recursos

- [Documentación Mercado Pago](https://www.mercadopago.com.mx/developers/es/docs)
- [SDK Flutter](https://pub.dev/packages/mercadopago_sdk)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)

---

**Nota**: Esta es una guía de referencia. La implementación real dependerá de las necesidades específicas del proyecto y las versiones actuales de los SDKs.
