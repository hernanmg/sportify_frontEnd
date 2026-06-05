import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/player_roster.dart';

class RosterService {
  final Dio _dio = DioClient.instance;

  static String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'];
        if (message is List) {
          return message.map((item) => item.toString()).join('\n');
        }
        if (message != null) return message.toString();
      }
    }
    return error.toString();
  }

  // Obtener todos los registros de roster
  Future<List<PlayerRoster>> getAllRoster() async {
    try {
      final response = await _dio.get('/roster');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => PlayerRoster.fromJson(json)).toList();
      }
      throw Exception('Error al obtener lista de buena fe');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener roster por equipo
  Future<List<PlayerRoster>> getRosterByTeam(
    int teamId, {
    String? season,
    List<int>? categoryIds,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (season != null) queryParams['season'] = season;
      if (categoryIds != null && categoryIds.isNotEmpty) {
        queryParams['categoryIds'] = categoryIds.join(',');
      }

      final response =
          await _dio.get('/roster/team/$teamId', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => PlayerRoster.fromJson(json)).toList();
      }
      throw Exception('Error al obtener roster del equipo');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener jugadores habilitados por equipo
  Future<List<PlayerRoster>> getEnabledPlayersByTeam(
      int teamId, String season) async {
    try {
      final response = await _dio.get(
        '/roster/team/$teamId/enabled',
        queryParameters: {'season': season},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => PlayerRoster.fromJson(json)).toList();
      }
      throw Exception('Error al obtener jugadores habilitados');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener números de camiseta disponibles
  Future<List<int>> getAvailableJerseyNumbers(int teamId, String season) async {
    try {
      final response = await _dio.get(
        '/roster/team/$teamId/available-numbers',
        queryParameters: {'season': season},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.cast<int>();
      }
      throw Exception('Error al obtener números disponibles');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener roster por temporada
  Future<List<PlayerRoster>> getRosterBySeason(String season) async {
    try {
      final response = await _dio.get('/roster/season/$season');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => PlayerRoster.fromJson(json)).toList();
      }
      throw Exception('Error al obtener roster por temporada');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener un registro específico
  Future<PlayerRoster> getRosterById(int id) async {
    try {
      final response = await _dio.get('/roster/$id');
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return PlayerRoster.fromJson(data);
      }
      throw Exception('Error al obtener registro de roster');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear nuevo registro de roster
  Future<PlayerRoster> createRoster(Map<String, dynamic> rosterData) async {
    try {
      final response = await _dio.post('/roster', data: rosterData);
      if (response.statusCode == 201) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return PlayerRoster.fromJson(data);
      }
      throw Exception('Error al crear registro de roster');
    } on DioException catch (e) {
      throw Exception(errorMessage(e));
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar registro de roster
  Future<PlayerRoster> updateRoster(
      int id, Map<String, dynamic> rosterData) async {
    try {
      final response = await _dio.patch('/roster/$id', data: rosterData);
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return PlayerRoster.fromJson(data);
      }
      throw Exception('Error al actualizar registro de roster');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Vincula un jugador sin app a un usuario registrado.
  Future<PlayerRoster> linkRosterToUser(int rosterId, int userId) async {
    try {
      final response = await _dio.patch(
        '/roster/$rosterId/link-user',
        data: {'userId': userId},
      );
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return PlayerRoster.fromJson(data);
      }
      throw Exception('Error al vincular jugador con usuario');
    } on DioException catch (e) {
      throw Exception(errorMessage(e));
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar estado médico
  Future<PlayerRoster> updateMedicalStatus(int id, String status) async {
    try {
      final response = await _dio.patch('/roster/$id/medical-status', data: {
        'status': status,
      });
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return PlayerRoster.fromJson(data);
      }
      throw Exception('Error al actualizar estado médico');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar registro de roster
  Future<void> deleteRoster(int id) async {
    try {
      final response = await _dio.delete('/roster/$id');
      if (response.statusCode != 204) {
        throw Exception('Error al eliminar registro de roster');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Helpers para UI
  static List<String> getPositions() {
    return ['goalkeeper', 'defender', 'midfielder', 'forward', 'player'];
  }

  static String getPositionDisplayName(String position) {
    switch (position) {
      case 'goalkeeper':
        return 'Arquero';
      case 'defender':
        return 'Defensor';
      case 'midfielder':
        return 'Mediocampo';
      case 'forward':
        return 'Delantero';
      default:
        return 'Jugador';
    }
  }

  static List<String> getMedicalStatuses() {
    return ['pending', 'approved', 'expired', 'rejected'];
  }

  static String getMedicalStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobado';
      case 'expired':
        return 'Vencido';
      case 'rejected':
        return 'Rechazado';
      default:
        return 'Desconocido';
    }
  }

  static List<String> getSeasons() {
    final currentYear = DateTime.now().year;
    return [
      '$currentYear-Apertura',
      '$currentYear-Clausura',
      '${currentYear - 1}-Apertura',
      '${currentYear - 1}-Clausura',
    ];
  }

  static List<String> getCategories() {
    return ['+35', '+40', '+45', 'Primera', 'Reserva', 'Juveniles'];
  }
}
