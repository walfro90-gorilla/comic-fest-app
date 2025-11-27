import 'package:flutter/material.dart';
import 'package:comic_fest/models/product_model.dart';

class CartScreen extends StatefulWidget {
  final Map<String, int> cartItems;
  final List<ProductModel> products;
  final Function(Map<String, int>) onCartUpdated;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.products,
    required this.onCartUpdated,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Map<String, int> _localCart;

  @override
  void initState() {
    super.initState();
    _localCart = Map.from(widget.cartItems);
  }

  void _updateQuantity(String productId, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _localCart.remove(productId);
      } else {
        _localCart[productId] = newQuantity;
      }
    });
    widget.onCartUpdated(_localCart);
  }

  double get _subtotal {
    double total = 0;
    for (final product in widget.products) {
      final quantity = _localCart[product.id] ?? 0;
      total += product.price * quantity;
    }
    return total;
  }

  double get _shipping => _subtotal > 500 ? 0 : 80;
  double get _total => _subtotal + _shipping;

  Future<void> _checkout() async {
    if (_localCart.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Integración de Mercado Pago'),
        content: const Text(
          'La integración con Mercado Pago será implementada próximamente.\n\n'
          'Tu orden será procesada y recibirás un email de confirmación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmOrder();
            },
            child: const Text('Simular Compra'),
          ),
        ],
      ),
    );
  }

  void _confirmOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Orden confirmada! Recibirás un email con los detalles.'),
        duration: Duration(seconds: 3),
      ),
    );

    setState(() {
      _localCart.clear();
    });
    widget.onCartUpdated(_localCart);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
      ),
      body: _localCart.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.products.length,
                    itemBuilder: (context, index) {
                      final product = widget.products[index];
                      final quantity = _localCart[product.id] ?? 0;
                      if (quantity == 0) return const SizedBox.shrink();

                      return CartItemCard(
                        product: product,
                        quantity: quantity,
                        onQuantityChanged: (newQty) => _updateQuantity(product.id, newQty),
                      );
                    },
                  ),
                ),
                Container(
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal:', style: theme.textTheme.bodyLarge),
                          Text('\$${_subtotal.toStringAsFixed(2)} MXN', style: theme.textTheme.bodyLarge),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Envío:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            _shipping == 0 ? 'GRATIS' : '\$${_shipping.toStringAsFixed(2)} MXN',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _shipping == 0 ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.7),
                              fontWeight: _shipping == 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      if (_subtotal < 500 && _subtotal > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Envío gratis en compras mayores a \$500',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.secondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${_total.toStringAsFixed(2)} MXN',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _checkout,
                        icon: const Icon(Icons.payment),
                        label: const Text('Proceder al Pago'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Tu carrito está vacío',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega productos desde la tienda',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Ir a la Tienda'),
          ),
        ],
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final ProductModel product;
  final int quantity;
  final Function(int) onQuantityChanged;

  const CartItemCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtotal = product.price * quantity;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: product.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.image_not_supported, color: colorScheme.onSurfaceVariant),
                      ),
                    )
                  : Icon(Icons.shopping_bag, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(2)} MXN',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => onQuantityChanged(quantity - 1),
                        icon: const Icon(Icons.remove_circle_outline),
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$quantity',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: quantity < product.stock ? () => onQuantityChanged(quantity + 1) : null,
                        icon: const Icon(Icons.add_circle_outline),
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\$${subtotal.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
