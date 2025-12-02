import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:comic_fest/auth/auth_manager.dart';
import 'package:comic_fest/models/user_model.dart';
import 'package:comic_fest/supabase/supabase_config.dart';
import 'package:comic_fest/services/user_service.dart';

class SupabaseAuthManager extends AuthManager
    with EmailSignInManager, GoogleSignInManager {
  final sb.SupabaseClient _client = SupabaseConfig.client;
  final UserService _userService = UserService();

  @override
  Future<UserModel?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // ⚠️ Verificar si el email está confirmado
        if (response.user!.emailConfirmedAt == null) {
          debugPrint('❌ Email no confirmado');
          if (context.mounted) {
            _showError(context, 'Debes confirmar tu email antes de iniciar sesión.');
          }
          await _client.auth.signOut();
          return null;
        }
        return await _fetchOrCreateProfile(response.user!);
      }
      return null;
    } on sb.AuthException catch (e) {
      debugPrint('❌ Auth error: ${e.message}');
      if (context.mounted) {
        _showError(context, e.message);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Sign in error: $e');
      if (context.mounted) {
        _showError(context, 'Error de conexión. Intenta nuevamente.');
      }
      return null;
    }
  }

  Future<UserModel?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password, {
    String? username,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // ⚠️ Verificar si el email está confirmado
        if (response.user!.emailConfirmedAt == null) {
          debugPrint('📧 Email no confirmado. Usuario debe verificar su correo.');
          if (context.mounted) {
            _showSuccess(context, 'Revisa tu correo para confirmar tu cuenta.');
          }
          // Cerrar sesión inmediatamente para forzar confirmación
          await _client.auth.signOut();
          return null;
        }

        // Crear perfil automáticamente (solo si está confirmado)
        final user = UserModel(
          id: response.user!.id,
          email: email,
          username: username ?? email.split('@').first,
          role: UserRole.attendee,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _userService.createUserProfile(user);
        return user;
      }
      return null;
    } on sb.AuthException catch (e) {
      debugPrint('❌ Auth error: ${e.message}');
      if (context.mounted) {
        _showError(context, e.message);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Sign up error: $e');
      if (context.mounted) {
        _showError(context, 'Error al crear cuenta. Intenta nuevamente.');
      }
      return null;
    }
  }

  @override
  Future<UserModel?> createAccount(
    BuildContext context,
    String email,
    String password,
  ) async {
    return createAccountWithEmail(context, email, password);
  }

  @override
  Future<UserModel?> signInWithGoogle(BuildContext context) async {
    try {
      // 1. Iniciar flujo nativo de Google
      final GoogleSignIn googleSignIn = GoogleSignIn(
        // serverClientId es necesario para obtener el ID Token válido para Supabase
        // Este ID debe coincidir con el "Web Client ID" en Google Cloud Console
        // y estar agregado en Supabase > Auth > Providers > Google
        serverClientId: '241329411586-4dqh24bs0cgsahq16qqhgrq690ek9nhm.apps.googleusercontent.com', 
      );
      
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // El usuario canceló el inicio de sesión
        return null;
      }

      // 2. Obtener credenciales de autenticación (tokens)
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      // 3. Autenticar con Supabase usando el ID Token
      final response = await _client.auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // 4. Verificar y crear/obtener perfil
      if (response.user != null) {
        return await _fetchOrCreateProfile(response.user!);
      }
      
      return null;
    } on sb.AuthException catch (e) {
      debugPrint('❌ Google auth error: ${e.message}');
      if (context.mounted) {
        _showError(context, 'Error de autenticación: ${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('❌ Google sign in error: $e');
      if (context.mounted) {
        _showError(context, 'Error al conectar con Google. Verifica tu conexión.');
      }
      return null;
    }
  }

  @override
  Future signOut() async {
    try {
      await _client.auth.signOut();
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
    }
  }

  @override
  Future deleteUser(BuildContext context) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Eliminar perfil primero
      await _client.from('profiles').delete().eq('id', user.id);
      
      // Nota: La eliminación del usuario de auth.users se maneja automáticamente
      // gracias a ON DELETE CASCADE en la base de datos
      
      debugPrint('✅ User deleted successfully');
    } catch (e) {
      debugPrint('❌ Delete user error: $e');
      if (context.mounted) {
        _showError(context, 'Error al eliminar cuenta.');
      }
    }
  }

  @override
  Future updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await _client.auth.updateUser(sb.UserAttributes(email: email));
      debugPrint('✅ Email updated successfully');
      if (context.mounted) {
        _showSuccess(context, 'Email actualizado. Verifica tu nuevo correo.');
      }
    } on sb.AuthException catch (e) {
      debugPrint('❌ Update email error: ${e.message}');
      if (context.mounted) {
        _showError(context, e.message);
      }
    }
  }

  @override
  Future resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      if (context.mounted) {
        _showSuccess(context, 'Revisa tu correo para restablecer tu contraseña.');
      }
    } on sb.AuthException catch (e) {
      debugPrint('❌ Reset password error: ${e.message}');
      if (context.mounted) {
        _showError(context, e.message);
      }
    }
  }

  // Helpers privados
  Future<UserModel?> _fetchOrCreateProfile(sb.User authUser) async {
    try {
      // Intentar obtener perfil existente
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (response != null) {
        return UserModel.fromJson(response);
      }

      // Si no existe, crear perfil
      final newUser = UserModel(
        id: authUser.id,
        email: authUser.email,
        username: authUser.userMetadata?['name'] ?? authUser.email?.split('@').first,
        avatarUrl: authUser.userMetadata?['avatar_url'],
        role: UserRole.attendee,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _userService.createUserProfile(newUser);
      return newUser;
    } catch (e) {
      debugPrint('❌ Error fetching/creating profile: $e');
      return null;
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
