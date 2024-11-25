import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sportify_amateur/core/common/app_config.dart';
import 'package:sportify_amateur/models/role.dart';

class RoleService {
  final String baseUrl = AppConfig.apiBaseUrl;

  RoleService();

  Future<List<Role>> getRoles() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/roles'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Role.fromJson(json)).toList();
      } else {
        // Manejo de errores basado en el código de estado
        throw HttpException(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } on SocketException {
      // Manejo de errores de conexión
      throw Exception('No se pudo establecer conexión con el servidor');
    } on FormatException {
      // Manejo de errores de formato (JSON mal formado)
      throw Exception('Error en el formato de la respuesta del servidor');
    } catch (e) {
      // Manejo genérico de errores
      throw Exception('Ocurrió un error inesperado: $e');
    }
  }

  Future<Role> createRole(Role role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/roles'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(role.toJson()),
      );

      if (response.statusCode == 201) {
        return Role.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create role');
      }
    } on SocketException {
      // Manejo de errores de conexión
      throw Exception('No se pudo establecer conexión con el servidor');
    } on FormatException {
      // Manejo de errores de formato (JSON mal formado)
      throw Exception('Error en el formato de la respuesta del servidor');
    } catch (e) {
      // Manejo genérico de errores
      throw Exception('Ocurrió un error inesperado: $e');
    }
  }

  Future<void> deleteRole(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/roles/$id'));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete role');
      }
    } on SocketException {
      // Manejo de errores de conexión
      throw Exception('No se pudo establecer conexión con el servidor');
    } on FormatException {
      // Manejo de errores de formato (JSON mal formado)
      throw Exception('Error en el formato de la respuesta del servidor');
    } catch (e) {
      // Manejo genérico de errores
      throw Exception('Ocurrió un error inesperado: $e');
    }
  }
}
