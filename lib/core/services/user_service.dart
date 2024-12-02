import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sportify_amateur/core/common/app_config.dart';
import 'package:sportify_amateur/models/permission.dart';
import 'package:sportify_amateur/models/role.dart';
import 'package:sportify_amateur/models/user.dart';

class UserService {
  final String baseUrl = AppConfig.apiBaseUrl;

  // UserService(this.baseUrl);

  Future<List<User>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch users');
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
