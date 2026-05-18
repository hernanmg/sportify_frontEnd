import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';

/// Registra tokens FCM en el backend. Llamar tras obtener el token
/// (p. ej. con firebase_messaging cuando esté configurado).
class DeviceService {
  final Dio _dio = DioClient.instance;

  Future<void> registerToken(String token, {String platform = 'web'}) async {
    await _dio.post('/devices/register', data: {
      'token': token,
      'platform': platform,
    });
  }

  Future<void> unregisterToken(String token) async {
    await _dio.delete('/devices/unregister', data: {'token': token});
  }
}
