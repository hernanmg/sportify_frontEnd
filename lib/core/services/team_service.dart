import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/team.dart';
import 'package:sportify_amateur/models/my_team_option.dart';

class TeamService {
  final Dio _dio = DioClient.instance;

  static String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        final message = data['message'];
        if (message is List) {
          return message.map((e) => e.toString()).join('\n');
        }
        return message.toString();
      }
    }
    return error.toString();
  }

  Future<Map<String, dynamic>> completeOnboarding(
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post('/teams/onboarding', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> joinWithCode(
    String inviteCode, {
    List<int>? categoryIds,
  }) async {
    final response = await _dio.post('/teams/join', data: {
      'inviteCode': inviteCode.trim().toUpperCase(),
      if (categoryIds != null && categoryIds.isNotEmpty)
        'categoryIds': categoryIds,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> previewInvite(String code) async {
    final response = await _dio.get('/teams/invites/${code.trim().toUpperCase()}');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> createTeamInvite(
    int teamId, {
    List<int>? categoryIds,
  }) async {
    final response = await _dio.post(
      '/teams/$teamId/invites',
      data: categoryIds != null ? {'categoryIds': categoryIds} : {},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> getTeamSocialGuests(int teamId) async {
    final response = await _dio.get('/teams/$teamId/social-guests');
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<MyTeamOption>> getMyTeams() async {
    try {
      final response = await _dio.get('/teams/mine');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => MyTeamOption.fromJson(
                  Map<String, dynamic>.from(json as Map),
                ))
            .toList();
      }
      throw Exception('Error al obtener tus equipos');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener todos los equipos
  Future<List<Team>> getAllTeams() async {
    try {
      final response = await _dio.get('/teams');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Team.fromJson(json)).toList();
      }
      throw Exception('Error al obtener equipos');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener equipo por ID
  Future<Team> getTeamById(int id) async {
    try {
      final response = await _dio.get('/teams/$id');
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return Team.fromJson(data);
      }
      throw Exception('Error al obtener equipo');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Buscar equipos por nombre
  Future<List<Team>> searchTeams(String query) async {
    try {
      if (query.trim().length < 2) {
        return [];
      }
      final response = await _dio.get('/teams/search', queryParameters: {
        'q': query.trim(),
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Team.fromJson(json)).toList();
      }
      throw Exception('Error al buscar equipos');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Asigna al usuario actual como encargado (super_admin / manager / admin).
  Future<Map<String, dynamic>> claimTeamAsAdmin(int teamId) async {
    final response = await _dio.post('/teams/$teamId/claim-admin');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Team> setTeamCategories(int teamId, List<int> categoryIds) async {
    final response = await _dio.patch(
      '/teams/$teamId/categories',
      data: {'categoryIds': categoryIds},
    );
    if (response.statusCode == 200) {
      return Team.fromJson(Map<String, dynamic>.from(response.data as Map));
    }
    throw Exception('Error al actualizar categorías del equipo');
  }

  // Crear nuevo equipo
  Future<Team> createTeam(Map<String, dynamic> teamData) async {
    try {
      final response = await _dio.post('/teams', data: teamData);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return Team.fromJson(data);
      }
      throw Exception('Error al crear equipo');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar equipo existente
  Future<Team> updateTeam(int id, Map<String, dynamic> teamData) async {
    try {
      final response = await _dio.patch('/teams/$id', data: teamData);
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return Team.fromJson(data);
      }
      throw Exception('Error al actualizar equipo');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Team> updateBirthdayNotificationHour(int teamId, int hour) async {
    try {
      final response = await _dio.patch(
        '/teams/$teamId/birthday-notification-hour',
        data: {'birthdayNotificationHour': hour},
      );
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return Team.fromJson(data);
      }
      throw Exception('Error al guardar hora de cumpleaños');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar equipo
  Future<void> deleteTeam(int id) async {
    try {
      final response = await _dio.delete('/teams/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar equipo');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener equipos por deporte
  Future<List<Team>> getTeamsBySport(int sportId) async {
    try {
      final response = await _dio.get('/teams/sport/$sportId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Team.fromJson(json)).toList();
      }
      throw Exception('Error al obtener equipos por deporte');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener equipos de fútbol
  Future<List<Team>> getFootballTeams() async {
    try {
      final response = await _dio.get('/teams/football');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Team.fromJson(json)).toList();
      }
      throw Exception('Error al obtener equipos de fútbol');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Buscar o crear equipo por nombre
  Future<Team> findOrCreateByName(String name, int sportId,
      {int? categoryId}) async {
    try {
      final response = await _dio.post('/teams/find-or-create', data: {
        'name': name,
        'sportId': sportId,
        'categoryId': categoryId,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return Team.fromJson(data);
      }
      throw Exception('Error al buscar o crear equipo');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Helpers para UI
  static List<String> getSportTypes() {
    return ['Fútbol', 'Básquet', 'Vóley', 'Tenis', 'Paddle', 'Hockey'];
  }

  static List<String> getCategories() {
    return [
      '+35',
      '+40',
      '+45',
      'Primera',
      'Reserva',
      'Juveniles',
      'Infantiles'
    ];
  }

  Future<List<Map<String, dynamic>>> listTeamMembers(int teamId) async {
    final response = await _dio.get('/teams/$teamId/members');
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> updateTeamMemberRole(
    int teamId,
    int userId,
    String role,
  ) async {
    await _dio.patch(
      '/teams/$teamId/members/$userId/role',
      data: {'role': role},
    );
  }
}
