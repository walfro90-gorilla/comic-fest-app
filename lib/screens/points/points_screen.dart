import 'package:comic_fest/models/points_transaction_model.dart';
import 'package:comic_fest/models/user_model.dart';
import 'package:comic_fest/services/points_service.dart';
import 'package:comic_fest/services/user_service.dart';
import 'package:comic_fest/widgets/points_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  final PointsService _pointsService = PointsService();
  final UserService _userService = UserService();
  List<PointsTransactionModel> _transactions = [];
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _userService.getCurrentUser();
      final transactions = await _pointsService.getTransactionHistory();
      setState(() {
        _currentUser = user;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Puntos'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPointsHeader(theme, colorScheme),
                    const SizedBox(height: 24),
                    _buildHowToEarnSection(theme, colorScheme),
                    const SizedBox(height: 24),
                    _buildTransactionHistory(theme, colorScheme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPointsHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.tertiary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.tertiary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.stars_rounded,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Balance Total',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentUser?.points ?? 0}',
            style: theme.textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'puntos acumulados',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToEarnSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎁 Cómo ganar puntos',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildEarnMethodCard(
          icon: Icons.confirmation_num,
          title: 'Compra de Boletos',
          points: '10% del precio',
          color: colorScheme.primary,
        ),
        const SizedBox(height: 12),
        _buildEarnMethodCard(
          icon: Icons.shopping_bag,
          title: 'Compras en Tienda',
          points: '5% del precio',
          color: colorScheme.secondary,
        ),
        const SizedBox(height: 12),
        _buildEarnMethodCard(
          icon: Icons.how_to_vote,
          title: 'Votar en Paneles',
          points: '+5 puntos',
          color: colorScheme.tertiary,
        ),
        const SizedBox(height: 12),
        _buildEarnMethodCard(
          icon: Icons.qr_code_scanner,
          title: 'Check-in en Eventos',
          points: '+10 puntos',
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildEarnMethodCard(
          icon: Icons.share,
          title: 'Compartir en Redes',
          points: '+15 puntos',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildEarnMethodCard({
    required IconData icon,
    required String title,
    required String points,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            points,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📜 Historial de Transacciones',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay transacciones aún',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._transactions.map((transaction) =>
              _buildTransactionCard(transaction, theme, colorScheme)),
      ],
    );
  }

  Widget _buildTransactionCard(
    PointsTransactionModel transaction,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isEarn = transaction.type == TransactionType.earn;
    final color = isEarn ? Colors.green : Colors.red;
    final icon = isEarn ? Icons.add_circle : Icons.remove_circle;
    final sign = isEarn ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.reason,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy - HH:mm').format(transaction.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign${transaction.amount}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
