import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;
  String? get userId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;

  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
      );
      debugPrint('✅ Supabase initialized');
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Sign in successful: ${response.user?.email}');
      return response;
    } catch (e) {
      debugPrint('❌ Sign in failed: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      debugPrint('✅ Sign up successful: ${response.user?.email}');
      return response;
    } catch (e) {
      debugPrint('❌ Sign up failed: $e');
      rethrow;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.comicfest://login-callback/',
      );
      debugPrint('✅ Google sign in initiated');
      return true;
    } catch (e) {
      debugPrint('❌ Google sign in failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
      debugPrint('✅ Sign out successful');
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      rethrow;
    }
  }

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
