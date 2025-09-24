import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/role.dart';

class RoleService {
  final Dio _dio = DioClient.instance;

  Future<List<Role>> getAllRoles() async {
    try {
      final response = await _dio.get('/roles');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Role.fromJson(json)).toList();
      }
      throw Exception('Error al obtener roles');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<Role>> getAvailableRoles() async {
    try {
      // Obtener roles que son asignables por usuarios (excluyendo super_admin)
      final allRoles = await getAllRoles();
      return allRoles.where((role) => role.name != 'super_admin').toList();
    } catch (e) {
      throw Exception('Error al obtener roles disponibles: $e');
    }
  }

  Future<List<Role>> getTeamRoles() async {
    try {
      // Roles específicos para equipos
      final allRoles = await getAllRoles();
      return allRoles
          .where((role) => role.name == 'team_captain' || role.name == 'player')
          .toList();
    } catch (e) {
      throw Exception('Error al obtener roles de equipo: $e');
    }
  }

  Future<Role> getRoleById(int id) async {
    try {
      final response = await _dio.get('/roles/$id');
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return Role.fromJson(data);
      }
      throw Exception('Error al obtener rol');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Helper para obtener el texto displayable del rol
  static String getRoleDisplayName(String roleName) {
    switch (roleName) {
      case 'super_admin':
        return 'Super Administrador';
      case 'manager':
        return 'Manager/Administrador';
      case 'team_captain':
        return 'Capitán de Equipo';
      case 'player':
        return 'Jugador';
      case 'guest':
        return 'Invitado';
      default:
        return roleName;
    }
  }

  // Helper para obtener la descripción del rol
  static String getRoleDescription(String roleName) {
    switch (roleName) {
      case 'super_admin':
        return 'Control total del sistema';
      case 'manager':
        return 'Gestiona ligas, torneos y usuarios';
      case 'team_captain':
        return 'Gestiona su equipo y jugadores';
      case 'player':
        return 'Participa en equipos y actividades';
      case 'guest':
        return 'Usuario básico sin equipo';
      default:
        return 'Rol personalizado';
    }
  }

  // Helper para validar si un rol puede ser asignado por el usuario actual
  static bool canAssignRole(String currentUserRole, String targetRole) {
    // super_admin puede asignar cualquier rol
    if (currentUserRole == 'super_admin') return true;

    // manager puede asignar roles de menor jerarquía
    if (currentUserRole == 'manager') {
      return ['team_captain', 'player', 'guest'].contains(targetRole);
    }

    // team_captain solo puede asignar player
    if (currentUserRole == 'team_captain') {
      return targetRole == 'player';
    }

    // Otros roles no pueden asignar
    return false;
  }

  // Helper para determinar la jerarquía del rol (mayor número = mayor poder)
  static int getRoleHierarchy(String roleName) {
    switch (roleName) {
      case 'super_admin':
        return 5;
      case 'manager':
        return 4;
      case 'team_captain':
        return 3;
      case 'player':
        return 2;
      case 'guest':
        return 1;
      default:
        return 0;
    }
  }
}
