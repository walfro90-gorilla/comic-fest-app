import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:comic_fest/services/mercadopago_service.dart';
import 'package:comic_fest/services/order_service.dart';
import 'package:comic_fest/screens/tickets/tickets_list_screen.dart';

class CardPaymentScreen extends StatefulWidget {
  final List<Map<String, dynamic>> ticketItems;
  final double totalAmount;
  final String buyerName;
  final String buyerEmail;
  final String? buyerPhone;

  const CardPaymentScreen({
    super.key,
    required this.ticketItems,
    required this.totalAmount,
    required this.buyerName,
    required this.buyerEmail,
    this.buyerPhone,
  });

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final MercadoPagoService _mpService = MercadoPagoService();
  final OrderService _orderService = OrderService();

  String cardNumber = '4189 1412 2126 7633';
  String expiryDate = '11/23';
  String cardHolderName = 'APRO';
  String cvvCode = '123';
  bool isCvvFocused = false;
  bool _isProcessing = false;
  
  // Para guardar el orderId después de crearlo
  String? _createdOrderId;
  String? _createdOrderNumber;

  // Datos de identificación (requeridos por Mercado Pago)
  final _identificationController = TextEditingController(text: '12346789');
  String _identificationType = 'DNI'; // DNI, CURP, RFC, etc.

  @override
  void dispose() {
    _identificationController.dispose();
    super.dispose();
  }

  void _fillTestCard() {
    setState(() {
      cardNumber = '4189 1412 2126 7633';
      expiryDate = '11/23'; // Note: This might be expired. User requested 11/23. I'll use it.
      cardHolderName = 'APRO';
      cvvCode = '123';
      _identificationController.text = '12346789';
    });
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    if (cardHolderName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa el nombre del titular')),
      );
      return;
    }

    if (_identificationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu número de identificación')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      debugPrint('🔐 Procesando pago con tarjeta...');
      debugPrint('📝 Amount: ${widget.totalAmount}');
      debugPrint('📝 Buyer Email: ${widget.buyerEmail}');
      debugPrint('📝 Card Number length: ${cardNumber.length}');
      debugPrint('📝 Cardholder Name: "$cardHolderName" (length: ${cardHolderName.length})');
      debugPrint('📝 Expiry Date: "$expiryDate"');
      debugPrint('📝 CVV length: ${cvvCode.length}');
      debugPrint('📝 ID Type: $_identificationType');
      debugPrint('📝 ID Number: ${_identificationController.text.trim()}');
      
      final expiryParts = expiryDate.split('/');
      if (expiryParts.length != 2) {
        throw Exception('Fecha de expiración inválida');
      }

      final expMonth = expiryParts[0].trim();
      final expYear = '20${expiryParts[1].trim()}';
      
      debugPrint('📝 Parsed Expiration: $expMonth/$expYear');

      // Procesar pago a través de Edge Function (evita CORS)
      // Usar un ID temporal para el external_reference
      final tempOrderRef = 'TEMP-${DateTime.now().millisecondsSinceEpoch}';
      
      final paymentResult = await _mpService.processCardPaymentViaEdgeFunction(
        orderId: tempOrderRef,
        amount: widget.totalAmount,
        payerEmail: widget.buyerEmail,
        cardNumber: cardNumber,
        cardholderName: cardHolderName,
        expirationMonth: expMonth,
        expirationYear: expYear,
        securityCode: cvvCode,
        identificationType: _identificationType,
        identificationNumber: _identificationController.text.trim(),
      );

      if (mounted) {
        setState(() => _isProcessing = false);
      }

      if (paymentResult['success'] == true) {
        final status = paymentResult['status'];
        final paymentId = paymentResult['payment_id'].toString();
        final statusDetail = paymentResult['status_detail'];

        debugPrint('✅ Payment status: $status');
        debugPrint('✅ Payment status_detail: $statusDetail');

        if (status == 'approved' || status == 'pending' || status == 'in_process') {
          // SOLO AHORA crear la orden y payment en Supabase
          debugPrint('📦 Creando orden en Supabase...');
          
          final order = await _orderService.createTicketOrder(
            ticketItems: widget.ticketItems,
            totalAmount: widget.totalAmount,
            buyerName: widget.buyerName,
            buyerEmail: widget.buyerEmail,
            buyerPhone: widget.buyerPhone,
          );
          
          _createdOrderId = order.id;
          _createdOrderNumber = order.orderNumber;
          debugPrint('✅ Orden creada: $_createdOrderNumber');
          
          // Crear registro de pago
          await _orderService.createPayment(
            orderId: order.id,
            mpPreferenceId: paymentId,
            amount: widget.totalAmount,
          );
          debugPrint('✅ Payment record creado');
          
          // Extraer datos crudos para el webhook_data
          final rawData = paymentResult['raw'] as Map<String, dynamic>?;

          if (status == 'approved') {
            // Actualizar el payment con los datos de Mercado Pago
            await _approveOrder(paymentId, statusDetail, 'approved', rawData);
            if (mounted) {
              _showSuccessDialog();
            }
          } else if (status == 'pending' || status == 'in_process') {
            // También guardar la info para pagos pendientes
            await _approveOrder(paymentId, statusDetail, 'pending', rawData);
            
            // Pagos pendientes o en proceso
            if (mounted) {
              _showPendingDialog(statusDetail);
            }
          }
        } else {
          // rejected, cancelled, etc.
          // NO crear orden ni payment
          debugPrint('❌ Pago rechazado. NO se creará orden.');
          final statusDetailValue = statusDetail ?? 'unknown';
          _showRejectionDialog(statusDetailValue);
        }
      } else {
        // Error en el procesamiento
        final rawError = paymentResult['error'] ?? 'Error desconocido';
        final details = paymentResult['details'];
        final friendlyError = _parseErrorMessage(rawError.toString());
        _showErrorDialog(friendlyError, details ?? rawError);
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      
      if (mounted) {
        setState(() => _isProcessing = false);
        final friendlyError = _parseErrorMessage(e.toString());
        _showErrorDialog(friendlyError, e.toString());
      }
    }
  }

  String _parseErrorMessage(String error) {
    final lowerError = error.toLowerCase();
    
    // Errores específicos de validación
    if (lowerError.contains('invalid expiration_year')) {
      return 'El año de expiración de la tarjeta es incorrecto.\nPor favor verifica la fecha de vencimiento.';
    }
    if (lowerError.contains('invalid expiration_month')) {
      return 'El mes de expiración de la tarjeta es incorrecto.\nPor favor verifica la fecha de vencimiento.';
    }
    if (lowerError.contains('invalid security_code')) {
      return 'El código de seguridad (CVV) es incorrecto.';
    }
    if (lowerError.contains('invalid card_number') || lowerError.contains('bad_filled_card_number')) {
      return 'El número de tarjeta es inválido.';
    }
    if (lowerError.contains('bad_request')) {
      return 'Los datos de la tarjeta no son válidos. Por favor verifícalos.';
    }
    if (lowerError.contains('insufficient_amount')) {
      return 'La tarjeta no tiene fondos suficientes para realizar la compra.';
    }
    
    // Error genérico de FunctionException
    if (error.contains('FunctionException')) {
      return 'No pudimos procesar tu tarjeta en este momento.\nPor favor intenta con otra tarjeta o verifica los datos.';
    }

    return error;
  }

  Future<void> _approveOrder(String mpPaymentId, String? statusDetail, String status, Map<String, dynamic>? paymentData) async {
    try {
      if (_createdOrderId == null) {
        throw Exception('No se ha creado la orden');
      }
      
      // Actualizar el payment con el mp_payment_id y status
      await _orderService.updatePaymentWithMPData(
        orderId: _createdOrderId!,
        mpPaymentId: mpPaymentId,
        status: status,
        paymentMethod: 'card',
        statusDetail: statusDetail,
        webhookData: paymentData,
      );
      
      debugPrint('✅ Pago actualizado. El trigger generará los tickets.');
    } catch (e) {
      debugPrint('❌ Error completando orden: $e');
      rethrow;
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.tertiary,
          size: 64,
        ),
        title: const Text('¡Pago Aprobado!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tu pago ha sido procesado exitosamente.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Tus boletos están listos y puedes verlos en "Mis Boletos".',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (_createdOrderNumber != null) ...[
              const SizedBox(height: 8),
              Text(
                'Orden: $_createdOrderNumber',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close payment screen
              Navigator.of(context).pop(); // Close checkout
              Navigator.of(context).pop(); // Close buy tickets
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TicketsListScreen()),
              );
            },
            child: const Text('Ver Mis Boletos'),
          ),
        ],
      ),
    );
  }

  void _showPendingDialog(String? detail) {
    // Mensajes más claros según el estado
    String message = 'Tu pago está siendo procesado.';
    String explanation = 'El banco está verificando la transacción.';
    
    if (detail == 'pending_contingency') {
      message = 'Pago en revisión';
      explanation = 'Tu pago fue recibido pero está en revisión manual por Mercado Pago. Esto suele resolverse en minutos.';
    } else if (detail == 'pending_review_manual') {
      message = 'Revisión manual requerida';
      explanation = 'Tu pago requiere revisión adicional por seguridad. Te notificaremos cuando se apruebe.';
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.schedule,
          color: Theme.of(context).colorScheme.secondary,
          size: 64,
        ),
        title: Text(message),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              explanation,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (detail != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Estado técnico',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                            fontFamily: 'monospace',
                          ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Recibirás un correo cuando se confirme tu pago y tus boletos estén listos.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close payment screen
              Navigator.of(context).pop(); // Close checkout
              Navigator.of(context).pop(); // Close buy tickets
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(String statusDetail) {
    // Mensajes de error específicos de MercadoPago según la documentación oficial
    switch (statusDetail) {
      // Errores de datos de tarjeta
      case 'cc_rejected_bad_filled_card_number':
        return 'El número de tarjeta es inválido. Verifica que esté correcto.';
      case 'cc_rejected_bad_filled_date':
        return 'La fecha de expiración es inválida. Verifica mes y año.';
      case 'cc_rejected_bad_filled_security_code':
        return 'El código de seguridad (CVV) es inválido.';
      case 'cc_rejected_bad_filled_other':
        return 'Hay un error en los datos de la tarjeta. Verifica toda la información.';
      
      // Problemas con la tarjeta o banco
      case 'cc_rejected_blacklist':
        return 'La tarjeta está en lista negra. Contacta a tu banco.';
      case 'cc_rejected_call_for_authorize':
      case 'CALL':
        return 'Debes autorizar el pago con tu banco. Llama al número en tu tarjeta.';
      case 'cc_rejected_card_disabled':
        return 'La tarjeta está deshabilitada. Contacta a tu banco.';
      case 'cc_rejected_card_error':
        return 'La tarjeta no pudo ser procesada. Intenta con otra tarjeta.';
      case 'cc_rejected_duplicated_payment':
        return 'Ya existe un pago similar. Espera unos minutos antes de reintentar.';
      case 'cc_rejected_high_risk':
        return 'Pago rechazado por seguridad. Contacta a tu banco.';
      case 'cc_rejected_insufficient_amount':
      case 'FUND':
        return 'La tarjeta no tiene fondos suficientes.';
      case 'cc_rejected_invalid_installments':
        return 'Las cuotas seleccionadas no son válidas para esta tarjeta.';
      case 'cc_rejected_max_attempts':
        return 'Superaste el número máximo de intentos. Intenta más tarde.';
      case 'cc_rejected_other_reason':
      case 'OTHE':
        return 'El pago fue rechazado por el banco. Intenta con otra tarjeta o contacta a tu banco.';
      
      // Problemas de seguridad
      case 'SECU':
      case 'cc_rejected_invalid_security_code':
        return 'El código de seguridad es inválido.';
      
      // Problemas de fecha
      case 'EXPI':
      case 'cc_rejected_expired_card':
        return 'La tarjeta está vencida. Verifica la fecha de expiración.';
      
      // Problemas de formulario
      case 'FORM':
        return 'Hay un error en los datos ingresados. Revisa toda la información.';
      
      // Pendiente de aprobación
      case 'CONT':
        return 'Pago pendiente de aprobación. Te notificaremos cuando se confirme.';
      
      default:
        return 'El pago fue rechazado: $statusDetail';
    }
  }

  void _showRejectionDialog(String statusDetail) {
    final errorMessage = _getErrorMessage(statusDetail);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
          size: 64,
        ),
        title: const Text('Pago Rechazado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Código de error',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusDetail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontFamily: 'monospace',
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '💳 Tarjetas de prueba',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Para aprobar: 5031 7557 3453 0604\nPara rechazar: 5031 4332 1540 6351\n\nCVV: cualquiera\nFecha: cualquier fecha futura\nNombre: APRO o OTHE',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontFamily: 'monospace',
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Intentar de Nuevo'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close payment screen
            },
            child: const Text('Cambiar Método de Pago'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error, dynamic details) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          Icons.error_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 72,
        ),
        title: Text(
          'No se pudo procesar el pago',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Sugerencias
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '¿Qué puedes hacer?',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSuggestionItem('Verifica que los datos de la tarjeta sean correctos'),
                    _buildSuggestionItem('Asegúrate de tener fondos suficientes'),
                    _buildSuggestionItem('Intenta con otra tarjeta (débito/crédito)'),
                    _buildSuggestionItem('Contacta a tu banco si el problema persiste'),
                  ],
                ),
              ),
              
              if (details != null) ...[
                const SizedBox(height: 16),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      'Ver detalles técnicos',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    iconColor: Theme.of(context).colorScheme.outline,
                    collapsedIconColor: Theme.of(context).colorScheme.outline,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        width: double.infinity,
                        child: Text(
                          details.toString(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Entendido, volver a intentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar con Tarjeta'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Vista de la tarjeta
                CreditCardWidget(
                  cardNumber: cardNumber,
                  expiryDate: expiryDate,
                  cardHolderName: cardHolderName,
                  cvvCode: cvvCode,
                  showBackView: isCvvFocused,
                  obscureCardNumber: true,
                  obscureCardCvv: true,
                  isHolderNameVisible: true,
                  cardBgColor: colorScheme.primary,
                  glassmorphismConfig: Glassmorphism.defaultConfig(),
                  isSwipeGestureEnabled: true,
                  onCreditCardWidgetChange: (CreditCardBrand brand) {},
                ),
                
                // Formulario de datos de la tarjeta
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen de compra',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ...widget.ticketItems.map((item) {
                                final quantity = item['quantity'] as int;
                                final unitPrice = item['unit_price'] as double;
                                final subtotal = item['subtotal'] as double;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$quantity x Boleto',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                      Text(
                                        '\$${subtotal.toStringAsFixed(0)}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total a pagar',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '\$${widget.totalAmount.toStringAsFixed(2)} MXN',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Botón de prueba
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _fillTestCard,
                          icon: const Icon(Icons.bug_report),
                          label: const Text('APROBADO'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        ),
                      ),
                      
                      // Formulario de tarjeta
                      CreditCardForm(
                        formKey: _formKey,
                        cardNumber: cardNumber,
                        expiryDate: expiryDate,
                        cardHolderName: cardHolderName,
                        cvvCode: cvvCode,
                        onCreditCardModelChange: (CreditCardModel data) {
                          setState(() {
                            cardNumber = data.cardNumber;
                            expiryDate = data.expiryDate;
                            cardHolderName = data.cardHolderName;
                            cvvCode = data.cvvCode;
                            isCvvFocused = data.isCvvFocused;
                          });
                        },
                        obscureCvv: true,
                        obscureNumber: true,
                        isHolderNameVisible: true,
                        isCardNumberVisible: true,
                        isExpiryDateVisible: true,
                        enableCvv: true,
                        inputConfiguration: InputConfiguration(
                          cardNumberDecoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelText: 'Número de tarjeta',
                            hintText: 'XXXX XXXX XXXX XXXX',
                            prefixIcon: const Icon(Icons.credit_card),
                          ),
                          expiryDateDecoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelText: 'Fecha de expiración',
                            hintText: 'MM/YY',
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          cvvCodeDecoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelText: 'CVV',
                            hintText: 'XXX',
                            prefixIcon: const Icon(Icons.lock),
                          ),
                          cardHolderDecoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelText: 'Nombre del titular',
                            hintText: 'Como aparece en la tarjeta',
                            prefixIcon: const Icon(Icons.person),
                          ),
                          cardNumberTextStyle: theme.textTheme.bodyLarge,
                          cardHolderTextStyle: theme.textTheme.bodyLarge,
                          expiryDateTextStyle: theme.textTheme.bodyLarge,
                          cvvCodeTextStyle: theme.textTheme.bodyLarge,
                        ),
                        cardNumberValidator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa el número de tarjeta';
                          }
                          if (value.replaceAll(' ', '').length < 13) {
                            return 'Número de tarjeta incompleto';
                          }
                          return null;
                        },
                        expiryDateValidator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa la fecha de expiración';
                          }
                          final parts = value.split('/');
                          if (parts.length != 2) {
                            return 'Formato inválido (MM/YY)';
                          }
                          final month = int.tryParse(parts[0]);
                          if (month == null || month < 1 || month > 12) {
                            return 'Mes inválido';
                          }
                          return null;
                        },
                        cvvValidator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa el CVV';
                          }
                          if (value.length < 3) {
                            return 'CVV incompleto';
                          }
                          return null;
                        },
                        cardHolderValidator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa el nombre del titular';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Datos de identificación
                      Text(
                        'Identificación del titular',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _identificationType,
                              decoration: InputDecoration(
                                labelText: 'Tipo',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'DNI', child: Text('DNI')),
                                DropdownMenuItem(value: 'CURP', child: Text('CURP')),
                                DropdownMenuItem(value: 'RFC', child: Text('RFC')),
                                DropdownMenuItem(value: 'PASS', child: Text('Pasaporte')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _identificationType = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _identificationController,
                              decoration: InputDecoration(
                                labelText: 'Número',
                                hintText: 'Ej: 123456789',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requerido';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Información de seguridad
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock, size: 20, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tu información está protegida con encriptación de nivel bancario',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Procesando pago...'),
                        SizedBox(height: 8),
                        Text(
                          'Por favor no cierres esta pantalla',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: FilledButton.icon(
            onPressed: _isProcessing ? null : _processPayment,
            icon: const Icon(Icons.payment),
            label: Text('Pagar \$${widget.totalAmount.toStringAsFixed(2)} MXN'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ),
    );
  }
}
