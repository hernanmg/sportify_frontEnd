import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:sportify_amateur/core/common/app_config.dart';
import 'package:sportify_amateur/models/permission.dart';
import 'package:sportify_amateur/models/role.dart';
import 'package:sportify_amateur/models/user.dart';

class UserService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  // UserService(this.baseUrl);
  final FlutterSecureStorage _secureStorage =
      FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _secureStorage.read(
        key: 'authToken'); // Leer token desde almacenamiento seguro
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Obtener todos los usuarios (requiere rol admin)
  Future<List<User>> findAll() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<User>;
    } else {
      throw Exception('Error al obtener los usuarios');
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: headers,
      body: json.encode(data),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error al crear el usuario');
    }
  }

  // Obtener perfil del usuario autenticado
  Future<Map<String, dynamic>> getProfile() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error al obtener el perfil');
    }
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error al actualizar el usuario');
    }
  }
    // Eliminar un usuario por ID
  Future<void> delete(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar el usuario');
    }
  }

  Future<List<User>> fetchMockUsers() async {
    // Simula un tiempo de espera como si estuvieras llamando a un backend
    await Future.delayed(Duration(seconds: 2));

    // Retorna una lista de usuarios mock
    return [
      User(
        id: 1,
        name: 'John Doe',
        email: 'john.doe@example.com',
        roles: [
          Role(
              id: 1,
              name: 'Admin',
              permissions: [Permission(id: 1, name: 'yeyeye')]),
          Role(
              id: 2,
              name: 'Editor',
              permissions: [Permission(id: 1, name: 'yeyeye')]),
        ],
      ),
      User(
        id: 2,
        name: 'Jane Smith',
        email: 'jane.smith@example.com',
        roles: [
          Role(
              id: 3,
              name: 'Viewer',
              permissions: [Permission(id: 1, name: 'yeyeye')]),
        ],
      ),
      User(
        id: 3,
        name: 'Robert Johnson',
        email: 'robert.johnson@example.com',
        roles: [
          Role(
              id: 1,
              name: 'Admin',
              permissions: [Permission(id: 1, name: 'yeyeye')]),
        ],
      ),
    ];
  }

  Future<void> deleteMockUser(int userId) async {
    // Simula una espera como si estuvieras llamando al backend
    await Future.delayed(Duration(seconds: 1));
    // Aquí podrías implementar lógica para eliminar en la lista mock
    print('User with ID $userId deleted');
  }
}
