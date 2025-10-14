import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

  // CRUD de roles
  Future<Role> createRole(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/roles', data: data);
      if (response.statusCode == 201) {
        final roleData = Map<String, dynamic>.from(response.data as Map);
        return Role.fromJson(roleData);
      }
      throw Exception('Error al crear el rol');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Role> updateRole(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/roles/$id', data: data);
      if (response.statusCode == 200) {
        final roleData = Map<String, dynamic>.from(response.data as Map);
        return Role.fromJson(roleData);
      }
      throw Exception('Error al actualizar el rol');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> deleteRole(int id) async {
    try {
      final response = await _dio.delete('/roles/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar el rol');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Gestión de permisos de roles
  Future<void> assignPermissionToRole(int roleId, int permissionId) async {
    try {
      final response = await _dio.post('/roles/$roleId/permissions', data: {
        'permissionId': permissionId,
      });
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al asignar permiso al rol');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> removePermissionFromRole(int roleId, int permissionId) async {
    try {
      final response =
          await _dio.delete('/roles/$roleId/permissions/$permissionId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al remover permiso del rol');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Role> updateRolePermissions(
      int roleId, List<int> permissionIds) async {
    try {
      final response = await _dio.put('/roles/$roleId/permissions', data: {
        'permissionIds': permissionIds,
      });
      if (response.statusCode == 200) {
        final responseData = Map<String, dynamic>.from(response.data as Map);
        return Role.fromJson(responseData['role']);
      }
      throw Exception('Error al actualizar permisos del rol');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Role> fetchRoleWithPermissions(int roleId) async {
    try {
      final response = await _dio.get('/roles/$roleId');
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return Role.fromJson(data);
      }
      throw Exception('Error al cargar rol con permisos');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Helpers para UI
  static bool isSystemRole(String roleName) {
    return ['super_admin', 'manager', 'team_captain', 'player', 'guest']
        .contains(roleName);
  }

  static IconData getRoleIcon(String roleName) {
    switch (roleName) {
      case 'super_admin':
        return Icons.security;
      case 'manager':
        return Icons.admin_panel_settings;
      case 'team_captain':
        return Icons.military_tech;
      case 'player':
        return Icons.sports_soccer;
      case 'guest':
        return Icons.person_outline;
      default:
        return Icons.category;
    }
  }
}
