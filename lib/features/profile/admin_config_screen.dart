import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/role_service.dart';

class AdminConfigScreen extends StatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  State<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends State<AdminConfigScreen> {
  final AuthStorageService _authStorage = AuthStorageService();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await _authStorage.getRole();
    setState(() => _userRole = role);
  }

  bool _hasAdminAccess() {
    return _userRole == 'super_admin' || _userRole == 'manager';
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAdminAccess()) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acceso Denegado'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 80,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'No tienes permisos para acceder a esta sección',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Solo administradores y managers pueden gestionar la configuración del sistema',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración General'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header informativo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade600, Colors.red.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Panel de Administración',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestiona usuarios, roles y configuración del sistema',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Opciones administrativas
            _buildAdminOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminOptions() {
    final adminOptions = [
      {
        'title': 'Gestión de Usuarios',
        'subtitle': 'Ver, editar y gestionar todos los usuarios del sistema',
        'icon': Icons.people,
        'color': Colors.blue,
        'route': '/admin/users',
        'stats': 'Usuarios activos',
      },
      {
        'title': 'Roles y Permisos',
        'subtitle': 'Gestionar roles del sistema y asignar permisos',
        'icon': Icons.badge,
        'color': Colors.purple,
        'route': '/roles',
        'stats': 'Roles disponibles',
      },
      {
        'title': 'Usuarios Eliminados',
        'subtitle': 'Ver y restaurar usuarios eliminados (papelera)',
        'icon': Icons.delete_outline,
        'color': Colors.orange,
        'route': '/admin/deleted-users',
        'stats': 'En papelera',
      },
      {
        'title': 'Configuración del Sistema',
        'subtitle': 'Configurar parámetros globales de la aplicación',
        'icon': Icons.settings,
        'color': Colors.teal,
        'route': '/admin/system-config',
        'stats': 'Configuraciones',
      },
      {
        'title': 'Logs y Auditoría',
        'subtitle': 'Ver logs del sistema y auditoría de acciones',
        'icon': Icons.description,
        'color': Colors.indigo,
        'route': '/admin/logs',
        'stats': 'Registros',
      },
      {
        'title': 'Respaldos',
        'subtitle': 'Gestionar respaldos y restauración de datos',
        'icon': Icons.backup,
        'color': Colors.green,
        'route': '/admin/backups',
        'stats': 'Respaldos',
      },
    ];

    return Column(
      children: adminOptions.map((option) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                final route = option['route'] as String;

                // Verificar si es una ruta que existe
                if (route == '/roles') {
                  Navigator.pushNamed(context, route);
                } else {
                  // Para rutas no implementadas, mostrar mensaje
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${option['title']} - Próximamente'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (option['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        option['icon'] as IconData,
                        color: option['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            option['stats'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: option['color'] as Color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[400],
                          size: 16,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (option['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _userRole == 'super_admin' ? 'ADMIN' : 'MANAGER',
                            style: TextStyle(
                              fontSize: 10,
                              color: option['color'] as Color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
