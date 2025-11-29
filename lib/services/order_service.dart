import 'package:comic_fest/core/supabase_service.dart';
import 'package:comic_fest/models/order_model.dart';
import 'package:comic_fest/models/payment_model.dart';
import 'package:comic_fest/services/mercadopago_service.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class OrderService {
  final SupabaseService _supabase = SupabaseService.instance;
  final MercadoPagoService _mercadoPago = MercadoPagoService();

  /// Crear una nueva orden de tickets
  Future<OrderModel> createTicketOrder({
    required List<Map<String, dynamic>> ticketItems,
    required double totalAmount,
    required String buyerName,
    required String buyerEmail,
    String? buyerPhone,
  }) async {
    final userId = _supabase.userId;
    if (userId == null) throw Exception('No authenticated user');

    final orderId = const Uuid().v4();
    final orderNumber = 'CF-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-${orderId.substring(0, 8).toUpperCase()}';

    final order = OrderModel(
      id: orderId,
      userId: userId,
      items: {'tickets': ticketItems},
      totalAmount: totalAmount,
      orderType: 'ticket',
      orderNumber: orderNumber,
      buyerName: buyerName,
      buyerEmail: buyerEmail,
      buyerPhone: buyerPhone,
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      debugPrint('📦 Creating order: ${order.orderNumber}');
      await _supabase.client.from('orders').insert(order.toJson());

      // Insertar order_items
      for (final item in ticketItems) {
        await _supabase.client.from('order_items').insert({
          'id': const Uuid().v4(),
          'order_id': orderId,
          'ticket_type_id': item['ticket_type_id'],
          'item_type': 'ticket',
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'subtotal': item['subtotal'],
        });
      }

      debugPrint('✅ Order created successfully: ${order.orderNumber}');
      return order;
    } catch (e) {
      debugPrint('❌ Failed to create order: $e');
      rethrow;
    }
  }

  /// Obtener orden por ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final response = await _supabase.client
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ Failed to get order: $e');
      return null;
    }
  }

  /// Obtener órdenes del usuario
  Future<List<OrderModel>> getUserOrders({String? orderType}) async {
    final userId = _supabase.userId;
    if (userId == null) return [];

    try {
      var query = _supabase.client
          .from('orders')
          .select()
          .eq('user_id', userId);

      if (orderType != null) {
        query = query.eq('order_type', orderType);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get user orders: $e');
      return [];
    }
  }

  /// Actualizar estado de la orden
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase.client.from('orders').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      debugPrint('✅ Order status updated: $orderId -> $status');
    } catch (e) {
      debugPrint('❌ Failed to update order status: $e');
      rethrow;
    }
  }

  /// Crear registro de pago
  Future<PaymentModel> createPayment({
    required String orderId,
    required String mpPreferenceId,
    required double amount,
  }) async {
    final paymentId = const Uuid().v4();

    final payment = PaymentModel(
      id: paymentId,
      orderId: orderId,
      mpPreferenceId: mpPreferenceId,
      status: PaymentStatusEnum.pending,
      transactionAmount: amount,
      externalReference: orderId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _supabase.client.from('payments').insert(payment.toJson());
      debugPrint('✅ Payment record created: $paymentId');
      return payment;
    } catch (e) {
      debugPrint('❌ Failed to create payment: $e');
      rethrow;
    }
  }

  /// Verificar estado de pago
  Future<PaymentModel?> getPaymentByOrderId(String orderId) async {
    try {
      final response = await _supabase.client
          .from('payments')
          .select()
          .eq('order_id', orderId)
          .single();

      return PaymentModel.fromJson(response);
    } catch (e) {
      debugPrint('⚠️ Payment not found for order: $orderId');
      return null;
    }
  }

  /// Actualizar estado del pago (usado por el procesamiento de pagos)
  Future<void> updatePaymentStatus({
    required String orderId,
    required String status,
    String? paymentId,
  }) async {
    try {
      // Si se provee un paymentId, verificar que no exista duplicado
      if (paymentId != null) {
        final existingPayment = await _supabase.client
            .from('payments')
            .select('id, order_id')
            .eq('mp_payment_id', paymentId)
            .maybeSingle();

        if (existingPayment != null && existingPayment['order_id'] != orderId) {
          debugPrint('⚠️ Payment ID $paymentId already exists for another order');
          throw Exception('Este pago ya fue procesado anteriormente');
        }
      }

      await _supabase.client.from('payments').update({
        'status': status,
        if (paymentId != null) 'mp_payment_id': paymentId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);

      debugPrint('✅ Payment status updated for order $orderId: $status');
    } catch (e) {
      debugPrint('❌ Failed to update payment status: $e');
      rethrow;
    }
  }

  /// Actualizar el payment con datos completos de Mercado Pago
  Future<void> updatePaymentWithMPData({
    required String orderId,
    required String mpPaymentId,
    required String status,
    String? paymentMethod,
    String? statusDetail,
    Map<String, dynamic>? webhookData,
  }) async {
    try {
      debugPrint('🔄 Updating payment for order: $orderId');
      debugPrint('   MP Payment ID: $mpPaymentId');
      debugPrint('   Status: $status');

      // 1. Verificar estado actual del pago
      final currentPayment = await _supabase.client
          .from('payments')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();

      if (currentPayment == null) {
        debugPrint('❌ Payment record not found for order $orderId');
        throw Exception('Payment record not found for order $orderId');
      }

      // Verificar si ya tiene un ID de pago asignado
      final currentMpId = currentPayment['mp_payment_id'];
      if (currentMpId != null) {
        if (currentMpId.toString() == mpPaymentId) {
          debugPrint('⚠️ Payment already updated with this MP ID. Skipping update.');
          return;
        }
        debugPrint('❌ Payment already has a different MP ID: $currentMpId');
        throw Exception('Este pago ya fue procesado con otro ID de Mercado Pago');
      }

      // 2. Actualizar el pago por partes para aislar el error 22023
      
      // 2. Actualizar TODO junto para satisfacer triggers
      // Es probable que el trigger espere que si status='approved', mp_payment_id y webhook_data existan.
      
      final Map<String, dynamic> updateData = {
        'status': status,
        'mp_payment_id': mpPaymentId,
        'webhook_data': webhookData ?? {}, // Asegurar JSON válido
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (paymentMethod != null) updateData['payment_method'] = paymentMethod;
      if (statusDetail != null) updateData['status_detail'] = statusDetail;

      debugPrint('🔄 Updating payment with ALL data...');
      
      await _supabase.client.from('payments').update(updateData).eq('order_id', orderId);

      // 3. Actualizar la orden si el pago fue aprobado
      // NOTA: El trigger en la base de datos (handle_payment_approval) ya actualiza el estado de la orden a 'paid'.
      // Eliminamos esta actualización explícita para evitar conflictos y errores (22023).
      /*
      if (status == 'approved') {
        await _supabase.client.from('orders').update({
          'status': 'paid',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', orderId);
      }
      */

      debugPrint('✅ Payment flow completed for order $orderId');
    } catch (e) {
      debugPrint('❌ Failed to update payment with MP data: $e');
      rethrow;
    }
  }

  /// Generar tickets para una orden pagada
  Future<void> generateTicketsForOrder(String orderId) async {
    try {
      debugPrint('🎫 Generating tickets for order: $orderId');

      final userId = _supabase.userId;
      if (userId == null) throw Exception('No authenticated user');

      // Obtener order_items con información del ticket_type
      final orderItemsResponse = await _supabase.client
          .from('order_items')
          .select('*, ticket_types!inner(name, price)')
          .eq('order_id', orderId);

      final orderItems = orderItemsResponse as List;

      int totalTickets = 0;
      for (final item in orderItems) {
        final quantity = item['quantity'] as int;
        final ticketTypeName = item['ticket_types']['name'] as String;
        final unitPrice = item['unit_price'].toString();

        // Crear N tickets según la cantidad
        for (int i = 0; i < quantity; i++) {
          final ticketId = const Uuid().v4();
          final qrData = 'CF-TICKET-$ticketId';
          
          await _supabase.client.from('tickets').insert({
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
          totalTickets++;
        }
      }

      debugPrint('✅ Generated $totalTickets tickets for order $orderId');
    } catch (e) {
      debugPrint('❌ Failed to generate tickets: $e');
      rethrow;
    }
  }

  /// Crear checkout de Mercado Pago para una orden (DEPRECATED para tickets)
  /// Use MercadoPagoService.createTicketPaymentPreference() para tickets
  Future<Map<String, dynamic>> createMercadoPagoCheckout({
    required OrderModel order,
    required List<Map<String, dynamic>> ticketItems,
  }) async {
    try {
      // ⚠️ Método deprecado: Los tickets ahora usan Edge Functions
      debugPrint('⚠️ createMercadoPagoCheckout is deprecated for tickets. Use MercadoPagoService instead.');
      
      // Simulación temporal para compatibilidad
      final preference = {
        'preference_id': 'DEPRECATED-${order.id}',
        'init_point': 'https://mercadopago.com',
        'sandbox_init_point': 'https://sandbox.mercadopago.com',
      };

      // Crear registro de pago con la preferencia
      await createPayment(
        orderId: order.id,
        mpPreferenceId: preference['preference_id'] as String,
        amount: order.totalAmount,
      );

      return preference;
    } catch (e) {
      debugPrint('❌ Failed to create Mercado Pago checkout: $e');
      rethrow;
    }
  }

  /// Sincronizar estado del pago desde Mercado Pago (DEPRECATED)
  /// Los webhooks de Supabase Edge Functions actualizan automáticamente el estado
  Future<void> syncPaymentFromMercadoPago(String paymentId) async {
    try {
      debugPrint('⚠️ syncPaymentFromMercadoPago is deprecated. Webhooks handle sync automatically.');
    } catch (e) {
      debugPrint('❌ Failed to sync payment: $e');
    }
  }
}
