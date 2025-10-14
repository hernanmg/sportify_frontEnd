import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/role.dart';
import 'package:sportify_amateur/models/user.dart';

class UserService {
  final Dio _dio = DioClient.instance;

  // Obtener todos los usuarios (requiere rol admin)
  Future<List<User>> findAll() async {
    try {
      final response = await _dio.get('/users');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => User.fromJson(json)).toList();
      }
      throw Exception('Error al obtener los usuarios');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<User> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/users', data: data);
      if (response.statusCode == 201) {
        final userData = Map<String, dynamic>.from(response.data as Map);
        return User.fromJson(userData);
      }
      throw Exception('Error al crear el usuario');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener perfil del usuario autenticado
  Future<User> getProfile() async {
    try {
      final response = await _dio.get('/users/profile');
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return User.fromJson(data);
      }
      throw Exception('Error al obtener el perfil');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<User> update(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/users/$id', data: data);
      if (response.statusCode == 200) {
        final userData = Map<String, dynamic>.from(response.data as Map);
        return User.fromJson(userData);
      }
      throw Exception('Error al actualizar el usuario');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar un usuario por ID
  Future<void> delete(int id) async {
    try {
      final response = await _dio.delete('/users/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar el usuario');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<User>> fetchMockUsers() async {
    // Simula un tiempo de espera como si estuvieras llamando a un backend
    await Future.delayed(const Duration(seconds: 2));

    final now = DateTime.now();

    // Retorna una lista de usuarios mock con constructores correctos
    return [
      User(
        id: 1,
        name: 'John Doe',
        email: 'john.doe@example.com',
        username: 'johndoe',
        roles: [
          Role(
            id: 1,
            name: 'super_admin',
            description: 'Administrador del sistema',
            createdAt: now,
            updatedAt: now,
          ),
          Role(
            id: 2,
            name: 'manager',
            description: 'Manager de la liga',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      User(
        id: 2,
        name: 'Jane Smith',
        email: 'jane.smith@example.com',
        username: 'janesmith',
        roles: [
          Role(
            id: 3,
            name: 'team_captain',
            description: 'Capitán de equipo',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      User(
        id: 3,
        name: 'Robert Johnson',
        email: 'robert.johnson@example.com',
        username: 'robertj',
        roles: [
          Role(
            id: 4,
            name: 'player',
            description: 'Jugador activo',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  Future<void> deleteMockUser(int userId) async {
    // Simula una espera como si estuvieras llamando al backend
    await Future.delayed(const Duration(seconds: 1));
    // Aquí podrías implementar lógica para eliminar en la lista mock
    print('User with ID $userId deleted');
  }

  // Método para asignar rol a usuario
  Future<void> assignRoleToUser(int userId, int roleId) async {
    try {
      final response = await _dio.post('/users/$userId/roles', data: {
        'roleId': roleId,
      });
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al asignar rol');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Método para remover rol de usuario
  Future<void> removeRoleFromUser(int userId, int roleId) async {
    try {
      final response = await _dio.delete('/users/$userId/roles/$roleId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al remover rol');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener usuario por ID
  Future<User> findById(int id) async {
    try {
      final response = await _dio.get('/users/$id');
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return User.fromJson(data);
      }
      throw Exception('Usuario no encontrado');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Buscar usuarios por nombre o email
  Future<List<User>> searchUsers(String query) async {
    try {
      final response = await _dio.get('/users/search', queryParameters: {
        'q': query,
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => User.fromJson(json)).toList();
      }
      throw Exception('Error al buscar usuarios');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Gestión de usuarios eliminados
  Future<List<User>> getDeletedUsers() async {
    try {
      final response = await _dio.get('/users/deleted');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => User.fromJson(json)).toList();
      }
      throw Exception('Error al obtener usuarios eliminados');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<User> restoreUser(int userId) async {
    try {
      final response = await _dio.put('/users/$userId/restore');
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      throw Exception('Error al restaurar usuario');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> permanentDeleteUser(int userId) async {
    try {
      final response = await _dio.delete('/users/$userId/permanent');
      if (response.statusCode != 204) {
        throw Exception('Error al eliminar permanentemente el usuario');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Gestión de roles de usuarios
  Future<User> updateUserRole(int userId, int newRoleId) async {
    try {
      final response = await _dio.put('/users/$userId/role', data: {
        'roleId': newRoleId,
      });
      if (response.statusCode == 200) {
        final responseData = Map<String, dynamic>.from(response.data as Map);
        return User.fromJson(responseData['user']);
      }
      throw Exception('Error al actualizar rol del usuario');
    } catch (e) {
      throw Exception('Error actualizando rol del usuario: $e');
    }
  }
}
