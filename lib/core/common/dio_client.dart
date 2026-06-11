import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sportify_amateur/core/common/app_config.dart';

class DioClient {
  static String get backendUrl => AppConfig.apiBaseUrl;

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: backendUrl,
    // Render free tier puede tardar >30s en despertar (cold start).
    connectTimeout: const Duration(seconds: 90),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static bool _isPublicAuthPath(String path) {
    final p = path.split('?').first;
    const public = <String>{
      '/auth/login',
      '/auth/register',
      '/auth/refresh',
      '/auth/google/token',
    };
    return public.contains(p);
  }

  static void initialize() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!_isPublicAuthPath(options.path)) {
          final accessToken = await _storage.read(key: 'authToken');
          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final path = error.requestOptions.path.split('?').first;
        final alreadyRetried =
            error.requestOptions.extra['auth_retry'] == true;

        if (status != 401 ||
            _isPublicAuthPath(path) ||
            path == '/auth/refresh' ||
            alreadyRetried) {
          return handler.next(error);
        }

        final refreshToken = await _storage.read(key: 'refreshToken');
        if (refreshToken == null || refreshToken.isEmpty) {
          return handler.next(error);
        }

        final success = await _refreshToken(refreshToken);
        if (!success) {
          return handler.next(error);
        }

        try {
          final retryResponse = await _retry(error.requestOptions);
          return handler.resolve(retryResponse);
        } catch (e) {
          return handler.next(error);
        }
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

      await _storage.write(key: 'authToken', value: newAccessToken);
      await _storage.write(key: 'refreshToken', value: newRefreshToken);
      return true;
    } catch (e) {
      await _storage.delete(key: 'authToken');
      await _storage.delete(key: 'refreshToken');
      return false;
    }
  }

  static Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final accessToken = await _storage.read(key: 'authToken');
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: headers,
        extra: {...requestOptions.extra, 'auth_retry': true},
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
      ),
    );
  }
}
