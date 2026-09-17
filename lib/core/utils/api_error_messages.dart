import 'package:dio/dio.dart';

/// Mensajes de error de API amigables (incl. cold start de Render).
class ApiErrorMessages {
  ApiErrorMessages._();

  static const coldStart =
      'El servidor está despertando (Render). Esperá unos segundos e intentá de nuevo.';

  static const connection =
      'No hay conexión con el servidor. Revisá internet o reintentá en unos segundos.';

  static bool isColdStartLike(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  static String from(Object error, {String fallback = 'Ocurrió un error'}) {
    if (error is! DioException) {
      final s = error.toString();
      if (s.startsWith('Exception: ')) return s.substring(11);
      return s.isEmpty ? fallback : s;
    }

    if (isColdStartLike(error)) {
      if (error.type == DioExceptionType.connectionError) {
        return connection;
      }
      return coldStart;
    }

    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is List) {
        return message.map((e) => e.toString()).join('\n');
      }
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    final status = error.response?.statusCode;
    if (status == 401) return 'Sesión vencida. Volvé a iniciar sesión.';
    if (status == 403) return 'No tenés permisos para esta acción.';
    if (status == 404) return 'No se encontró el recurso.';
    if (status != null && status >= 500) {
      return 'El servidor no respondió bien ($status). Reintentá en unos segundos.';
    }

    return fallback;
  }
}
