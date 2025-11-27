import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:comic_fest/supabase/supabase_config.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// Servicio para integración con Mercado Pago - DIRECTO desde Flutter
/// 
/// Este servicio se comunica DIRECTAMENTE con la API de Mercado Pago para:
/// 1. Crear preferencias de pago
/// 2. Verificar el estado de pagos desde la base de datos
/// 
/// CONFIGURACIÓN REQUERIDA:
/// 1. Access Token de Mercado Pago (hardcoded por ahora, mover a .env en producción)
/// 2. Webhook configurado en Mercado Pago apuntando a tu servidor/edge function
class MercadoPagoService {
  // ⚠️ IMPORTANTE: En producción, mover esto a variables de entorno
  // Access Token de PRUEBA de Mercado Pago
  static const String _accessToken = 'TEST-609116576534644-111319-2a64ba9924fab4e9b158322d60311a64-479630144';
  static const String _preferencesUrl = 'https://api.mercadopago.com/checkout/preferences';
  static const String _paymentsUrl = 'https://api.mercadopago.com/v1/payments';
  static const String _cardTokenUrl = 'https://api.mercadopago.com/v1/card_tokens';
  
  /// Crear una preferencia de pago para una orden completa
  /// Llama DIRECTAMENTE a la API de Mercado Pago (sin Edge Functions)
  Future<Map<String, dynamic>> createPaymentPreference({
    required String orderId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    try {
      debugPrint('💳 Creating payment preference for order: $orderId');
      debugPrint('📦 Items: ${items.length}, Total: \$${totalAmount.toStringAsFixed(2)}');

      // Verificar que hay usuario autenticado
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('🔐 User authenticated: ${user.email}');

      // Preparar payload para Mercado Pago
      final payload = {
        'items': items.map((item) {
          return {
            'title': item['title'],
            'quantity': item['quantity'],
            'unit_price': (item['unit_price'] as num).toDouble(),
            'currency_id': 'MXN',
          };
        }).toList(),
        'payer': {
          'email': user.email ?? 'guest@comicfest.com',
        },
        'back_urls': {
          'success': 'https://comicfest.app/payment/success',
          'failure': 'https://comicfest.app/payment/failure',
          'pending': 'https://comicfest.app/payment/pending',
        },
        'auto_return': 'approved',
        'external_reference': orderId,
        'statement_descriptor': 'COMIC FEST',
        'notification_url': 'https://tlzkddmquytddhdeqdmo.supabase.co/functions/v1/mercadopago-webhook',
      };

      debugPrint('📤 Calling Mercado Pago API...');
      debugPrint('🔗 URL: $_preferencesUrl');
      debugPrint('📦 Payload: ${jsonEncode(payload)}');

      // Llamar a la API de Mercado Pago
      final response = await http.post(
        Uri.parse(_preferencesUrl),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final preferenceId = data['id'];
        final initPoint = data['init_point'];
        final sandboxInitPoint = data['sandbox_init_point'];
        
        debugPrint('✅ Preference created: $preferenceId');
        debugPrint('🔗 Init Point: $initPoint');
        debugPrint('🔗 Sandbox Init Point: $sandboxInitPoint');
        
        // En desarrollo, usar sandbox
        final checkoutUrl = sandboxInitPoint ?? initPoint;
        
        return {
          'success': true,
          'init_point': checkoutUrl,
          'preference_id': preferenceId,
        };
      } else {
        debugPrint('❌ Mercado Pago API error: ${response.statusCode}');
        debugPrint('❌ Error body: ${response.body}');
        throw Exception('Mercado Pago API returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error creating payment preference: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Verificar estado de una orden después de que el usuario regrese
  /// Consulta directamente la base de datos (actualizada por el webhook)
  Future<Map<String, dynamic>?> checkOrderPaymentStatus(String orderId) async {
    try {
      debugPrint('🔍 Checking order payment status: $orderId');

      final orderResponse = await SupabaseConfig.client
          .from('orders')
          .select()
          .eq('id', orderId)
          .maybeSingle();

      if (orderResponse != null) {
        final paymentResponse = await SupabaseConfig.client
            .from('payments')
            .select()
            .eq('order_id', orderId)
            .maybeSingle();

        debugPrint('✅ Order status: ${orderResponse['status']}');
        if (paymentResponse != null) {
          debugPrint('✅ Payment status: ${paymentResponse['status']}');
        }

        return {
          'order': orderResponse,
          'payment': paymentResponse,
        };
      } else {
        debugPrint('⚠️ Order not found');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error checking payment status: $e');
      return null;
    }
  }

  /// Helper: Verificar si Supabase está configurado correctamente
  bool get isConfigured {
    try {
      return SupabaseConfig.client.auth.currentUser != null;
    } catch (e) {
      return false;
    }
  }

  /// Simular pago aprobado (solo para desarrollo/testing)
  /// ADVERTENCIA: Esto NO debe usarse en producción
  /// Simula el comportamiento del webhook de Mercado Pago
  Future<bool> simulatePaymentApproval(String orderId) async {
    try {
      debugPrint('⚠️ SIMULANDO aprobación de pago para orden: $orderId');
      
      // 1. Actualizar el pago
      await SupabaseConfig.client
          .from('payments')
          .update({
            'status': 'approved',
            'mp_payment_id': 'SIM-${DateTime.now().millisecondsSinceEpoch}',
            'payment_method': 'simulated',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('order_id', orderId);

      // 2. Actualizar la orden
      final orderResponse = await SupabaseConfig.client
          .from('orders')
          .update({
            'status': 'paid',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select('items')
          .single();

      // 3. Obtener order_items para crear tickets
      final orderItemsResponse = await SupabaseConfig.client
          .from('order_items')
          .select('*, ticket_types!inner(name, price)')
          .eq('order_id', orderId);

      final orderItems = orderItemsResponse as List;
      
      // 4. Crear tickets para cada item
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) throw Exception('No user logged in');

      for (final item in orderItems) {
        final quantity = item['quantity'] as int;
        final ticketTypeName = item['ticket_types']['name'] as String;
        final unitPrice = item['unit_price'].toString();

        // Crear N tickets según la cantidad
        for (int i = 0; i < quantity; i++) {
          final ticketId = const Uuid().v4();
          final qrData = 'CF-TICKET-$ticketId';
          
          await SupabaseConfig.client.from('tickets').insert({
            'id': ticketId,
            'user_id': userId,
            'ticket_type': ticketTypeName,
            'price': unitPrice,
            'payment_status': 'approved',
            'qr_code_data': qrData,
            'is_validated': false,
            'purchase_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }

      debugPrint('✅ Pago simulado y ${orderItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int))} tickets generados');
      return true;
    } catch (e) {
      debugPrint('❌ Error simulando pago: $e');
      return false;
    }
  }

  /// Procesar pago con tarjeta usando Edge Function de Supabase
  /// Evita problemas de CORS al hacer las llamadas desde el servidor
  Future<Map<String, dynamic>> processCardPaymentViaEdgeFunction({
    required String orderId,
    required double amount,
    required String payerEmail,
    required String cardNumber,
    required String cardholderName,
    required String expirationMonth,
    required String expirationYear,
    required String securityCode,
    required String identificationType,
    required String identificationNumber,
  }) async {
    try {
      debugPrint('💳 Processing card payment via Edge Function...');
      debugPrint('💰 Amount: $amount');
      debugPrint('📦 Order: $orderId');

      // Verificar que hay usuario autenticado
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener la sesión actual
      final session = await SupabaseConfig.client.auth.refreshSession();
      final accessToken = session.session?.accessToken;
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      debugPrint('🔐 User authenticated: ${user.email}');
      debugPrint('🔑 Token length: ${accessToken.length}');

      // Preparar payload
      final payload = {
        'orderId': orderId,
        'amount': amount,
        'payerEmail': payerEmail,
        'cardData': {
          'cardNumber': cardNumber,
          'cardholderName': cardholderName,
          'expirationMonth': expirationMonth,
          'expirationYear': expirationYear,
          'securityCode': securityCode,
          'identificationType': identificationType,
          'identificationNumber': identificationNumber,
        },
      };

      debugPrint('📤 Invoking Edge Function: process-card-payment');
      debugPrint('📦 Payload keys: ${payload.keys.join(', ')}');
      debugPrint('📦 OrderId: $orderId');
      debugPrint('📦 Amount: $amount');
      debugPrint('📦 PayerEmail: $payerEmail');
      debugPrint('📦 CardData present: ${payload['cardData'] != null}');
      if (payload['cardData'] != null) {
        final cardData = payload['cardData'] as Map<String, dynamic>;
        debugPrint('📦 CardData keys: ${cardData.keys.join(', ')}');
        debugPrint('📦 Card Number length: ${cardNumber.length} chars');
        debugPrint('📦 Cardholder Name: "$cardholderName"');
        debugPrint('📦 Expiration: $expirationMonth/$expirationYear');
        debugPrint('📦 Security Code length: ${securityCode.length}');
        debugPrint('📦 ID Type: $identificationType');
        debugPrint('📦 ID Number: $identificationNumber');
      }
      debugPrint('📦 Full payload JSON: ${jsonEncode(payload)}');

      // Llamar a la Edge Function
      final response = await SupabaseConfig.client.functions.invoke(
        'process-card-payment',
        body: payload,
      );

      debugPrint('📡 Response status: ${response.status}');
      debugPrint('📡 Response data: ${response.data}');
      
      // Si hay error, mostrar detalles
      if (response.status != 200) {
        debugPrint('❌ Edge Function error - Status: ${response.status}');
        debugPrint('❌ Error details: ${jsonEncode(response.data)}');
      }

      // Verificar respuesta
      final data = response.data;
      if (data == null) {
        throw Exception('No data received from Edge Function');
      }

      if (data['success'] == true) {
        final paymentId = data['payment_id'];
        final status = data['status'];
        final statusDetail = data['status_detail'];

        debugPrint('✅ Payment processed: $paymentId');
        debugPrint('✅ Status: $status ($statusDetail)');

        return {
          'success': true,
          'payment_id': paymentId,
          'status': status,
          'status_detail': statusDetail,
          'raw': data['raw'],
        };
      } else {
        final error = data['error'] ?? 'Unknown error';
        debugPrint('❌ Payment failed: $error');
        return {
          'success': false,
          'error': error,
          'details': data['details'],
        };
      }
    } catch (e) {
      debugPrint('❌ Error processing payment: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
