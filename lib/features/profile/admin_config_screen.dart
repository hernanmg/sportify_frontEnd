import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/role_service.dart';
import 'package:sportify_amateur/core/services/admin_metrics_service.dart';
import 'package:sportify_amateur/widgets/smooth_header_gradient.dart';

class AdminConfigScreen extends StatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  State<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends State<AdminConfigScreen> {
  final AuthStorageService _authStorage = AuthStorageService();
  final AdminMetricsService _metricsService = AdminMetricsService();
  String? _userRole;
  Map<String, dynamic>? _metrics;
  // Eliminamos el scope ya que ahora es automático según el rol

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadMetrics();
  }

  Future<void> _loadUserRole() async {
    final role = await _authStorage.getRole();
    setState(() => _userRole = role);
  }

  Future<void> _loadMetrics() async {
    try {
      final metrics = await _metricsService.getDashboardMetrics(
          userRole: _userRole ?? 'player');
      setState(() => _metrics = metrics);
    } catch (e) {
      print('Error loading metrics: $e');
    }
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SmoothHeaderGradient.primary(
                Colors.red.shade700,
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Métricas del sistema
            if (_metrics != null) ...[
              _buildMetricsDashboard(),
              const SizedBox(height: 24),
            ],

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
        'title': 'Gestión de Permisos',
        'subtitle': 'Crear, editar y eliminar permisos del sistema',
        'icon': Icons.security,
        'color': Colors.deepPurple,
        'route': '/admin/permissions',
        'stats': 'Permisos disponibles',
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
                final implementedRoutes = [
                  '/roles',
                  '/admin/users',
                  '/admin/deleted-users',
                  '/admin/permissions'
                ];

                if (implementedRoutes.contains(route)) {
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

  Widget _buildMetricsDashboard() {
    if (_metrics == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getContextTitle(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Métricas específicas según el rol
        _buildRoleSpecificMetrics(),

        const SizedBox(height: 16),

        // Actividad reciente
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timeline, color: Colors.purple),
                    SizedBox(width: 8),
                    Text(
                      'Actividad Reciente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...((_metrics!['recentActivity'] as List?) ?? [])
                    .take(3)
                    .map((activity) {
                  return _buildActivityItem(activity);
                }).toList(),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Vista completa de actividad - Próximamente'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    child: const Text('Ver todo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    Color color = _getActivityColor(activity['color'] ?? 'grey');
    IconData iconData = _getActivityIcon(activity['icon'] ?? 'info');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(iconData, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              activity['message'] ?? 'Sin descripción',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            _formatTime(
                activity['timestamp'] ?? DateTime.now().toIso8601String()),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String colorName) {
    switch (colorName) {
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String iconName) {
    switch (iconName) {
      case 'person_add':
        return Icons.person_add;
      case 'group_add':
        return Icons.group_add;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'person_remove':
        return Icons.person_remove;
      case 'badge':
        return Icons.badge;
      default:
        return Icons.info;
    }
  }

  String _formatTime(String timestamp) {
    try {
      final time = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(time);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inDays}d';
      }
    } catch (e) {
      return 'ahora';
    }
  }

  String _getContextTitle() {
    switch (_userRole) {
      case 'player':
        return 'Mis Estadísticas';
      case 'team_captain':
        return 'Mi Equipo';
      case 'manager':
      case 'super_admin':
        return 'Mi Organización';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildRoleSpecificMetrics() {
    switch (_userRole) {
      case 'player':
        return _buildPlayerMetrics();
      case 'team_captain':
        return _buildTeamCaptainMetrics();
      case 'manager':
      case 'super_admin':
        return _buildManagerMetrics();
      default:
        return _buildPlayerMetrics();
    }
  }

  Widget _buildPlayerMetrics() {
    final personalStats =
        _metrics!['personal_stats'] as Map<String, dynamic>? ?? {};
    final teamContext =
        _metrics!['team_context'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Goles',
                (personalStats['goals_scored'] ?? 0).toString(),
                Icons.sports_soccer,
                Colors.green,
                '${personalStats['matches_played'] ?? 0} partidos',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Asistencias',
                (personalStats['assists'] ?? 0).toString(),
                Icons.handshake,
                Colors.blue,
                'Rating ${personalStats['average_rating'] ?? 0.0}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Equipo',
                teamContext['team_name'] ?? 'Sin equipo',
                Icons.groups,
                Colors.orange,
                'Posición ${teamContext['team_position'] ?? 'N/A'}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamCaptainMetrics() {
    final teamMgmt =
        _metrics!['team_management'] as Map<String, dynamic>? ?? {};
    final teamPerf =
        _metrics!['team_performance'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Jugadores',
                (teamMgmt['total_players'] ?? 0).toString(),
                Icons.people,
                Colors.blue,
                '${teamMgmt['active_players'] ?? 0} activos',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Partidos',
                (teamPerf['matches_played'] ?? 0).toString(),
                Icons.sports_soccer,
                Colors.green,
                '${teamPerf['matches_won'] ?? 0} ganados',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Posición',
                (teamPerf['current_position'] ?? 0).toString(),
                Icons.leaderboard,
                Colors.orange,
                '${teamPerf['goals_scored'] ?? 0} goles',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagerMetrics() {
    final overview =
        _metrics!['organization_overview'] as Map<String, dynamic>? ?? {};
    final competition =
        _metrics!['competition_stats'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Equipos',
                (overview['total_teams'] ?? 0).toString(),
                Icons.groups,
                Colors.blue,
                '${overview['total_players'] ?? 0} jugadores',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Fecha',
                (competition['matchday'] ?? 0).toString(),
                Icons.calendar_today,
                Colors.green,
                'de ${competition['total_matchdays'] ?? 0}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Goles Total',
                (competition['goals_total'] ?? 0).toString(),
                Icons.sports_soccer,
                Colors.orange,
                'Prom ${competition['average_goals_per_match'] ?? 0.0}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
