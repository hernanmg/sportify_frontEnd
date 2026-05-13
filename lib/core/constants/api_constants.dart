import '../common/app_config.dart';

class ApiConstants {
  // URL base HTTP
  static String get baseUrl => AppConfig.apiBaseUrl;
  
  // URL base WebSocket
  static String get wsBaseUrl {
    final httpUrl = AppConfig.apiBaseUrl;
    // Convertir HTTP a WebSocket
    if (httpUrl.startsWith('https://')) {
      return httpUrl.replaceFirst('https://', 'wss://');
    } else if (httpUrl.startsWith('http://')) {
      return httpUrl.replaceFirst('http://', 'ws://');
    }
    return 'ws://localhost:3000'; // Fallback
  }

  // Endpoints HTTP
  static const String auth = '/auth';
  static const String users = '/users';
  static const String teams = '/teams';
  static const String events = '/events';
  static const String sportEvents = '/sport-events';
  static const String convocations = '/convocations';
  static const String notifications = '/notifications';
  static const String roster = '/roster';
  static const String roles = '/roles';
  static const String permissions = '/permissions';

  // Endpoints WebSocket
  static const String wsNotifications = '/notifications';

  // Headers comunes
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // WebSocket
  static const Duration wsReconnectDelay = Duration(seconds: 3);
  static const Duration wsHeartbeatInterval = Duration(seconds: 30);
}
