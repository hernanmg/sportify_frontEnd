import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'websocket_service.dart';

class DebugService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final Dio _dio = DioClient.instance;
  static final WebSocketService _wsService = WebSocketService();

  static Future<Map<String, dynamic>> checkAuthStatus() async {
    try {
      // Verificar si hay token almacenado
      final token = await _storage.read(key: 'authToken');
      final refreshToken = await _storage.read(key: 'refreshToken');

      if (token == null) {
        return {
          'isAuthenticated': false,
          'error': 'No hay token almacenado',
          'token': null,
          'refreshToken': null,
        };
      }

      // Probar endpoint protegido
      try {
        final response = await _dio.get('/auth/admin');
        return {
          'isAuthenticated': true,
          'token': token.substring(0, 20) + '...',
          'refreshToken': refreshToken != null
              ? refreshToken.substring(0, 20) + '...'
              : null,
          'userInfo': response.data,
          'backendConnected': true,
        };
      } catch (e) {
        if (e is DioException) {
          return {
            'isAuthenticated': false,
            'token': token.substring(0, 20) + '...',
            'refreshToken': refreshToken != null
                ? refreshToken.substring(0, 20) + '...'
                : null,
            'error': 'Token inválido o expirado',
            'statusCode': e.response?.statusCode,
            'backendConnected': true,
          };
        }
        return {
          'isAuthenticated': false,
          'token': token.substring(0, 20) + '...',
          'error': 'Error de conexión con backend',
          'backendConnected': false,
        };
      }
    } catch (e) {
      return {
        'isAuthenticated': false,
        'error': 'Error al verificar autenticación: $e',
        'backendConnected': false,
      };
    }
  }

  static Future<Map<String, dynamic>> testEventCreation() async {
    try {
      final testEventData = {
        'title': 'Test Event - ${DateTime.now().millisecondsSinceEpoch}',
        'description': 'Evento de prueba para verificar conectividad',
        'type': 'training',
        'eventDate':
            DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'location': 'Campo de prueba',
        'teamId': 2,
        'durationMinutes': 90,
        'requiresConfirmation': true,
      };

      final response = await _dio.post('/sport-events', data: testEventData);

      return {
        'success': true,
        'statusCode': response.statusCode,
        'eventId': response.data['id'],
        'message': 'Evento creado exitosamente',
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'statusCode': e.response?.statusCode,
          'error': e.response?.data['message'] ?? e.message,
          'details': e.response?.data,
        };
      }
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> checkBackendHealth() async {
    try {
      // Probar endpoint público
      final response = await _dio.get('/');
      return {
        'backendOnline': true,
        'statusCode': response.statusCode,
        'message': 'Backend conectado correctamente',
      };
    } catch (e) {
      return {
        'backendOnline': false,
        'error': 'Backend no disponible: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> testEventWithNotifications() async {
    try {
      final testEventData = {
        'title':
            'Entrenamiento con Notificaciones - ${DateTime.now().millisecondsSinceEpoch}',
        'description':
            'Evento de prueba para verificar notificaciones automáticas',
        'type': 'training',
        'eventDate':
            DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'location': 'Campo de entrenamiento',
        'teamId': 2,
        'durationMinutes': 90,
        'requiresConfirmation': true,
      };

      final response = await _dio.post('/sport-events', data: testEventData);

      // Verificar si se crearon notificaciones
      final notificationsResponse = await _dio.get('/notifications/my?limit=5');

      return {
        'success': true,
        'statusCode': response.statusCode,
        'eventId': response.data['id'],
        'eventTitle': response.data['title'],
        'participantCount': response.data['participantCount'] ?? 0,
        'notificationsCount': notificationsResponse.data?.length ?? 0,
        'message': 'Evento creado con notificaciones',
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'statusCode': e.response?.statusCode,
          'error': e.response?.data['message'] ?? e.message,
          'details': e.response?.data,
        };
      }
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> testRosterQuery() async {
    try {
      final response = await _dio.get('/debug/roster/2');
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error testing roster: $e',
      };
    }
  }

  static Future<void> printDebugInfo() async {
    print('=== DEBUG INFO ===');

    final healthCheck = await checkBackendHealth();
    print('Backend Health: $healthCheck');

    final authStatus = await checkAuthStatus();
    print('Auth Status: $authStatus');

    if (authStatus['isAuthenticated'] == true) {
      final rosterTest = await testRosterQuery();
      print('Roster Query Test: $rosterTest');

      final eventTest = await testEventCreation();
      print('Event Creation Test: $eventTest');

      final notificationTest = await testEventWithNotifications();
      print('Event + Notifications Test: $notificationTest');
    }

    print('==================');
  }

  // Test Socket.IO Connection
  static Future<Map<String, dynamic>> testSocketIOConnection() async {
    try {
      print('🔌 Probando conexión Socket.IO...');
      
      // Verificar estado inicial
      final initialInfo = _wsService.getConnectionInfo();
      print('📊 Estado inicial: $initialInfo');

      // Conectar
      await _wsService.connect();
      
      // Esperar un momento para que se establezca la conexión
      await Future.delayed(const Duration(seconds: 3));
      
      // Verificar estado después de conectar
      final connectedInfo = _wsService.getConnectionInfo();
      print('📊 Estado después de conectar: $connectedInfo');

      return {
        'success': _wsService.isConnected,
        'socketId': connectedInfo['socketId'],
        'userId': connectedInfo['userId'],
        'isConnected': connectedInfo['isConnected'],
        'message': _wsService.isConnected 
            ? '✅ Socket.IO conectado exitosamente' 
            : '❌ Socket.IO no pudo conectarse',
      };
    } catch (e) {
      print('❌ Error probando Socket.IO: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error al probar Socket.IO',
      };
    }
  }

  // Test recepción de notificaciones via Socket.IO
  static Future<Map<String, dynamic>> testSocketIONotifications() async {
    try {
      print('🔔 Probando recepción de notificaciones via Socket.IO...');
      
      bool notificationReceived = false;
      Map<String, dynamic>? receivedNotification;

      // Configurar listener
      _wsService.onNotificationReceived((data) {
        print('🎉 ¡Notificación recibida via Socket.IO!');
        print('📨 Datos: $data');
        notificationReceived = true;
        receivedNotification = data;
      });

      // Conectar si no está conectado
      if (!_wsService.isConnected) {
        await _wsService.connect();
        await Future.delayed(const Duration(seconds: 3));
      }

      print('⏳ Esperando notificaciones durante 10 segundos...');
      print('💡 Crea un evento desde la app para probar');
      
      // Esperar notificaciones
      await Future.delayed(const Duration(seconds: 10));

      return {
        'success': notificationReceived,
        'notificationReceived': notificationReceived,
        'notification': receivedNotification,
        'message': notificationReceived 
            ? '✅ Notificación recibida correctamente' 
            : '⏰ No se recibieron notificaciones (timeout)',
      };
    } catch (e) {
      print('❌ Error probando notificaciones Socket.IO: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error al probar notificaciones',
      };
    }
  }
}
