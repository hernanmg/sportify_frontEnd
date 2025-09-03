class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
// flutter build apk --dart-define=API_BASE_URL=https://prod.api.example.com
// flutter build apk --dart-define=API_BASE_URL=https://dev.api.example.com
