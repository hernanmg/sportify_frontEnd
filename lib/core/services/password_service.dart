import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';

class PasswordService {
  final Dio _dio = DioClient.instance;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.put('/users/profile/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      if (response.statusCode != 200) {
        throw Exception('Error al cambiar la contraseña');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('La contraseña actual es incorrecta');
      } else if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Error en la solicitud';
        throw Exception(message);
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}
