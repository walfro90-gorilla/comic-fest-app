import 'dart:convert';
import 'dart:io';
import 'package:comic_fest/core/supabase_service.dart';
import 'package:comic_fest/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  static const String keyPrefix = 'user_';
  SharedPreferences? _prefs;
  final SupabaseService _supabase = SupabaseService.instance;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<UserModel?> getCurrentUser() async {
    if (_prefs == null) await init();

    final userId = _supabase.userId;
    if (userId == null) return null;

    UserModel? cachedUser;
    final cachedJson = _prefs!.getString('$keyPrefix$userId');
    if (cachedJson != null) {
      try {
        cachedUser = UserModel.fromJson(jsonDecode(cachedJson));
      } catch (e) {
        debugPrint('⚠️ Failed to parse cached user: $e');
      }
    }
    
    try {
      final response = await _supabase.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final user = UserModel.fromJson(response);
      await _prefs!.setString('$keyPrefix$userId', jsonEncode(user.toJson()));
      debugPrint('✅ User synced from Supabase');
      return user;
    } catch (e) {
      debugPrint('⚠️ Using cached user: $e');
      return cachedUser;
    }
  }

  /// Forces a fresh fetch of the user profile from Supabase and updates local cache
  Future<void> fetchUserProfile() async {
    if (_prefs == null) await init();
    final userId = _supabase.userId;
    if (userId == null) return;

    try {
      final response = await _supabase.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final user = UserModel.fromJson(response);
      await _prefs!.setString('$keyPrefix$userId', jsonEncode(user.toJson()));
      debugPrint('✅ User profile force-refreshed from Supabase');
    } catch (e) {
      debugPrint('⚠️ Error fetching user profile: $e');
    }
  }

  Future<void> updateUserProfile({
    String? username,
    String? avatarUrl,
    String? bio,
  }) async {
    if (_prefs == null) await init();

    final userId = _supabase.userId;
    if (userId == null) throw Exception('No authenticated user');

    final currentUser = await getCurrentUser();
    if (currentUser == null) throw Exception('User not found');

    final updatedUser = currentUser.copyWith(
      username: username,
      avatarUrl: avatarUrl,
      bio: bio,
      updatedAt: DateTime.now(),
    );

    await _prefs!.setString('$keyPrefix$userId', jsonEncode(updatedUser.toJson()));

    try {
      await _supabase.client
          .from('profiles')
          .update(updatedUser.toJson())
          .eq('id', userId);
      debugPrint('✅ User profile updated on Supabase');
    } catch (e) {
      debugPrint('⚠️ User profile saved locally, will sync later: $e');
    }
  }

  Future<void> createUserProfile(UserModel user) async {
    if (_prefs == null) await init();

    await _prefs!.setString('$keyPrefix${user.id}', jsonEncode(user.toJson()));

    try {
      await _supabase.client.from('profiles').insert(user.toJson());
      debugPrint('✅ User profile created on Supabase');
    } catch (e) {
      debugPrint('⚠️ User profile saved locally, will sync later: $e');
    }
  }

  Future<void> updatePoints(int points) async {
    if (_prefs == null) await init();

    final userId = _supabase.userId;
    if (userId == null) return;

    final currentUser = await getCurrentUser();
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      points: currentUser.points + points,
      updatedAt: DateTime.now(),
    );

    await _prefs!.setString('$keyPrefix$userId', jsonEncode(updatedUser.toJson()));

    try {
      await _supabase.client
          .from('profiles')
          .update({'points': updatedUser.points})
          .eq('id', userId);
      debugPrint('✅ Points updated on Supabase');
    } catch (e) {
      debugPrint('⚠️ Points updated locally, will sync later: $e');
    }
  }

  Future<String> uploadAvatar(File imageFile) async {
    final userId = _supabase.userId;
    if (userId == null) throw Exception('No authenticated user');

    final fileExt = imageFile.path.split('.').last;
    final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = 'avatars/$fileName';

    try {
      // 1. Upload to Supabase Storage
      await _supabase.client.storage
          .from('avatars')
          .upload(filePath, imageFile);

      // 2. Get Public URL
      final avatarUrl = _supabase.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // 3. Update Profile
      await updateUserProfile(avatarUrl: avatarUrl);

      return avatarUrl;
    } catch (e) {
      debugPrint('❌ Avatar upload failed: $e');
      rethrow;
    }
  }

  // Admin methods
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabase.client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      final users = (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
      
      debugPrint('✅ Fetched ${users.length} users');
      return users;
    } catch (e) {
      debugPrint('❌ Error fetching users: $e');
      rethrow;
    }
  }

  Future<void> createUserByAdmin({
    required String email,
    required String password,
    required String username,
    required UserRole role,
  }) async {
    try {
      // Guarda los tokens de la sesión actual del admin
      final currentSession = _supabase.client.auth.currentSession;
      
      if (currentSession == null) {
        throw Exception('Admin must be logged in');
      }

      final adminAccessToken = currentSession.accessToken;
      final adminRefreshToken = currentSession.refreshToken;

      // Step 1: Create auth user with signUp (esto cambiará la sesión)
      final response = await _supabase.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null,
      );

      if (response.user == null) {
        throw Exception('Failed to create user');
      }

      final userId = response.user!.id;

      // Step 2: Update profile (trigger already created it) with the specified role and username
      await _supabase.client.from('profiles').update({
        'username': username,
        'role': role.name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      
      // Step 3: Restore admin session usando refreshSession
      await _supabase.client.auth.refreshSession(adminRefreshToken);
      
      debugPrint('✅ User created by admin: $email with role ${role.name}');
    } catch (e) {
      debugPrint('❌ Error creating user: $e');
      rethrow;
    }
  }

  Future<void> updateUserByAdmin({
    required String userId,
    String? username,
    UserRole? role,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (username != null) updates['username'] = username;
      if (role != null) updates['role'] = role.name;

      await _supabase.client
          .from('profiles')
          .update(updates)
          .eq('id', userId);

      debugPrint('✅ User updated by admin: $userId');
    } catch (e) {
      debugPrint('❌ Error updating user: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Solo podemos eliminar el perfil, no el auth user desde el cliente
      // El auth user debe ser eliminado desde Supabase Dashboard
      await _supabase.client
          .from('profiles')
          .delete()
          .eq('id', userId);
      
      debugPrint('✅ User profile deleted: $userId');
      debugPrint('ℹ️ Auth user must be deleted manually from Supabase Dashboard');
    } catch (e) {
      debugPrint('❌ Error deleting user: $e');
      rethrow;
    }
  }
}
