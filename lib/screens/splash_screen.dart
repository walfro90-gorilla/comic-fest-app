import 'package:comic_fest/screens/auth/login_screen.dart';
import 'package:comic_fest/screens/home/home_nav_screen.dart';
import 'package:comic_fest/services/user_service.dart';
import 'package:comic_fest/supabase/supabase_config.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Verificar si hay una sesión activa en Supabase
      final session = SupabaseConfig.auth.currentSession;
      final user = SupabaseConfig.auth.currentUser;

      if (session != null && user != null) {
        debugPrint('✅ Sesión activa encontrada para: ${user.email}');

        // getCurrentUser ya sincroniza automáticamente desde Supabase
        final profile = await _userService.getCurrentUser();

        if (profile != null && mounted) {
          debugPrint('✅ Perfil cargado: ${profile.username} (${profile.role.name})');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeNavScreen()),
          );
          return;
        }
      }

      // No hay sesión activa, ir al login
      debugPrint('ℹ️ No hay sesión activa. Redirigiendo a Login...');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('❌ Error verificando estado de autenticación: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Image.asset(
                'assets/icons/comic_fest_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Cargando...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
