import 'package:comic_fest/core/connectivity_service.dart';
import 'package:comic_fest/models/event_model.dart';
import 'package:comic_fest/models/user_model.dart';
import 'package:comic_fest/services/event_service.dart';
import 'package:comic_fest/services/user_service.dart';
import 'package:comic_fest/widgets/event_card.dart';
import 'package:comic_fest/widgets/points_badge.dart';
import 'package:comic_fest/screens/points/points_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final UserService _userService = UserService();
  final EventService _eventService = EventService();
  UserModel? _currentUser;
  List<EventModel> _upcomingEvents = [];
  bool _isLoading = true;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenToConnectivity();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  void _listenToConnectivity() {
    ConnectivityService.instance.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
      }
    });
    _isOnline = ConnectivityService.instance.isOnline;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = await _userService.getCurrentUser();
      final events = await _eventService.getUpcomingEvents();

      setState(() {
        _currentUser = user;
        _upcomingEvents = events.take(5).toList();
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
        title: const Text('Comic Fest 2025'),
        actions: [
          if (!_isOnline)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.cloud_off,
                color: colorScheme.error,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentUser != null) ...[
                      _buildWelcomeCard(theme, colorScheme),
                      const SizedBox(height: 24),
                      _buildQuickActions(theme, colorScheme),
                      const SizedBox(height: 24),
                    ],
                    _buildSectionTitle('Próximos Eventos', theme),
                    const SizedBox(height: 12),
                    if (_upcomingEvents.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No hay eventos programados',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      )
                    else
                      ..._upcomingEvents.map((event) => EventCard(event: event)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(ThemeData theme, ColorScheme colorScheme) {
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
          Text(
            '¡Hola, ${_currentUser!.displayName}! 👋',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ciudad Juárez, Chihuahua',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PointsScreen()),
              );
              _loadData();
            },
            child: PointsBadge(points: _currentUser!.points),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.confirmation_num,
                color: colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Aún no tienes tu boleto?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Compra tu acceso al festival',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () async {
                  await Navigator.of(context).pushNamed('/buy-tickets');
                  _loadData();
                },
                child: const Text('Comprar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.qr_code,
                label: 'Mis Boletos',
                color: colorScheme.tertiary,
                onTap: () async {
                  await Navigator.of(context).pushNamed('/my-tickets');
                  _loadData();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.stars,
                label: 'Puntos',
                color: colorScheme.secondary,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PointsScreen()),
                  );
                  _loadData();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.local_offer,
                label: 'Promociones',
                color: colorScheme.primary,
                onTap: () async {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Future<void> Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
