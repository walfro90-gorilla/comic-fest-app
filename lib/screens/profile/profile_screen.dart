import 'package:comic_fest/core/supabase_service.dart';
import 'package:comic_fest/models/user_model.dart';
import 'package:comic_fest/screens/auth/login_screen.dart';
import 'package:comic_fest/screens/admin/admin_panel_screen.dart';
import 'package:comic_fest/services/user_service.dart';
import 'package:comic_fest/screens/profile/payment_history_screen.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);

    try {
      final user = await _userService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await SupabaseService.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text('No se pudo cargar el perfil'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: colorScheme.primaryContainer,
                        child: _currentUser!.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  _currentUser!.avatarUrl!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 60,
                                color: colorScheme.primary,
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentUser!.displayName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_currentUser!.email != null)
                        Text(
                          _currentUser!.email!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(_currentUser!.role.name.toUpperCase()),
                        backgroundColor: colorScheme.secondaryContainer,
                      ),
                      const SizedBox(height: 32),
                      if (_currentUser!.role == UserRole.admin)
                        _buildMenuCard(
                          theme,
                          colorScheme,
                          icon: Icons.admin_panel_settings,
                          title: 'Panel de Administración',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AdminPanelScreen(),
                              ),
                            );
                          },
                        ),
                      _buildMenuCard(
                        theme,
                        colorScheme,
                        icon: Icons.confirmation_num_outlined,
                        title: 'Mis Boletos',
                        onTap: () {
                          Navigator.of(context).pushNamed('/my-tickets');
                        },
                      ),
                      _buildMenuCard(
                        theme,
                        colorScheme,
                        icon: Icons.stars_outlined,
                        title: 'Mis Puntos: ${_currentUser!.points}',
                        onTap: () {},
                      ),
                      _buildMenuCard(
                        theme,
                        colorScheme,
                        icon: Icons.history,
                        title: 'Historial de Compras',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PaymentHistoryScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        theme,
                        colorScheme,
                        icon: Icons.favorite_outline,
                        title: 'Eventos Favoritos',
                        onTap: () {},
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _signOut,
                        icon: Icon(Icons.logout, color: colorScheme.error),
                        label: Text(
                          'Cerrar Sesión',
                          style: TextStyle(color: colorScheme.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMenuCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(title),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        onTap: onTap,
      ),
    );
  }
}
