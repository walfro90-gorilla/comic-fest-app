import 'package:comic_fest/models/ticket_type_model.dart';
import 'package:comic_fest/screens/tickets/checkout_screen.dart';
import 'package:comic_fest/services/ticket_service.dart';
import 'package:flutter/material.dart';

class BuyTicketsScreen extends StatefulWidget {
  const BuyTicketsScreen({super.key});

  @override
  State<BuyTicketsScreen> createState() => _BuyTicketsScreenState();
}

class _BuyTicketsScreenState extends State<BuyTicketsScreen> {
  final TicketService _ticketService = TicketService();
  List<TicketTypeModel> _ticketTypes = [];
  final Map<String, int> _cart = {}; // ticket_type_id → quantity
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTicketTypes();
  }

  Future<void> _loadTicketTypes() async {
    setState(() => _isLoading = true);
    try {
      final types = await _ticketService.getAvailableTicketTypes(forceRefresh: true);
      if (mounted) {
        setState(() {
          _ticketTypes = types;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar tickets: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  int get _totalItemsInCart => _cart.values.fold(0, (sum, qty) => sum + qty);

  double get _totalAmount {
    double total = 0;
    for (final entry in _cart.entries) {
      final ticketType = _ticketTypes.firstWhere((t) => t.id == entry.key);
      total += ticketType.price * entry.value;
    }
    return total;
  }

  void _updateQuantity(String ticketTypeId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cart.remove(ticketTypeId);
      } else {
        _cart[ticketTypeId] = quantity;
      }
    });
  }

  void _goToCheckout() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega tickets al carrito primero')),
      );
      return;
    }

    final cartItems = _cart.entries.map((entry) {
      final ticketType = _ticketTypes.firstWhere((t) => t.id == entry.key);
      return {
        'ticket_type': ticketType,
        'quantity': entry.value,
      };
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          cartItems: cartItems,
          totalAmount: _totalAmount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprar Boletos'),
        actions: [
          if (_totalItemsInCart > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Badge(
                  label: Text('$_totalItemsInCart'),
                  child: IconButton(
                    onPressed: _goToCheckout,
                    icon: const Icon(Icons.shopping_cart),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTicketTypes,
              child: _ticketTypes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.confirmation_number_outlined, size: 64, color: colorScheme.outline),
                          const SizedBox(height: 16),
                          Text('No hay tickets disponibles', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _loadTicketTypes,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Recargar'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEventBanner(theme, colorScheme),
                          const SizedBox(height: 24),
                          Text('Selecciona tus Boletos', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          ..._ticketTypes.map((ticketType) => _buildTicketCard(ticketType, theme, colorScheme)),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
            ),
      floatingActionButton: _totalItemsInCart > 0
          ? FloatingActionButton.extended(
              onPressed: _goToCheckout,
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text('Pagar \$${_totalAmount.toStringAsFixed(2)}'),
            )
          : null,
    );
  }

  Widget _buildEventBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comic Fest 2026', style: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: colorScheme.onPrimary, size: 18),
              const SizedBox(width: 4),
              Text('Ciudad Juárez, Chihuahua', style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, color: colorScheme.onPrimary, size: 18),
              const SizedBox(width: 4),
              Text('Marzo 2026', style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(TicketTypeModel ticketType, ThemeData theme, ColorScheme colorScheme) {
    final quantity = _cart[ticketType.id] ?? 0;
    final bool outOfStock = !ticketType.isAvailable;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: ticketType.isEarlyBird ? 4 : 1,
      child: Opacity(
        opacity: outOfStock ? 0.6 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(ticketType.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            ),
                            if (ticketType.isEarlyBird)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('EARLY BIRD', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onTertiary, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('\$${ticketType.price.toStringAsFixed(0)} MXN', style: theme.textTheme.headlineMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              if (ticketType.description != null) ...[
                const SizedBox(height: 12),
                Text(ticketType.description!, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7))),
              ],
              if (ticketType.benefits.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...ticketType.benefits.map((benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle, size: 18, color: colorScheme.tertiary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(benefit, style: theme.textTheme.bodyMedium)),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (ticketType.isLowStock)
                    Row(
                      children: [
                        Icon(Icons.warning_amber, size: 18, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text('Solo ${ticketType.stockAvailable} disponibles', style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange, fontWeight: FontWeight.bold)),
                      ],
                    )
                  else if (outOfStock)
                    Text('AGOTADO', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold))
                  else
                    Text('${ticketType.stockAvailable} disponibles', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline)),
                ],
              ),
              const SizedBox(height: 16),
              if (outOfStock)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: null,
                    child: const Text('Agotado'),
                  ),
                )
              else if (quantity == 0)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _updateQuantity(ticketType.id, 1),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Agregar al Carrito'),
                  ),
                )
              else
                Row(
                  children: [
                    IconButton.filled(
                      onPressed: () => _updateQuantity(ticketType.id, quantity - 1),
                      icon: const Icon(Icons.remove),
                    ),
                    Expanded(
                      child: Text('$quantity en carrito', textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    IconButton.filled(
                      onPressed: quantity < ticketType.stockAvailable ? () => _updateQuantity(ticketType.id, quantity + 1) : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
