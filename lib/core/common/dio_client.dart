import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sportify_amateur/core/common/app_config.dart';

class DioClient {
  static String get backendUrl => AppConfig.apiBaseUrl;

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: backendUrl,
    connectTimeout: Duration(seconds: 5000),
    receiveTimeout: Duration(seconds: 5000),
    headers: {'Content-Type': 'application/json'},
  ));
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static void initialize() {
    // Agregar el interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Adjuntar token en cada solicitud
        final accessToken = await _storage.read(key: 'authToken');
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Si el token ha expirado
        if (error.response?.statusCode == 401) {
          final refreshToken = await _storage.read(key: 'refreshToken');
          if (refreshToken != null) {
            // Intentar renovar el token
            final success = await _refreshToken(refreshToken);
            if (success) {
              final retryRequest = await _retry(error.requestOptions);
              return handler.resolve(retryRequest);
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  static Dio get instance => _dio;

  static Future<bool> _refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });
      final newAccessToken = response.data['accessToken'];
      final newRefreshToken = response.data['refreshToken'];

      // Almacenar los nuevos tokens
      await _storage.write(key: 'authToken', value: newAccessToken);
      await _storage.write(key: 'refreshToken', value: newRefreshToken);
      return true;
    } catch (e) {
      // El refreshToken no es válido
      await _storage.deleteAll();
      return false;
    }
  }

  static Future<Response> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
