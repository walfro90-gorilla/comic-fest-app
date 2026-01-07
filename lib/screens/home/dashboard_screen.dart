import 'package:comic_fest/core/connectivity_service.dart';
import 'package:comic_fest/models/contest_model.dart';
import 'package:comic_fest/models/event_model.dart';
import 'package:comic_fest/models/exhibitor_model.dart';
import 'package:comic_fest/models/product_model.dart';
import 'package:comic_fest/models/promotion_model.dart';
import 'package:comic_fest/models/user_model.dart';
import 'package:comic_fest/services/contest_service.dart';
import 'package:comic_fest/services/event_service.dart';
import 'package:comic_fest/services/exhibitor_service.dart';
import 'package:comic_fest/services/product_service.dart';
import 'package:comic_fest/services/promotion_service.dart';
import 'package:comic_fest/services/user_service.dart';
import 'package:comic_fest/widgets/event_card.dart';
import 'package:comic_fest/widgets/points_badge.dart';
import 'package:comic_fest/widgets/empty_state_card.dart';
import 'package:comic_fest/widgets/welcome_modal.dart';
import 'package:comic_fest/widgets/retro_points_modal.dart';
import 'package:comic_fest/widgets/feedback_survey_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:comic_fest/screens/points/points_screen.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _getUserLevel(int points) {
    if (points < 1000) return 'NIVEL 1 • NOVATO';
    if (points < 5000) return 'NIVEL 5 • FAN';
    if (points < 20000) return 'NIVEL 10 • SUPER FAN';
    return 'NIVEL 99 • LEYENDA';
  }

  final UserService _userService = UserService();
  final EventService _eventService = EventService();
  final ExhibitorService _exhibitorService = ExhibitorService();
  final PromotionService _promotionService = PromotionService();
  final ProductService _productService = ProductService();
  final ContestService _contestService = ContestService();
  
  UserModel? _currentUser;
  List<EventModel> _upcomingEvents = [];
  List<ExhibitorModel> _featuredExhibitors = [];
  List<PromotionModel> _flashPromotions = [];
  List<ProductModel> _exclusiveProducts = [];
  List<ContestModel> _activeContests = [];
  bool _isLoading = true;
  bool _isOnline = false;
  bool _surveyCompleted = true; // Empieza en true para no mostrar el botón por error

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenToConnectivity();
    _checkFirstLogin();
  }

  Future<void> _checkFirstLogin() async {
    // Esperar a que el usuario esté cargado para tener su ID
    int attempts = 0;
    while (_currentUser == null && attempts < 50 && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!mounted || _currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    // Clave única por usuario para que funcione correctamente en registros reales
    final userKey = 'is_first_login_v4_${_currentUser!.id}';
    final isFirstLogin = prefs.getBool(userKey) ?? true;

    if (isFirstLogin && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        
        // 1. Bienvenida con Confeti
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const WelcomeModal(),
        );
        
        // 2. Bono 500 XP (Pokemon Style)
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const RetroPointsModal(),
          );
        }

        // 3. Encuesta de Invitados (1500 XP)
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const FeedbackSurveyModal(),
          );
        }
        
        await prefs.setBool(userKey, false);
        _loadData(); // Recargar puntos al final
      });
    }
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
      final exhibitors = await _exhibitorService.getFeaturedExhibitors();
      final promotions = await _promotionService.getActiveFlashPromotions();
      final products = await _productService.getExclusiveProducts();
      final contests = await _contestService.getActiveContests();
      
      final prefs = await SharedPreferences.getInstance();
      final surveyKey = 'survey_completed_${user?.id}';
      final completed = prefs.getBool(surveyKey) ?? false;

      setState(() {
        _currentUser = user;
        _upcomingEvents = events.take(5).toList();
        _featuredExhibitors = exhibitors;
        _flashPromotions = promotions;
        _exclusiveProducts = products;
        _activeContests = contests;
        _surveyCompleted = completed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    
    // 1. Mostrar opciones: Cámara o Galería
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_front_rounded),
              title: const Text('Tomar Foto (Frontal)'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Elegir de Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    // 2. Capturar imagen
    final XFile? image = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image != null && mounted) {
      setState(() => _isLoading = true);
      try {
        await _userService.uploadAvatar(File(image.path));
        await _loadData(); // Recargar perfil
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar actualizado correctamente ✨')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Falló la carga: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentUser != null ? 'Okaeri, ${_currentUser!.username ?? 'Hero'}' : 'Comic Fest 2026',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            if (_currentUser != null)
              Text(
                'Nivel: ${_getUserLevel(_currentUser!.points).split(' • ').last}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        actions: [
          // Botón Notificaciones
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Próximamente: Sistema de Notificaciones')),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                ),
              ),
            ],
          ),
          // Radar Otaku (Acceso al Mapa o Búsqueda)
          IconButton(
            icon: const Icon(Icons.radar_rounded),
            tooltip: 'Radar de Eventos',
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Iniciando Radar de Expositores...')),
              );
            },
          ),
          if (_currentUser != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PointsScreen()),
                  );
                  _loadData();
                },
                child: PointsBadge(points: _currentUser!.points),
              ),
            ),
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
      floatingActionButton: (!_surveyCompleted && !_isLoading && _currentUser != null)
          ? FloatingActionButton.extended(
              onPressed: () async {
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const FeedbackSurveyModal(),
                );
                _loadData(); // Refrescar para ver si ya se completó
              },
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.stars),
              label: const Text('¡GANA 1500 XP!'),
            )
          : null,
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
                    _buildSectionTitle('⚡ Promociones Flash', theme),
                    const SizedBox(height: 12),
                    if (_flashPromotions.isEmpty)
                      const EmptyStateCard()
                    else
                      _buildFlashPromotions(theme, colorScheme),
                    const SizedBox(height: 24),

                    _buildSectionTitle('🏆 Concursos Activos', theme),
                    const SizedBox(height: 12),
                    if (_activeContests.isEmpty)
                      const EmptyStateCard()
                    else
                      _buildActiveContests(theme, colorScheme),
                    const SizedBox(height: 24),

                    _buildSectionTitle('💎 Productos Exclusivos', theme),
                    const SizedBox(height: 12),
                    if (_exclusiveProducts.isEmpty)
                      const EmptyStateCard()
                    else
                      _buildExclusiveProducts(theme, colorScheme),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Expositores Destacados', theme),
                    const SizedBox(height: 12),
                    if (_featuredExhibitors.isEmpty)
                      const EmptyStateCard()
                    else
                      _buildFeaturedExhibitors(theme),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Próximos Eventos', theme),
                    const SizedBox(height: 12),
                    if (_upcomingEvents.isEmpty)
                      const EmptyStateCard()
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
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2A0845), // Deep Purple
            Color(0xFF6441A5), // Purple
            Color(0xFF43CBFF), // Neon Blue accent
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6441A5).withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Decorative background elements
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.gamepad,
              size: 150,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF43CBFF), width: 2),
                      ),
                      child: InkWell(
                        onTap: _pickAndUploadImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.black26,
                              child: ClipOval(
                                child: _currentUser?.avatarUrl != null
                                    ? Image.network(
                                        _currentUser!.avatarUrl!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(
                                            child: Text(
                                              (_currentUser?.displayName?.isNotEmpty == true)
                                                  ? _currentUser!.displayName![0].toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Text(
                                        (_currentUser?.displayName?.isNotEmpty == true)
                                            ? _currentUser!.displayName![0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF43CBFF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentUser?.displayName ?? 'Jugador',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getUserLevel(_currentUser?.points ?? 0),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF43CBFF),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Points Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF43CBFF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MIS PUNTOS',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${_currentUser?.points ?? 0}',
                                style: const TextStyle(
                                  color: Color(0xFFFFD700), // Gold
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Courier', // Monospace feel
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'XP',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Progress Bar (Visual only for now)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ((_currentUser?.points ?? 0) / 500).clamp(0.0, 1.0),
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E676)), // Neon Green
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Próxima recompensa: 500 XP',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '${(((_currentUser?.points ?? 0) / 500).clamp(0.0, 1.0) * 100).toInt()}%',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

  Widget _buildFlashPromotions(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _flashPromotions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final promo = _flashPromotions[index];
          return Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD700).withValues(alpha: 0.2),
                  const Color(0xFFFF8C00).withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt, color: const Color(0xFFFF8C00), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        promo.exhibitorName ?? 'Expositor',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (promo.discountPercent != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C00),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${promo.discountPercent}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  promo.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Termina: ${DateFormat('HH:mm').format(promo.validUntil)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveContests(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _activeContests.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final contest = _activeContests[index];
          return Container(
            width: 240,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        contest.category.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  contest.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: () {
                    // Navigate to contest details
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(32),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Votar Ahora'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExclusiveProducts(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _exclusiveProducts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = _exclusiveProducts[index];
          return Container(
            width: 140,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: product.imageUrl != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.shopping_bag,
                              size: 40,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
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

  Widget _buildFeaturedExhibitors(ThemeData theme) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _featuredExhibitors.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final exhibitor = _featuredExhibitors[index];
          return Container(
            width: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primaryContainer,
                  ),
                  child: ClipOval(
                    child: exhibitor.avatarUrl != null
                        ? Image.network(
                            exhibitor.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  exhibitor.companyName.isNotEmpty
                                      ? exhibitor.companyName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              exhibitor.companyName.isNotEmpty
                                  ? exhibitor.companyName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    exhibitor.companyName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
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
