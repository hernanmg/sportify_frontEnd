import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import 'auth_storage_services.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _userId;
  String? _userRole;
  Timer? _reconnectTimer;

  // Callbacks para diferentes tipos de eventos
  final Map<String, List<Function(Map<String, dynamic>)>> _eventListeners = {};

  bool get isConnected => _isConnected;
  String? get userId => _userId;
  String? get userRole => _userRole;

  Future<void> connect() async {
    if (_isConnecting) return;
    if (_socket?.connected == true) {
      debugPrint('📡 Socket.IO ya conectado (${_socket!.id})');
      return;
    }

    _isConnecting = true;
    try {
      final token = await AuthStorageService().getToken();
      if (token == null) {
        debugPrint('🔒 No hay token disponible para Socket.IO');
        return;
      }

      if (_socket != null) {
        _socket!.clearListeners();
        _socket!.dispose();
        _socket = null;
      }

      final socketUrl = '${ApiConstants.baseUrl}${ApiConstants.wsNotifications}';
      debugPrint('🔗 Conectando a Socket.IO: $socketUrl');

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(3000)
            .setPath('/socket.io/')
            .setExtraHeaders({
              'Authorization': 'Bearer $token',
            })
            .setAuth({
              'token': token,
            })
            .build(),
      );

      _setupSocketListeners();
      _socket!.connect();

      debugPrint('📡 Socket.IO inicializado');
    } catch (e) {
      debugPrint('❌ Error conectando Socket.IO: $e');
      _isConnected = false;
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _setupSocketListeners() {
    if (_socket == null) return;
    _socket!.clearListeners();
    // Evento: Conexión exitosa
    _socket!.on('connect', (_) {
      _isConnected = true;
      _reconnectTimer?.cancel();
      debugPrint('✅ Socket.IO conectado - ID: ${_socket!.id}');
      
      _notifyListeners('connected', {
        'socketId': _socket!.id,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    // Evento: Desconexión
    _socket!.on('disconnect', (reason) {
      _isConnected = false;
      debugPrint('🔌 Socket.IO desconectado - Razón: $reason');
      
      _notifyListeners('disconnected', {
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (reason == 'io server disconnect') {
        debugPrint('⚠️ El servidor cerró la conexión WS (revisar JWT o sesión)');
        return;
      }

      if (reason != 'io client disconnect') {
        _scheduleReconnect();
      }
    });

    // Evento: Error de conexión
    _socket!.on('connect_error', (error) {
      debugPrint('❌ Error de conexión Socket.IO: $error');
      _isConnected = false;
      _scheduleReconnect();
    });

    // Evento: Error general
    _socket!.on('error', (error) {
      debugPrint('❌ Error Socket.IO: $error');
      _notifyListeners('error', {
        'error': error.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    // Evento: Reconexión
    _socket!.on('reconnect', (attemptNumber) {
      debugPrint('🔄 Socket.IO reconectado - Intento: $attemptNumber');
      _isConnected = true;
    });

    // Evento: Intento de reconexión
    _socket!.on('reconnect_attempt', (attemptNumber) {
      debugPrint('🔄 Intentando reconectar Socket.IO - Intento: $attemptNumber');
    });

    // Evento: Fallo de reconexión
    _socket!.on('reconnect_failed', (_) {
      debugPrint('💀 Socket.IO falló al reconectar después de todos los intentos');
      _isConnected = false;
    });

    // Evento: Notificación recibida
    _socket!.on('notification', (data) {
      debugPrint('🔔 Notificación recibida via Socket.IO');
      _handleNotification(data);
    });

    // Evento: Usuario conectado (confirmación del servidor)
    _socket!.on('connected', (data) {
      if (data is Map) {
        final payload = Map<String, dynamic>.from(data);
        _userId = payload['userId']?.toString();
        debugPrint('👤 Usuario autenticado en WS - ID: $_userId');
        
        _notifyListeners('authenticated', {
          'userId': _userId,
          'rooms': payload['rooms'],
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });

    // Compatibilidad con nombre anterior
    _socket!.on('user_connected', (data) {
      if (data is Map) {
        _userId = data['userId']?.toString();
        _userRole = data['role']?.toString();
        debugPrint('👤 Usuario autenticado - ID: $_userId, Role: $_userRole');
        
        _notifyListeners('authenticated', {
          'userId': _userId,
          'userRole': _userRole,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });

    // Evento: Pong (respuesta a ping)
    _socket!.on('pong', (_) {
      debugPrint('🏓 Pong recibido de Socket.IO');
    });

    // Evento: Unido a sala
    _socket!.on('joined_room', (data) {
      if (data is Map) {
        debugPrint('👥 Unido a sala: ${data['room']}');
      }
    });
  }

  void _handleNotification(dynamic data) {
    try {
      Map<String, dynamic> notificationData;
      
      if (data is Map<String, dynamic>) {
        notificationData = data;
      } else if (data is Map) {
        notificationData = Map<String, dynamic>.from(data);
      } else {
        debugPrint('⚠️ Formato de notificación desconocido: ${data.runtimeType}');
        return;
      }

      debugPrint('📨 Procesando notificación: ${notificationData['title']}');
      
      _notifyListeners('notification', notificationData);
    } catch (e) {
      debugPrint('❌ Error procesando notificación: $e');
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        debugPrint('🔄 Intentando reconectar Socket.IO...');
        connect();
      }
    });
  }

  // Enviar ping al servidor
  void ping() {
    if (_isConnected && _socket != null) {
      _socket!.emit('ping');
      debugPrint('🏓 Ping enviado a Socket.IO');
    }
  }

  // Unirse a una sala específica
  void joinRoom(String room) {
    if (_isConnected && _socket != null) {
      _socket!.emit('join_room', {'room': room});
      debugPrint('🚪 Solicitando unirse a sala: $room');
    }
  }

  // Salir de una sala
  void leaveRoom(String room) {
    if (_isConnected && _socket != null) {
      _socket!.emit('leave_room', {'room': room});
      debugPrint('🚪 Saliendo de sala: $room');
    }
  }

  // Sistema de listeners para eventos
  void addEventListener(
      String eventType, Function(Map<String, dynamic>) callback) {
    if (!_eventListeners.containsKey(eventType)) {
      _eventListeners[eventType] = [];
    }
    _eventListeners[eventType]!.add(callback);
    debugPrint('📝 Listener agregado para evento: $eventType');
  }

  void removeEventListener(
      String eventType, Function(Map<String, dynamic>) callback) {
    _eventListeners[eventType]?.remove(callback);
    debugPrint('📝 Listener removido para evento: $eventType');
  }

  void _notifyListeners(String eventType, Map<String, dynamic> data) {
    final listeners = _eventListeners[eventType];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          listener(data);
        } catch (e) {
          debugPrint('❌ Error en listener $eventType: $e');
        }
      }
    }
  }

  // Desconectar Socket.IO
  void disconnect() {
    debugPrint('🔌 Desconectando Socket.IO...');
    _reconnectTimer?.cancel();
    _isConnected = false;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _eventListeners.clear();
    _userId = null;
    _userRole = null;
  }

  // Métodos de conveniencia para tipos específicos de eventos
  void onNotificationReceived(Function(Map<String, dynamic>) callback) {
    addEventListener('notification', callback);
  }

  void onConnected(Function(Map<String, dynamic>) callback) {
    addEventListener('connected', callback);
  }

  void onAuthenticated(Function(Map<String, dynamic>) callback) {
    addEventListener('authenticated', callback);
  }

  void onDisconnected(Function(Map<String, dynamic>) callback) {
    addEventListener('disconnected', callback);
  }

  void onError(Function(Map<String, dynamic>) callback) {
    addEventListener('error', callback);
  }

  // Estado de la conexión
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': _isConnected,
      'socketId': _socket?.id,
      'userId': _userId,
      'userRole': _userRole,
      'activeListeners': _eventListeners.keys.toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Emitir evento personalizado
  void emit(String event, dynamic data) {
    if (_isConnected && _socket != null) {
      _socket!.emit(event, data);
      debugPrint('📤 Evento emitido: $event');
    } else {
      debugPrint('⚠️ No se puede emitir evento $event - Socket no conectado');
    }
  }
}
