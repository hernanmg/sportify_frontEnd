import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/team.dart';

class TeamService {
  final Dio _dio = DioClient.instance;

  Future<List<Team>> getAllTeams() async {
    try {
      final response = await _dio.get('/teams');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map(
                (json) => Team.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
      }
      throw Exception('Error al obtener equipos');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<Team>> searchTeams(String query) async {
    try {
      final response =
          await _dio.get('/teams/search', queryParameters: {'q': query});
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map(
                (json) => Team.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
      }
      throw Exception('Error al buscar equipos');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Team> createTeam(Map<String, dynamic> teamData) async {
    try {
      final response = await _dio.post('/teams', data: teamData);
      if (response.statusCode == 201) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return Team.fromJson(data);
      }
      throw Exception('Error al crear equipo');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

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

  Future<Team> getTeamById(int id) async {
    try {
      final response = await _dio.get('/teams/$id');
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return Team.fromJson(data);
      }
      throw Exception('Equipo no encontrado');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<Team>> getTeamsBySport(int sportId) async {
    try {
      final response = await _dio.get('/teams/sport/$sportId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map(
                (json) => Team.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
      }
      throw Exception('Error al obtener equipos del deporte');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
