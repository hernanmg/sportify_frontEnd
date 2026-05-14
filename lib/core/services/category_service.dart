import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/category.dart';

class CategoryService {
  final Dio _dio = DioClient.instance;

  Future<List<Category>> getAllCategories() async {
    try {
      final response = await _dio.get('/categories');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Category.fromJson(json)).toList();
      }
      throw Exception('Error al obtener categorías');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<Category>> getCategoriesBySport(int sportId) async {
    try {
      final response = await _dio.get('/categories/sport/$sportId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Category.fromJson(json)).toList();
      }
      throw Exception('Error al obtener categorías del deporte');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<Category>> getFootballCategories() async {
    try {
      final response = await _dio.get('/categories/football');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Category.fromJson(json)).toList();
      }
      throw Exception('Error al obtener categorías de fútbol');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Category> getCategoryById(int id) async {
    try {
      final response = await _dio.get('/categories/$id');
      if (response.statusCode == 200) {
        return Category.fromJson(response.data);
      }
      throw Exception('Categoría no encontrada');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Category> createCategory(Map<String, dynamic> categoryData) async {
    try {
      final response = await _dio.post('/categories', data: categoryData);
      if (response.statusCode == 201) {
        return Category.fromJson(response.data);
      }
      throw Exception('Error al crear categoría');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Category> updateCategory(
      int id, Map<String, dynamic> categoryData) async {
    try {
      final response = await _dio.patch('/categories/$id', data: categoryData);
      if (response.statusCode == 200) {
        return Category.fromJson(response.data);
      }
      throw Exception('Error al actualizar categoría');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      final response = await _dio.delete('/categories/$id');
      if (response.statusCode != 200) {
        throw Exception('Error al eliminar categoría');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Category> toggleCategoryActive(int id) async {
    try {
      final response = await _dio.patch('/categories/$id/toggle');
      if (response.statusCode == 200) {
        return Category.fromJson(response.data);
      }
      throw Exception('Error al cambiar estado de categoría');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<Category>> seedFootballCategories({int? sportId}) async {
    try {
      final response = await _dio.post(
        '/categories/seed/football',
        data: sportId != null ? {'sportId': sportId} : {},
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Category.fromJson(json)).toList();
      }
      throw Exception('Error al cargar categorías iniciales');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
