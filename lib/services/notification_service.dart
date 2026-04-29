import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('ℹ️ NotificationService: skipping init on web');
      return;
    }

    // Solicitar permisos
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Permisos de notificación concedidos');

      // Obtener el token FCM
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }

      // Escuchar cuando el token se actualice
      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

      // Configurar notificaciones locales
      await _initializeLocalNotifications();

      // Manejar notificaciones en primer plano
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Manejar cuando el usuario toca la notificación
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('user_push_tokens').upsert({
        'user_id': userId,
        'device_token': token,
        'platform': 'android', // Cambiar dinámicamente según la plataforma
      });

      debugPrint('💾 Token FCM guardado: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('❌ Error guardando token: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('🔔 Notificación tocada: ${details.payload}');
      },
    );

    // Crear canal de notificaciones para Android (requerido para Android 8.0+)
    const androidChannel = AndroidNotificationChannel(
      'comic_fest_channel', // Debe coincidir con el ID en AndroidManifest
      'Comic Fest Notifications',
      description: 'Notificaciones del evento Comic Fest',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    debugPrint('✅ Canal de notificaciones creado: ${androidChannel.id}');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📬 Notificación recibida en primer plano');
    
    const androidDetails = AndroidNotificationDetails(
      'comic_fest_channel',
      'Comic Fest Notifications',
      channelDescription: 'Notificaciones del evento Comic Fest',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Comic Fest',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Usuario tocó la notificación: ${message.data}');
    // Aquí puedes navegar a una pantalla específica según message.data
  }

  /// Escuchar notificaciones en tiempo real desde Supabase
  void listenToRealtimeNotifications(Function(Map<String, dynamic>) onNotification) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    
    Supabase.instance.client
        .channel('notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onNotification(payload.newRecord);
          },
        )
        .subscribe();
  }
}
