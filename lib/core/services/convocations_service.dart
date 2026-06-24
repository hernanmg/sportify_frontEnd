import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/sport_event.dart';
import 'package:sportify_amateur/models/player_eligibility.dart';
import 'package:sportify_amateur/models/player_convocation_stats.dart';

class AddConvocationPlayersResult {
  final SportEvent event;
  final List<int> added;
  final List<int> skipped;

  AddConvocationPlayersResult({
    required this.event,
    required this.added,
    required this.skipped,
  });

  factory AddConvocationPlayersResult.fromJson(Map<String, dynamic> json) {
    return AddConvocationPlayersResult(
      event: SportEvent.fromJson(
        Map<String, dynamic>.from(json['event'] as Map),
      ),
      added: (json['added'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      skipped: (json['skipped'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
    );
  }
}

class ConvocationStats {
  final int total;
  final int confirmed;
  final int pending;
  final int declined;
  final int noResponse;
  final int convoked;

  ConvocationStats({
    required this.total,
    required this.confirmed,
    required this.pending,
    required this.declined,
    required this.noResponse,
    this.convoked = 0,
  });

  factory ConvocationStats.fromJson(Map<String, dynamic> json) {
    return ConvocationStats(
      total: json['total'] ?? 0,
      confirmed: json['confirmed'] ?? 0,
      pending: json['pending'] ?? 0,
      declined: json['declined'] ?? 0,
      noResponse: json['noResponse'] ?? 0,
      convoked: json['convoked'] ?? 0,
    );
  }

  double get confirmationRate {
    return total > 0 ? (confirmed / total) * 100 : 0;
  }

  double get responseRate {
    return total > 0 ? ((confirmed + declined) / total) * 100 : 0;
  }
}

class ConvocationsService {
  final Dio _dio = DioClient.instance;

  // CRUD de convocatorias

  Future<List<SportEvent>> getAllConvocations({
    int? teamId,
    String? status, // 'sent' | 'draft'
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (teamId != null) queryParams['teamId'] = teamId;
      if (status != null) queryParams['status'] = status;

      final response =
          await _dio.get('/convocations', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SportEvent.fromJson(json)).toList();
      }
      throw Exception('Error al obtener convocatorias');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<SportEvent> getConvocation(int id) async {
    final response = await _dio.get('/convocations/$id');
    return SportEvent.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<PlayerEligibility>> getEligibleRoster(int convocationId) async {
    final response = await _dio.get('/convocations/$convocationId/eligible-roster');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => PlayerEligibility.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<AddConvocationPlayersResult> addConvokedPlayers(
    int convocationId,
    List<int> userIds,
  ) async {
    final response = await _dio.post(
      '/convocations/$convocationId/squad/add',
      data: {'userIds': userIds},
    );
    return AddConvocationPlayersResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<SportEvent> setSquad(
    int convocationId, {
    required List<int> convokedUserIds,
    List<Map<String, dynamic>>? feeOverrides,
  }) async {
    final response = await _dio.put(
      '/convocations/$convocationId/squad',
      data: {
        'convokedUserIds': convokedUserIds,
        if (feeOverrides != null) 'feeOverrides': feeOverrides,
      },
    );
    return SportEvent.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<SportEvent> createConvocation(
      Map<String, dynamic> convocationData) async {
    try {
      final response = await _dio.post('/convocations', data: convocationData);

      if (response.statusCode == 201) {
        return SportEvent.fromJson(response.data);
      }
      throw Exception('Error al crear convocatoria');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<SportEvent> createOfficialMatch(Map<String, dynamic> matchData) async {
    try {
      final response =
          await _dio.post('/convocations/official-match', data: matchData);

      if (response.statusCode == 201) {
        return SportEvent.fromJson(response.data);
      }
      throw Exception('Error al crear partido oficial');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<SportEvent> createFriendlyMatch(Map<String, dynamic> matchData) async {
    try {
      final response =
          await _dio.post('/convocations/friendly-match', data: matchData);

      if (response.statusCode == 201) {
        return SportEvent.fromJson(response.data);
      }
      throw Exception('Error al crear partido amistoso');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<SportEvent> updateConvocation(
      int id, Map<String, dynamic> convocationData) async {
    try {
      final response =
          await _dio.patch('/convocations/$id', data: convocationData);

      if (response.statusCode == 200) {
        return SportEvent.fromJson(response.data);
      }
      throw Exception('Error al actualizar convocatoria');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> deleteConvocation(int id) async {
    try {
      final response = await _dio.delete('/convocations/$id');

      if (response.statusCode != 204) {
        throw Exception('Error al eliminar convocatoria');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Gestión de envío

  Future<SportEvent> sendConvocation(int id) async {
    try {
      final response = await _dio.post('/convocations/$id/send');

      if (response.statusCode == 200) {
        return SportEvent.fromJson(response.data);
      }
      throw Exception('Error al enviar convocatoria');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> resendConvocation(int id) async {
    try {
      final response = await _dio.post('/convocations/$id/resend');

      if (response.statusCode != 200) {
        throw Exception('Error al reenviar convocatoria');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<int> remindPendingConvocation(int id) async {
    final response = await _dio.post('/convocations/$id/remind-pending');
    final data = Map<String, dynamic>.from(response.data as Map);
    return data['reminded'] as int? ?? 0;
  }

  Future<List<int>> getSuggestedStarters(int teamId) async {
    final response = await _dio.get(
      '/convocations/suggested-starters',
      queryParameters: {'teamId': teamId},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['userIds'] as List<dynamic>? ?? [])
        .map((e) => e as int)
        .toList();
  }

  // Estadísticas y respuestas

  Future<ConvocationStats> getConvocationStats(int id) async {
    try {
      final response = await _dio.get('/convocations/$id/stats');

      if (response.statusCode == 200) {
        return ConvocationStats.fromJson(response.data);
      }
      throw Exception('Error al obtener estadísticas');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<EventParticipant>> getConvocationResponses(int id) async {
    try {
      final response = await _dio.get('/convocations/$id/responses');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => EventParticipant.fromJson(json)).toList();
      }
      throw Exception('Error al obtener respuestas');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Consultas específicas

  Future<List<SportEvent>> getUpcomingConvocations(int teamId) async {
    try {
      final response =
          await _dio.get('/convocations/upcoming', queryParameters: {
        'teamId': teamId,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SportEvent.fromJson(json)).toList();
      }
      throw Exception('Error al obtener convocatorias próximas');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<SportEvent>> getMyConvocations() async {
    try {
      final response = await _dio.get('/convocations/my-convocations');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SportEvent.fromJson(json)).toList();
      }
      throw Exception('Error al obtener mis convocatorias');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<PlayerConvocationStats> getPlayerHistory({
    required int teamId,
    required int userId,
  }) async {
    final response = await _dio.get(
      '/convocations/player-history',
      queryParameters: {'teamId': teamId, 'userId': userId},
    );
    return PlayerConvocationStats.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<SportEvent>> getPendingResponses() async {
    try {
      final response = await _dio.get('/convocations/pending-responses');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SportEvent.fromJson(json)).toList();
      }
      throw Exception('Error al obtener respuestas pendientes');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Respuestas de jugadores

  Future<EventParticipant> confirmParticipation(int convocationId,
      {String? notes}) async {
    try {
      final response =
          await _dio.post('/convocations/$convocationId/confirm', data: {
        if (notes != null) 'notes': notes,
      });

      if (response.statusCode == 200) {
        return EventParticipant.fromJson(response.data);
      }
      throw Exception('Error al confirmar participación');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<EventParticipant> declineParticipation(int convocationId,
      {String? notes}) async {
    try {
      final response =
          await _dio.post('/convocations/$convocationId/decline', data: {
        if (notes != null) 'notes': notes,
      });

      if (response.statusCode == 200) {
        return EventParticipant.fromJson(response.data);
      }
      throw Exception('Error al rechazar participación');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Helpers para UI

  static List<SportEvent> filterByMatchType(
      List<SportEvent> convocations, bool isOfficial) {
    return convocations
        .where((conv) => conv.isOfficialMatch == isOfficial)
        .toList();
  }

  static List<SportEvent> filterSent(List<SportEvent> convocations) {
    return convocations
        .where((conv) => conv.status == SportEventStatus.scheduled)
        .toList();
  }

  static List<SportEvent> filterDrafts(List<SportEvent> convocations) {
    return convocations
        .where((conv) => conv.status == SportEventStatus.draft)
        .toList();
  }

  static Map<String, List<SportEvent>> groupByStatus(
      List<SportEvent> convocations) {
    final Map<String, List<SportEvent>> grouped = {
      'sent': [],
      'draft': [],
    };

    for (final convocation in convocations) {
      if (convocation.status == SportEventStatus.scheduled) {
        grouped['sent']!.add(convocation);
      } else if (convocation.status == SportEventStatus.draft) {
        grouped['draft']!.add(convocation);
      }
    }

    return grouped;
  }

  static Map<String, List<SportEvent>> groupByMatchType(
      List<SportEvent> convocations) {
    final Map<String, List<SportEvent>> grouped = {
      'official': [],
      'friendly': [],
    };

    for (final convocation in convocations) {
      if (convocation.isOfficialMatch) {
        grouped['official']!.add(convocation);
      } else {
        grouped['friendly']!.add(convocation);
      }
    }

    return grouped;
  }
}
