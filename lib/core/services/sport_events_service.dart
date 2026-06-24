import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/models/sport_event.dart';

class SportEventsService {
  final Dio _dio = DioClient.instance;

  // CRUD básico de eventos

  Future<List<SportEvent>> getAllEvents({
    int? teamId,
    SportEventType? type,
    SportEventStatus? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (teamId != null) queryParams['teamId'] = teamId;
      if (type != null) queryParams['type'] = type.value;
      if (status != null) queryParams['status'] = status.value;

      final response =
          await _dio.get('/sport-events', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SportEvent.fromJson(json)).toList();
      }
      throw Exception('Error al obtener eventos');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<SportEvent> getEventById(int id) async {
    try {
      final response = await _dio.get('/sport-events/$id');

      if (response.statusCode == 200) {
        return SportEvent.fromJson(response.data);
      }
      throw Exception('Evento no encontrado');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<SportEvent> createEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await _dio.post('/sport-events', data: eventData);

      if (response.statusCode == 201) {
        return SportEvent.fromJson(response.data);
      }
      throw Exception('Error al crear evento');
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw Exception(
              'Tenés que iniciar sesión para crear eventos.');
        } else if (e.response?.statusCode == 403) {
          final message = e.response?.data?['message'];
          throw Exception(
            message?.toString() ??
                'No podés crear eventos para este equipo. Verificá que seas miembro del club.',
          );
        } else if (e.response?.statusCode == 400) {
          final message = e.response?.data['message'] ?? 'Datos inválidos';
          throw Exception('Error en los datos: $message');
        } else if (e.response?.statusCode == 500) {
          throw Exception('Error interno del servidor. Intenta nuevamente.');
        }
      }
      throw Exception('Error de conexión: $e');
    }
  }

  Future<SportEvent> updateEvent(int id, Map<String, dynamic> eventData) async {
    try {
      final response = await _dio.patch('/sport-events/$id', data: eventData);

      if (response.statusCode == 200) {
        return SportEvent.fromJson(response.data);
      }
      throw Exception('Error al actualizar evento');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> deleteEvent(int id) async {
    try {
      final response = await _dio.delete('/sport-events/$id');

      if (response.statusCode != 204) {
        throw Exception('Error al eliminar evento');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Métodos específicos por tipo de evento

  Future<SportEvent> createTraining(Map<String, dynamic> trainingData) async {
    try {
      final response =
          await _dio.post('/sport-events/training', data: trainingData);

      if (response.statusCode == 201) {
        return SportEvent.fromJson(response.data);
      }
      throw Exception('Error al crear entrenamiento');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> createTrainingSchedule(
    Map<String, dynamic> scheduleData,
  ) async {
    final response =
        await _dio.post('/sport-events/training-schedules', data: scheduleData);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<SportEvent> createMatch(Map<String, dynamic> matchData) async {
    try {
      final response = await _dio.post('/sport-events/match', data: matchData);

      if (response.statusCode == 201) {
        return SportEvent.fromJson(response.data);
      }
      throw Exception('Error al crear partido');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<SportEvent> createSocialEvent(Map<String, dynamic> socialData) async {
    try {
      final response =
          await _dio.post('/sport-events/social', data: socialData);

      if (response.statusCode == 201) {
        return SportEvent.fromJson(response.data);
      }
      throw Exception('Error al crear evento social');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Gestión de participantes

  Future<EventParticipant> addParticipant(
      int eventId, Map<String, dynamic> participantData) async {
    try {
      final response = await _dio.post('/sport-events/$eventId/participants',
          data: participantData);

      if (response.statusCode == 201) {
        return EventParticipant.fromJson(response.data);
      }
      throw Exception('Error al agregar participante');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<EventParticipant>> addParticipants(
      int eventId, List<int> userIds) async {
    try {
      final response =
          await _dio.post('/sport-events/$eventId/participants/bulk', data: {
        'userIds': userIds,
      });

      if (response.statusCode == 201) {
        final List<dynamic> data = response.data;
        return data.map((json) => EventParticipant.fromJson(json)).toList();
      }
      throw Exception('Error al agregar participantes');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<EventParticipant> updateParticipantResponse(
      int eventId, int userId, String status,
      {String? notes, String? playingPosition}) async {
    try {
      final response = await _dio
          .patch('/sport-events/$eventId/participants/$userId/response', data: {
        'status': status,
        if (notes != null) 'notes': notes,
        if (playingPosition != null) 'playingPosition': playingPosition,
      });

      if (response.statusCode == 200) {
        return EventParticipant.fromJson(response.data);
      }
      throw Exception('Error al actualizar respuesta');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> removeParticipant(int eventId, int userId) async {
    try {
      final response =
          await _dio.delete('/sport-events/$eventId/participants/$userId');

      if (response.statusCode != 204) {
        throw Exception('Error al eliminar participante');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Consultas específicas

  Future<List<SportEvent>> getUpcomingEvents(int teamId, {int days = 7}) async {
    try {
      final response =
          await _dio.get('/sport-events/upcoming', queryParameters: {
        'teamId': teamId,
        'days': days,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SportEvent.fromJson(json)).toList();
      }
      throw Exception('Error al obtener eventos próximos');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<SportEvent>> getMyEvents() async {
    try {
      final response = await _dio.get('/sport-events/my-events');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SportEvent.fromJson(json)).toList();
      }
      throw Exception('Error al obtener mis eventos');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<SportEvent>> getEventsByDateRange(
      int teamId, DateTime startDate, DateTime endDate) async {
    try {
      final response =
          await _dio.get('/sport-events/date-range', queryParameters: {
        'teamId': teamId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SportEvent.fromJson(json)).toList();
      }
      throw Exception('Error al obtener eventos por fecha');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Métodos de respuesta para jugadores

  Future<EventParticipant> confirmParticipation(int eventId,
      {String? notes}) async {
    final userIdStr = await AuthStorageService().getUserId();
    final userId = int.parse(userIdStr ?? '0');
    return await updateParticipantResponse(eventId, userId, 'confirmed',
        notes: notes);
  }

  Future<EventParticipant> declineParticipation(int eventId,
      {String? notes}) async {
    final userIdStr = await AuthStorageService().getUserId();
    final userId = int.parse(userIdStr ?? '0');
    return await updateParticipantResponse(eventId, userId, 'declined',
        notes: notes);
  }

  // Helpers para UI

  static List<SportEvent> filterByType(
      List<SportEvent> events, SportEventType type) {
    return events.where((event) => event.type == type).toList();
  }

  static List<SportEvent> filterByStatus(
      List<SportEvent> events, SportEventStatus status) {
    return events.where((event) => event.status == status).toList();
  }

  static List<SportEvent> filterUpcoming(List<SportEvent> events) {
    return events.where((event) => event.isUpcoming).toList();
  }

  static List<SportEvent> filterToday(List<SportEvent> events) {
    return events.where((event) => event.isToday).toList();
  }

  static Map<SportEventType, List<SportEvent>> groupByType(
      List<SportEvent> events) {
    final Map<SportEventType, List<SportEvent>> grouped = {};

    for (final event in events) {
      if (!grouped.containsKey(event.type)) {
        grouped[event.type] = [];
      }
      grouped[event.type]!.add(event);
    }

    return grouped;
  }

  static Map<String, List<SportEvent>> groupByDate(List<SportEvent> events) {
    final Map<String, List<SportEvent>> grouped = {};

    for (final event in events) {
      final dateKey =
          '${event.eventDate.year}-${event.eventDate.month.toString().padLeft(2, '0')}-${event.eventDate.day.toString().padLeft(2, '0')}';
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(event);
    }

    return grouped;
  }
}
