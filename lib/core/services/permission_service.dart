import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/permission.dart';

class PermissionService {
  final Dio _dio = DioClient.instance;

  // Obtener todos los permisos
  Future<List<Permission>> getAllPermissions() async {
    try {
      final response = await _dio.get('/permissions');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Permission.fromJson(json)).toList();
      }
      throw Exception('Error al obtener los permisos');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear un permiso
  Future<Permission> createPermission(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/permissions', data: data);
      if (response.statusCode == 201) {
        final permissionData = Map<String, dynamic>.from(response.data as Map);
        return Permission.fromJson(permissionData);
      }
      throw Exception('Error al crear el permiso');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener un permiso por ID
  Future<Permission> getPermissionById(int id) async {
    try {
      final response = await _dio.get('/permissions/$id');
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return Permission.fromJson(data);
      }
      throw Exception('Permiso no encontrado');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar un permiso
  Future<Permission> updatePermission(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/permissions/$id', data: data);
      if (response.statusCode == 200) {
        final permissionData = Map<String, dynamic>.from(response.data as Map);
        return Permission.fromJson(permissionData);
      }
      throw Exception('Error al actualizar el permiso');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar un permiso
  Future<void> deletePermission(int id) async {
    try {
      final response = await _dio.delete('/permissions/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar el permiso');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Métodos de ayuda para mostrar información de permisos
  static String getPermissionDisplayName(String name) {
    switch (name) {
      case 'create_user':
        return 'Crear Usuario';
      case 'read_user':
        return 'Ver Usuario';
      case 'update_user':
        return 'Editar Usuario';
      case 'delete_user':
        return 'Eliminar Usuario';
      case 'manage_roles':
        return 'Gestionar Roles';
      case 'manage_permissions':
        return 'Gestionar Permisos';
      case 'create_team':
        return 'Crear Equipo';
      case 'manage_team':
        return 'Gestionar Equipo';
      case 'create_event':
        return 'Crear Evento';
      case 'manage_event':
        return 'Gestionar Evento';
      case 'create_match':
        return 'Crear Partido';
      case 'manage_match':
        return 'Gestionar Partido';
      case 'view_reports':
        return 'Ver Reportes';
      case 'manage_system':
        return 'Gestionar Sistema';
      default:
        return name
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1)
                : '')
            .join(' ');
    }
  }

  static String getPermissionDescription(String name) {
    switch (name) {
      case 'create_user':
        return 'Permite crear nuevos usuarios en el sistema';
      case 'read_user':
        return 'Permite ver información de usuarios';
      case 'update_user':
        return 'Permite editar información de usuarios';
      case 'delete_user':
        return 'Permite eliminar usuarios del sistema';
      case 'manage_roles':
        return 'Permite crear, editar y eliminar roles';
      case 'manage_permissions':
        return 'Permite gestionar permisos del sistema';
      case 'create_team':
        return 'Permite crear nuevos equipos';
      case 'manage_team':
        return 'Permite gestionar equipos y sus miembros';
      case 'create_event':
        return 'Permite crear eventos deportivos';
      case 'manage_event':
        return 'Permite gestionar eventos y torneos';
      case 'create_match':
        return 'Permite crear partidos';
      case 'manage_match':
        return 'Permite gestionar partidos y resultados';
      case 'view_reports':
        return 'Permite ver reportes y estadísticas';
      case 'manage_system':
        return 'Acceso completo al sistema';
      default:
        return 'Permiso del sistema';
    }
  }

  static List<String> getPermissionCategories() {
    return [
      'Usuarios',
      'Roles y Permisos',
      'Equipos',
      'Eventos',
      'Partidos y Estadísticas',
      'Financiero',
      'Comunicación',
      'Reportes',
      'Sistema'
    ];
  }

  static String getPermissionCategory(String name) {
    final nameLower = name.toLowerCase();

    if (nameLower.contains('usuario') || nameLower.contains('user'))
      return 'Usuarios';
    if (nameLower.contains('role') ||
        nameLower.contains('permission') ||
        nameLower.contains('permisos')) return 'Roles y Permisos';
    if (nameLower.contains('equipo') || nameLower.contains('team'))
      return 'Equipos';
    if (nameLower.contains('evento') ||
        nameLower.contains('event') ||
        nameLower.contains('convocatoria')) return 'Eventos';
    if (nameLower.contains('partido') ||
        nameLower.contains('match') ||
        nameLower.contains('estadistica')) return 'Partidos y Estadísticas';
    if (nameLower.contains('pago') ||
        nameLower.contains('gasto') ||
        nameLower.contains('financiero') ||
        nameLower.contains('payment')) return 'Financiero';
    if (nameLower.contains('reporte') ||
        nameLower.contains('report') ||
        nameLower.contains('publico')) return 'Reportes';
    if (nameLower.contains('configuracion') ||
        nameLower.contains('config') ||
        nameLower.contains('system') ||
        nameLower.contains('global')) return 'Sistema';
    if (nameLower.contains('chat') ||
        nameLower.contains('mensaje') ||
        nameLower.contains('comunicacion')) return 'Comunicación';

    return 'General';
  }

  static IconData getPermissionIcon(String permissionName) {
    switch (permissionName) {
      case 'GESTION_USUARIOS':
        return Icons.people;
      case 'GESTION_ROLES':
        return Icons.badge;
      case 'GESTION_PARTIDOS':
        return Icons.sports_soccer;
      case 'REGISTRAR_EVENTOS_PARTIDO':
        return Icons.event_note;
      case 'VER_ESTADISTICAS':
        return Icons.bar_chart;
      case 'EDITAR_ESTADISTICAS':
        return Icons.edit_note;
      case 'GESTION_CONVOCATORIAS':
        return Icons.calendar_month;
      case 'CONFIRMAR_ASISTENCIA':
        return Icons.check_circle_outline;
      case 'GESTION_PAGOS':
        return Icons.payment;
      case 'VER_PAGOS':
        return Icons.receipt_long;
      case 'GESTION_GASTOS':
        return Icons.money_off;
      case 'REPORTES_FINANCIEROS':
        return Icons.analytics;
      case 'CHAT':
        return Icons.chat;
      case 'CONFIGURACION_GLOBAL':
        return Icons.settings;
      case 'VER_PUBLICO':
        return Icons.public;
      default:
        return Icons.info_outline;
    }
  }
}
