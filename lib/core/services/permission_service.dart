import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/permission.dart';

class PermissionService {
  final Dio _dio = DioClient.instance;

  Future<List<Permission>> getAllPermissions() async {
    try {
      final response = await _dio.get('/permissions');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Permission.fromJson(json)).toList();
      }
      throw Exception('Error al obtener permisos');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Permission> getPermissionById(int id) async {
    try {
      final response = await _dio.get('/permissions/$id');
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return Permission.fromJson(data);
      }
      throw Exception('Error al obtener permiso');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Helper para obtener el texto displayable del permiso
  static String getPermissionDisplayName(String permissionName) {
    switch (permissionName) {
      case 'GESTION_USUARIOS':
        return 'Gestión de Usuarios';
      case 'GESTION_ROLES':
        return 'Gestión de Roles';
      case 'GESTION_PARTIDOS':
        return 'Gestión de Partidos';
      case 'REGISTRAR_EVENTOS_PARTIDO':
        return 'Registrar Eventos de Partido';
      case 'VER_ESTADISTICAS':
        return 'Ver Estadísticas';
      case 'EDITAR_ESTADISTICAS':
        return 'Editar Estadísticas';
      case 'GESTION_CONVOCATORIAS':
        return 'Gestión de Convocatorias';
      case 'CONFIRMAR_ASISTENCIA':
        return 'Confirmar Asistencia';
      case 'GESTION_PAGOS':
        return 'Gestión de Pagos';
      case 'VER_PAGOS':
        return 'Ver Pagos';
      case 'GESTION_GASTOS':
        return 'Gestión de Gastos';
      case 'REPORTES_FINANCIEROS':
        return 'Reportes Financieros';
      case 'CHAT':
        return 'Chat';
      case 'CONFIGURACION_GLOBAL':
        return 'Configuración Global';
      case 'VER_PUBLICO':
        return 'Ver Información Pública';
      default:
        return permissionName;
    }
  }

  // Helper para obtener la descripción del permiso
  static String getPermissionDescription(String permissionName) {
    switch (permissionName) {
      case 'GESTION_USUARIOS':
        return 'Crear, editar y eliminar usuarios del sistema';
      case 'GESTION_ROLES':
        return 'Crear, editar roles y asignar permisos';
      case 'GESTION_PARTIDOS':
        return 'Crear, editar y eliminar partidos y entrenamientos';
      case 'REGISTRAR_EVENTOS_PARTIDO':
        return 'Registrar goles, asistencias, tarjetas y cambios';
      case 'VER_ESTADISTICAS':
        return 'Consultar estadísticas de equipos y jugadores';
      case 'EDITAR_ESTADISTICAS':
        return 'Modificar estadísticas de equipos y jugadores';
      case 'GESTION_CONVOCATORIAS':
        return 'Crear convocatorias y modificar horarios';
      case 'CONFIRMAR_ASISTENCIA':
        return 'Confirmar asistencia a partidos y entrenamientos';
      case 'GESTION_PAGOS':
        return 'Registrar y gestionar cuotas y deudas';
      case 'VER_PAGOS':
        return 'Consultar estado de pagos propios';
      case 'GESTION_GASTOS':
        return 'Registrar y editar gastos comunes';
      case 'REPORTES_FINANCIEROS':
        return 'Consultar reportes de ingresos y egresos';
      case 'CHAT':
        return 'Acceder y participar en el chat del equipo';
      case 'CONFIGURACION_GLOBAL':
        return 'Configurar parámetros globales de la aplicación';
      case 'VER_PUBLICO':
        return 'Ver calendario y estadísticas públicas';
      default:
        return 'Permiso personalizado';
    }
  }

  // Helper para agrupar permisos por categoría
  static Map<String, List<String>> getPermissionsByCategory() {
    return {
      'Administración': [
        'GESTION_USUARIOS',
        'GESTION_ROLES',
        'CONFIGURACION_GLOBAL',
      ],
      'Deportes': [
        'GESTION_PARTIDOS',
        'REGISTRAR_EVENTOS_PARTIDO',
        'VER_ESTADISTICAS',
        'EDITAR_ESTADISTICAS',
        'GESTION_CONVOCATORIAS',
        'CONFIRMAR_ASISTENCIA',
      ],
      'Finanzas': [
        'GESTION_PAGOS',
        'VER_PAGOS',
        'GESTION_GASTOS',
        'REPORTES_FINANCIEROS',
      ],
      'Comunicación': [
        'CHAT',
      ],
      'General': [
        'VER_PUBLICO',
      ],
    };
  }

  // Helper para verificar si un usuario tiene un permiso específico
  static bool userHasPermission(
      List<Permission> userPermissions, String permissionName) {
    return userPermissions
        .any((permission) => permission.name == permissionName);
  }

  // Helper para verificar si un usuario tiene alguno de varios permisos
  static bool userHasAnyPermission(
      List<Permission> userPermissions, List<String> permissionNames) {
    return userPermissions
        .any((permission) => permissionNames.contains(permission.name));
  }
}
