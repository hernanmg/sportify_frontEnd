import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/team.dart';

class TeamService {
  final Dio _dio = DioClient.instance;

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
}
