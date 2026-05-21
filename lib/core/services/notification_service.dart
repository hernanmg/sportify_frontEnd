import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/notification.dart';
import 'websocket_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    _initializeWebSocket();
  }

  final Dio _dio = DioClient.instance;
  final WebSocketService _wsService = WebSocketService();
  static bool _wsListenersRegistered = false;
  final StreamController<List<NotificationModel>> _notificationsController =
      StreamController<List<NotificationModel>>.broadcast();

  // Stream para notificaciones individuales en tiempo real
  final StreamController<NotificationModel> _newNotificationController =
      StreamController<NotificationModel>.broadcast();
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();
  Timer? _pollTimer;
  int _lastUnread = 0;

  Stream<List<NotificationModel>> get notificationsStream =>
      _notificationsController.stream;

  Stream<NotificationModel> get newNotificationStream =>
      _newNotificationController.stream;

  Stream<int> get unreadCountStream => _unreadCountController.stream;

  void _initializeWebSocket() {
    _wsService.connect();
    if (_wsListenersRegistered) return;
    _wsListenersRegistered = true;

    _wsService.onNotificationReceived((data) {
      debugPrint('🔔 Nueva notificación via WebSocket: ${data['title']}');
      
      try {
        final notification = NotificationModel.fromJson(data);
        _newNotificationController.add(notification);
        refreshUnreadCount();
      } catch (e) {
        debugPrint('❌ Error procesando notificación WebSocket: $e');
      }
    });

    // Manejar conexión WebSocket
    _wsService.onConnected((data) {
      debugPrint('✅ WebSocket conectado para notificaciones');
      refreshUnreadCount();
    });

    _wsService.onError((data) {
      debugPrint('❌ Error WebSocket notificaciones: ${data['message']}');
    });
  }

  // Obtener notificaciones del usuario
  Future<List<NotificationModel>> getMyNotifications({int limit = 50}) async {
    try {
      print('🔔 Fetching notifications...');
      final response = await _dio.get('/notifications/my', queryParameters: {
        'limit': limit,
      });

      print('📡 Response status: ${response.statusCode}');
      print('📊 Response data length: ${response.data?.length ?? 0}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final notifications =
            data.map((json) => NotificationModel.fromJson(json)).toList();

        print('✅ Parsed ${notifications.length} notifications');
        for (var notif in notifications.take(3)) {
          print('   - ${notif.title} (${notif.type.value})');
        }

        // Actualizar stream
        _notificationsController.add(notifications);
        return notifications;
      }
      throw Exception('Error al obtener notificaciones');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Polling suave si el WebSocket no está conectado (Fase C).
  void startBackgroundSync() {
    _pollTimer?.cancel();
    refreshUnreadCount();
    _pollTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      if (!_wsService.isConnected) {
        await refreshUnreadCount();
      }
    });
  }

  void stopBackgroundSync() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<int> refreshUnreadCount() async {
    try {
      final count = await getUnreadCount();
      if (count != _lastUnread) {
        _lastUnread = count;
        _unreadCountController.add(count);
      }
      return count;
    } catch (_) {
      return _lastUnread;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/notifications/my/unread-count');

      if (response.statusCode == 200) {
        final count = (response.data['count'] as num?)?.toInt() ?? 0;
        _lastUnread = count;
        _unreadCountController.add(count);
        return count;
      }
      throw Exception('Error al obtener contador');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Marcar como leída
  Future<NotificationModel> markAsRead(int notificationId) async {
    try {
      final response = await _dio.patch('/notifications/$notificationId/read');

      if (response.statusCode == 200) {
        final notification = NotificationModel.fromJson(response.data);

        // Actualizar lista local y stream
        await getMyNotifications();
        return notification;
      }
      throw Exception('Error al marcar como leída');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Marcar todas como leídas
  Future<void> markAllAsRead() async {
    try {
      final response = await _dio.patch('/notifications/mark-all-read');

      if (response.statusCode == 200) {
        // Actualizar lista local
        await getMyNotifications();
      } else {
        throw Exception('Error al marcar todas como leídas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // MÉTODOS PARA GESTORES (DT/Manager)

  // Enviar convocatoria a partido
  Future<List<NotificationModel>> sendMatchInvitation({
    required int eventId,
    required int teamId,
    required Map<String, dynamic> matchDetails,
  }) async {
    try {
      final response =
          await _dio.post('/notifications/match-invitation', data: {
        'eventId': eventId,
        'teamId': teamId,
        'matchDetails': matchDetails,
      });

      if (response.statusCode == 201) {
        final List<dynamic> data = response.data;
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
      throw Exception('Error al enviar convocatoria');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Enviar recordatorio de entrenamiento
  Future<List<NotificationModel>> sendTrainingReminder({
    required int eventId,
    required int teamId,
    required Map<String, dynamic> trainingDetails,
  }) async {
    try {
      final response =
          await _dio.post('/notifications/training-reminder', data: {
        'eventId': eventId,
        'teamId': teamId,
        'trainingDetails': trainingDetails,
      });

      if (response.statusCode == 201) {
        final List<dynamic> data = response.data;
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
      throw Exception('Error al enviar recordatorio');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Enviar recordatorio de pago
  Future<List<NotificationModel>> sendPaymentReminder({
    required List<int> userIds,
    required int teamId,
    required Map<String, dynamic> paymentDetails,
  }) async {
    try {
      final response =
          await _dio.post('/notifications/payment-reminder', data: {
        'userIds': userIds,
        'teamId': teamId,
        'paymentDetails': paymentDetails,
      });

      if (response.statusCode == 201) {
        final List<dynamic> data = response.data;
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
      throw Exception('Error al enviar recordatorio de pago');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Enviar notificación de evento social
  Future<List<NotificationModel>> sendSocialEventNotification({
    required int eventId,
    required int teamId,
    required Map<String, dynamic> eventDetails,
  }) async {
    try {
      final response = await _dio.post('/notifications/social-event', data: {
        'eventId': eventId,
        'teamId': teamId,
        'eventDetails': eventDetails,
      });

      if (response.statusCode == 201) {
        final List<dynamic> data = response.data;
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
      throw Exception('Error al enviar notificación de evento');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Enviar alertas de apto médico
  Future<List<NotificationModel>> sendMedicalExpiryAlerts() async {
    try {
      final response = await _dio.post('/notifications/medical-expiry-alerts');

      if (response.statusCode == 201) {
        final List<dynamic> data = response.data;
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
      throw Exception('Error al enviar alertas médicas');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Helpers para UI
  static List<NotificationModel> filterByType(
      List<NotificationModel> notifications, NotificationType type) {
    return notifications.where((n) => n.type == type).toList();
  }

  static List<NotificationModel> filterUnread(
      List<NotificationModel> notifications) {
    return notifications.where((n) => !n.isRead).toList();
  }

  static List<NotificationModel> filterByPriority(
      List<NotificationModel> notifications, NotificationPriority priority) {
    return notifications.where((n) => n.priority == priority).toList();
  }

  static Map<NotificationType, List<NotificationModel>> groupByType(
      List<NotificationModel> notifications) {
    final Map<NotificationType, List<NotificationModel>> grouped = {};

    for (final notification in notifications) {
      if (!grouped.containsKey(notification.type)) {
        grouped[notification.type] = [];
      }
      grouped[notification.type]!.add(notification);
    }

    return grouped;
  }

  void dispose() {
    // NotificationService es singleton; no desconectar WS al salir de una pantalla.
  }

  void disconnectOnLogout() {
    stopBackgroundSync();
    _lastUnread = 0;
    _unreadCountController.add(0);
    _wsService.disconnect();
    _wsListenersRegistered = false;
  }

  // Legacy compatibility
  final Map<int, StreamController<String>> _notificacionesPorPartido = {};

  void inicializarNotificacionesParaPartido(int partidoId) {
    if (!_notificacionesPorPartido.containsKey(partidoId)) {
      _notificacionesPorPartido[partidoId] =
          StreamController<String>.broadcast();
    }
  }

  Stream<String> obtenerNotificacionesParaPartido(int partidoId) {
    inicializarNotificacionesParaPartido(partidoId);
    return _notificacionesPorPartido[partidoId]!.stream;
  }

  void emitirNotificacion(int partidoId, String mensaje) {
    if (_notificacionesPorPartido.containsKey(partidoId)) {
      _notificacionesPorPartido[partidoId]!.add(mensaje);
    }
  }

  void limpiarRecursos() {
    _notificacionesPorPartido.forEach((_, controller) => controller.close());
  }
}
