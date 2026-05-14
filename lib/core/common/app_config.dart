import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

import 'platform_is_android.dart';

class AppConfig {
  // URL base según plataforma
  static const String _defaultWebUrlDev = 'http://localhost:3000';
  static const String _defaultWebUrlProd = 'https://app.tudominio.com';
  /// iOS simulator / escritorio: el host es localhost.
  static const String _defaultMobileDebugLocalhost = 'http://localhost:3000';
  /// Emulador Android: localhost sería el propio emulador; 10.0.2.2 es el PC anfitrión.
  static const String _defaultAndroidEmulatorDev = 'http://10.0.2.2:3000';
  static const String _defaultAndroidUrlProd = 'https://api.tudominio.com';

  // Dart-define para API y GOOGLE_CLIENT_ID
  static const String _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _envGoogleClientId =
      String.fromEnvironment('GOOGLE_CLIENT_ID');

  /// URL base según entorno
  static String get apiBaseUrl {
    if (_envApiBaseUrl.isNotEmpty) {
      return _envApiBaseUrl;
    }

    if (kIsWeb) {
      return kDebugMode ? _defaultWebUrlDev : _defaultWebUrlProd;
    }
    if (kDebugMode) {
      return platformIsAndroid
          ? _defaultAndroidEmulatorDev
          : _defaultMobileDebugLocalhost;
    }
    return _defaultAndroidUrlProd;
  }

  /// Devuelve Google Client ID
  static String get googleClientId {
    if (_envGoogleClientId.isNotEmpty) {
      return _envGoogleClientId;
    }

    if (kDebugMode) {
      // fallback automático solo en debug
      return '643857245475-re1l4hhi8rhrkog5tmp8fr41glr10msr.apps.googleusercontent.com';
    }

    throw Exception(
      'Google Client ID no definido. Pasalo con --dart-define=GOOGLE_CLIENT_ID=...',
    );
  }
}

// flutter build apk --dart-define=API_BASE_URL=https://prod.api.example.com
// flutter build apk --dart-define=API_BASE_URL=https://dev.api.example.com
