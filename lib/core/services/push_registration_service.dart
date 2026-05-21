import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:sportify_amateur/core/common/app_config.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/device_service.dart';

/// Registra el token FCM en el backend tras login (web / móvil).
class PushRegistrationService {
  PushRegistrationService._();
  static final PushRegistrationService instance = PushRegistrationService._();

  final _deviceService = DeviceService();
  final _authStorage = AuthStorageService();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;

    if (kIsWeb) {
      final vapid = AppConfig.fcmVapidKey;
      if (vapid.isEmpty) {
        debugPrint(
          'FCM web: definí FCM_VAPID_KEY (--dart-define) o generá el par en Firebase Console.',
        );
        return;
      }
    }

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM: permiso de notificaciones denegado');
      return;
    }

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground: ${message.notification?.title}');
    });

    final token = await _fetchToken(messaging);
    if (token != null) {
      await _registerIfLoggedIn(token);
    }

    messaging.onTokenRefresh.listen(_registerIfLoggedIn);
  }

  /// Llamar después de login exitoso.
  Future<void> registerAfterLogin() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await _fetchToken(messaging);
      if (token != null) {
        await _deviceService.registerToken(
          token,
          platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
        );
        debugPrint('FCM: token registrado en backend');
      }
    } catch (e) {
      debugPrint('FCM registerAfterLogin: $e');
    }
  }

  Future<String?> _fetchToken(FirebaseMessaging messaging) async {
    try {
      if (kIsWeb) {
        return messaging.getToken(vapidKey: AppConfig.fcmVapidKey);
      }
      return messaging.getToken();
    } catch (e) {
      debugPrint('FCM getToken: $e');
      return null;
    }
  }

  Future<void> _registerIfLoggedIn(String token) async {
    final jwt = await _authStorage.getToken();
    if (jwt == null || jwt.isEmpty) return;
    await _deviceService.registerToken(
      token,
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
    );
  }
}
