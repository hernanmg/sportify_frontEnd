import 'dart:async';

class NotificationsService {
  final Map<int, StreamController<String>> _notificacionesPorPartido = {};

  // Inicializar un stream para un partido
  void inicializarNotificacionesParaPartido(int partidoId) {
    if (!_notificacionesPorPartido.containsKey(partidoId)) {
      _notificacionesPorPartido[partidoId] = StreamController<String>.broadcast();
    }
  }

  // Obtener el stream de notificaciones para un partido
  Stream<String> obtenerNotificacionesParaPartido(int partidoId) {
    inicializarNotificacionesParaPartido(partidoId);
    return _notificacionesPorPartido[partidoId]!.stream;
  }

  // Emitir una notificación
  void emitirNotificacion(int partidoId, String mensaje) {
    if (_notificacionesPorPartido.containsKey(partidoId)) {
      _notificacionesPorPartido[partidoId]!.add(mensaje);
    }
  }

  // Limpiar recursos al finalizar
  void limpiarRecursos() {
    _notificacionesPorPartido.forEach((_, controller) => controller.close());
  }
}
