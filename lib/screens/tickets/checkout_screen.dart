import 'package:comic_fest/models/ticket_type_model.dart';
import 'package:comic_fest/screens/tickets/tickets_list_screen.dart';
import 'package:comic_fest/screens/tickets/card_payment_screen.dart';
import 'package:comic_fest/services/mercadopago_service.dart';
import 'package:comic_fest/services/order_service.dart';
import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final MercadoPagoService _mpService = MercadoPagoService();
  final OrderService _orderService = OrderService();
  bool _isProcessing = false;
  String? _currentOrderId;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      debugPrint('💳 Preparando datos de compra...');
      
      final ticketItems = widget.cartItems.map((item) {
        final ticketType = item['ticket_type'] as TicketTypeModel;
        final quantity = item['quantity'] as int;
        return {
          'ticket_type_id': ticketType.id,
          'quantity': quantity,
          'unit_price': ticketType.price,
          'subtotal': ticketType.price * quantity,
        };
      }).toList();

      // Pasar los datos del comprador a la pantalla de pago
      // La orden y payment se crearán SOLO si el pago es exitoso
      if (mounted) {
        setState(() => _isProcessing = false);
        
        // Navegar a la pantalla de pago con tarjeta
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CardPaymentScreen(
              ticketItems: ticketItems,
              totalAmount: widget.totalAmount,
              buyerName: _nameController.text.trim(),
              buyerEmail: _emailController.text.trim(),
              buyerPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error al procesar pago: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el pago: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen de Compra',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...widget.cartItems.map((item) {
                    final ticketType = item['ticket_type'] as TicketTypeModel;
                    final quantity = item['quantity'] as int;
                    final subtotal = ticketType.price * quantity;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text('$quantity', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(ticketType.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('\$${ticketType.price.toStringAsFixed(0)} MXN × $quantity'),
                        trailing: Text('\$${subtotal.toStringAsFixed(0)} MXN', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                    );
                  }),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text('\$${widget.totalAmount.toStringAsFixed(2)} MXN', style: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Datos del Comprador',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Completo *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es requerido';
                      }
                      if (value.trim().length < 3) {
                        return 'El nombre debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico *',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El correo es requerido';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Correo inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono (opcional)',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                      helperText: 'Recibirás notificaciones por WhatsApp',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('Información Importante', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Recibirás tus boletos con código QR por correo electrónico\n• Los boletos son válidos para una sola entrada\n• No se permiten reembolsos después de la compra\n• Guarda tus boletos en un lugar seguro',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
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
                        Text('Procesando orden...'),
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
