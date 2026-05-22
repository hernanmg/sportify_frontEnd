import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sportify_amateur/core/common/app_config.dart';
import 'package:sportify_amateur/core/navigation/app_navigator.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/device_service.dart';
import 'package:sportify_amateur/core/services/notification_service.dart';

/// Canal Android (debe coincidir con AndroidManifest y backend FCM).
const String kAndroidNotificationChannelId = 'sportify_alerts';

/// Registra el token FCM en el backend tras login (web / Android / iOS).
class PushRegistrationService {
  PushRegistrationService._();
  static final PushRegistrationService instance = PushRegistrationService._();

  final _deviceService = DeviceService();
  final _authStorage = AuthStorageService();
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _initializeFcm();
    } catch (e) {
      debugPrint('FCM initialize: $e');
    }
  }

  Future<void> _initializeFcm() async {
    await _setupLocalNotifications();
    await _requestNotificationPermission();

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

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onMessageOpenedApp(initial);
      });
    }

    final token = await _fetchToken(messaging);
    if (token != null) {
      await _registerIfLoggedIn(token);
    }

    messaging.onTokenRefresh.listen((token) {
      _registerIfLoggedIn(token);
    });
  }

  Future<void> _setupLocalNotifications() async {
    if (kIsWeb) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handlePayloadNavigation(payload);
        }
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      final plugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await plugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          kAndroidNotificationChannelId,
          'Alertas Sportify',
          description: 'Convocatorias, lesiones y avisos del equipo',
          importance: Importance.high,
        ),
      );
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid) return;
    final status = await Permission.notification.status;
    if (status.isGranted) return;
    await Permission.notification.request();
  }

  void _onForegroundMessage(RemoteMessage message) {
    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ??
        message.data['message']?.toString() ??
        message.data['body']?.toString();
    debugPrint('FCM foreground: $title');
    if (kIsWeb) return;

    NotificationService().refreshUnreadCount();

    if (title == null || title.isEmpty) return;

    final action = message.data['action'] ?? '';
    final deepLink = message.data['deepLink'] ?? '';
    final payload = 'action=$action&deepLink=$deepLink&teamId=${message.data['teamId'] ?? ''}';

    _localNotifications.show(
      message.hashCode,
      title,
      body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          kAndroidNotificationChannelId,
          'Alertas Sportify',
          channelDescription: 'Convocatorias, lesiones y avisos del equipo',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    AppNavigator.openFromPushData(Map<String, dynamic>.from(message.data));
  }

  void _handlePayloadNavigation(String payload) {
    final data = <String, dynamic>{};
    for (final part in payload.split('&')) {
      final kv = part.split('=');
      if (kv.length == 2) data[kv[0]] = kv[1];
    }
    AppNavigator.openFromPushData(data);
  }

  /// Llamar después de login exitoso.
  Future<void> registerAfterLogin() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await _fetchToken(messaging);
      if (token != null) {
        await _deviceService.registerToken(token, platform: _platformName());
        debugPrint('FCM: token registrado en backend (${_platformName()})');
      }
    } catch (e) {
      debugPrint('FCM registerAfterLogin: $e');
    }
  }

  /// Quitar token del backend al cerrar sesión.
  Future<void> unregisterOnLogout() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _deviceService.unregisterToken(token);
      }
    } catch (e) {
      debugPrint('FCM unregisterOnLogout: $e');
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
    try {
      final jwt = await _authStorage.getToken();
      if (jwt == null || jwt.isEmpty) return;
      await _deviceService.registerToken(token, platform: _platformName());
      debugPrint('FCM: token registrado en backend (${_platformName()})');
    } catch (e) {
      // Sin sesión o JWT vencido al abrir la app: no bloquear el arranque.
      debugPrint('FCM: registro de token omitido (sesión no válida aún): $e');
    }
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return defaultTargetPlatform.name;
    }
  }
}
