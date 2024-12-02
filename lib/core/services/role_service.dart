import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sportify_amateur/core/common/app_config.dart';
import 'package:sportify_amateur/models/permission.dart';
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

  Future<void> deleteMocRole(int userId) async {
    // Simula una espera como si estuvieras llamando al backend
    await Future.delayed(Duration(seconds: 1));
    // Aquí podrías implementar lógica para eliminar en la lista mock
    print('User with ID $userId deleted');
  }

  Future<List<Role>> fetchMockRoles() async {
    // Simula un tiempo de espera como si estuvieras llamando a un backend
    await Future.delayed(Duration(seconds: 2));

    // Retorna una lista de usuarios mock
    return [
      Role(
        id: 1,
        name: 'Administrador',
        permissions: [
          Permission(
            id: 1,
            name: 'pantalla user',
          )
        ],
      ),
      Role(
        id: 2,
        name: 'Viewer',
        permissions: [
          Permission(
            id: 3,
            name: 'Viewer',
          )
        ],
      ),
      Role(
        id: 3,
        name: 'LALALA',
        permissions: [
          Permission(
            id: 1,
            name: 'Reportes',
          )
        ],
      ),
    ];
  }
}
