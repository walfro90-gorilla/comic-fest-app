import 'package:comic_fest/models/product_model.dart';
import 'package:comic_fest/models/product_model.dart'; // Import
import 'package:comic_fest/screens/points/my_orders_screen.dart'; // Import
import 'package:comic_fest/services/points_service.dart';
import 'package:comic_fest/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:comic_fest/widgets/empty_state_card.dart';

class RedeemScreen extends StatefulWidget {
  const RedeemScreen({super.key});

  @override
  State<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends State<RedeemScreen> {
  final PointsService _pointsService = PointsService();
  final UserService _userService = UserService();
  
  List<ProductModel> _rewards = [];
  bool _isLoading = true;
  int _userPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _userService.fetchUserProfile();
      final user = await _userService.getCurrentUser();
      
      final rewards = await _pointsService.fetchRewards();

      if (mounted) {
        setState(() {
          _userPoints = user?.points ?? 0;
          _rewards = rewards;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _redeemItem(ProductModel product) async {
    // 1. Confirm Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Canje'),
        content: Text(
          '¿Deseas canjear "${product.name}" por ${product.pointsPrice} XP?\n\n'
          'Se restarán de tu saldo actual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Loading State
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    // 3. Call API
    final result = await _pointsService.redeemReward(product.id);
    
    // 4. Close Loading
    if (!mounted) return;
    Navigator.pop(context); 

    // 5. Show Result
    if (result['success'] == true) {
      // Success
      await _loadData(); // Refresh UI
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Canje exitoso! ${result['message']}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error desconocido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda'),
        actions: [
            IconButton(
                icon: const Icon(Icons.confirmation_num_outlined),
                tooltip: 'Mis Premios',
                onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                    );
                },
            ),
            Center(
            child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Icon(Icons.bolt, size: 16, color: colorScheme.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text(
                        '$_userPoints XP',
                        style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                        ),
                    ),
                    ],
                ),
                ),
            ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rewards.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: EmptyStateCard(
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _rewards.length,
                  itemBuilder: (context, index) {
                    final item = _rewards[index];
                    final canAfford = _userPoints >= (item.pointsPrice ?? 0);
                    
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Image (Placeholder if empty)
                          Expanded(
                            child: item.imageUrl.isNotEmpty
                                ? Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: colorScheme.surfaceContainerHighest,
                                      child: const Icon(Icons.image_not_supported),
                                    ),
                                  )
                                : Container(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    child: Icon(Icons.card_giftcard, size: 40, color: colorScheme.primary),
                                  ),
                          ),
                          // Info
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.bolt, size: 14, color: Colors.amber[700]),
                                    Text(
                                      ' ${item.pointsPrice} XP',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber[700],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                        'Qty: ${item.stock}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonal(
                                    onPressed: canAfford ? () => _redeemItem(item) : null,
                                    style: FilledButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact, 
                                    ),
                                    child: Text(canAfford ? 'CANJEAR' : 'Faltan pts'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
