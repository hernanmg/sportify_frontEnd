import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/sport.dart';

class SportService {
  final Dio _dio = DioClient.instance;

  Future<List<Sport>> getAllSports() async {
    final response = await _dio.get('/sports');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => Sport.fromJson(json)).toList();
    }
    throw Exception('Error al obtener deportes');
  }

  Future<Sport> createSport(String name) async {
    final response = await _dio.post('/sports', data: {'name': name});
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Sport.fromJson(response.data);
    }
    throw Exception('Error al crear deporte');
  }

  Future<Sport> updateSport(int id, String name) async {
    final response = await _dio.patch('/sports/$id', data: {'name': name});
    if (response.statusCode == 200) {
      return Sport.fromJson(response.data);
    }
    throw Exception('Error al actualizar deporte');
  }

  Future<void> deleteSport(int id) async {
    final response = await _dio.delete('/sports/$id');
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar deporte');
    }
  }

  Future<List<Sport>> seedDefaults() async {
    final response = await _dio.post('/sports/seed/defaults');
    if (response.statusCode == 201 || response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => Sport.fromJson(json)).toList();
    }
    throw Exception('Error al cargar deportes iniciales');
  }
}
