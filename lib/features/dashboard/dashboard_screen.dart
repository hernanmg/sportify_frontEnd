import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/themes_provider.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/notification_service.dart';
import 'package:sportify_amateur/features/dashboard/team_membership_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.startBackgroundSync();
  }

  Future<String?> _getUserRole() async {
    final authStorage = AuthStorageService();
    return await authStorage.getRole();
  }

  static List<Map<String, dynamic>> get allFeatures => [
        {
          'title': 'Gestión Deportiva',
          'icon': Icons.sports_soccer,
          'description':
              'Lista de buena fe, convocatorias y eventos del equipo',
          'requiredRole': 'user',
          'color': Colors.green,
          'route': '/sports/roster',
        },
        {
          'title': 'Gestión de Equipos',
          'icon': Icons.groups,
          'description':
              'Crear, editar y administrar equipos de la organización',
          'requiredRole': 'manager',
          'color': Colors.blue,
          'route': '/teams',
        },
        {
          'title': 'Autenticación y Roles',
          'icon': Icons.security,
          'description': 'Gestiona accesos y permisos de usuarios',
          'requiredRole': 'admin',
          'color': Colors.blue,
          'route': '/secondary',
        },
        {
          'title': 'Estadísticas de Juego',
          'icon': Icons.bar_chart,
          'description': 'Analiza el rendimiento de tus equipos y jugadores',
          'requiredRole': 'user',
          'color': Colors.indigo,
          'route': '/game-stats',
        },
        {
          'title': 'Finanzas y Pagos',
          'icon': Icons.attach_money,
          'description': 'Controla ingresos, gastos y pagos',
          'requiredRole': 'user',
          'color': Colors.green,
          'route': '/finances',
        },
        {
          'title': 'Panel del equipo',
          'icon': Icons.dashboard_customize,
          'description':
              'Resumen DT: morosos, confirmaciones pendientes, asistencia y caja del mes',
          'requiredRole': 'user',
          'color': Colors.teal,
          'route': '/sports/admin-panel',
        },
        {
          'title': 'Gestión de Asistencia y Horarios',
          'icon': Icons.calendar_today,
          'description': 'Organiza entrenamientos y eventos',
          'requiredRole': 'user',
          'color': Colors.blueGrey,
          'route': '/game-stats',
        },
        {
          'title': 'Comunicaciones',
          'icon': Icons.message,
          'description': 'Mantén informados a todos los miembros del equipo',
          'requiredRole': 'user',
          'color': Colors.orange,
          'route': '/game-stats',
        },
        {
          'title': 'Configuración Multilenguaje',
          'icon': Icons.language,
          'description': 'Adapta la app a diferentes idiomas',
          'requiredRole': 'user',
          'color': Colors.amberAccent,
          'route': '/game-stats',
        },
        {
          'title': 'Mis eventos',
          'icon': Icons.event_available,
          'description':
              'Invitaciones sociales, confirmar asistencia y gastos compartidos',
          'requiredRole': 'user',
          'color': Colors.deepPurple,
          'route': '/my-events',
        },
        {
          'title': 'Mis partidos',
          'icon': Icons.how_to_vote,
          'description': 'Convocatorias y votación post-partido',
          'requiredRole': 'user',
          'color': Colors.green,
          'route': '/sports/my-matches',
        },
        {
          'title': 'Notificaciones',
          'icon': Icons.notifications,
          'description': 'Ver notificaciones de eventos y convocatorias',
          'requiredRole': 'user',
          'color': Colors.orange,
          'route': '/notifications',
        },
        {
          'title': 'Administración y Reportes',
          'icon': Icons.assessment,
          'description': 'Genera informes detallados y gestiona la app',
          'requiredRole': 'admin',
          'color': Colors.teal,
          'route': '/game-stats',
        },
      ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sports Manager Pro'),
        actions: [
          // Icono de perfil/configuración
          FutureBuilder<String?>(
            future: _getUserRole(),
            builder: (context, snapshot) {
              return IconButton(
                icon: const Icon(Icons.account_circle),
                tooltip: 'Perfil y Configuración',
                onPressed: () {
                  Navigator.pushNamed(context, '/profile');
                },
              );
            },
          ),
          Switch(
            value: isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _getUserRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final role = snapshot.data;
          final features = allFeatures;
          final filteredFeatures = features.where((feature) {
            final requiredRole = feature['requiredRole'];
            if (requiredRole == null) return true;

            // Super admin puede ver todo
            if (role == 'super_admin') return true;

            // Manager / capitán del club: gestión deportiva y equipos
            if ((role == 'manager' ||
                    role == 'team_captain' ||
                    role == 'dt') &&
                (requiredRole == 'manager' || requiredRole == 'user'))
              return true;

            // Player puede ver características de user
            if (role == 'player' && requiredRole == 'user') return true;

            // Admin legacy (mantener compatibilidad)
            if (role == 'admin' &&
                (requiredRole == 'admin' || requiredRole == 'user'))
              return true;

            // Características públicas (user)
            if (requiredRole == 'user') return true;

            return false;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const TeamMembershipBanner(),
              ...filteredFeatures.map((feature) {
              final isNotifications = feature['route'] == '/notifications';
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: isNotifications
                      ? StreamBuilder<int>(
                          stream: _notificationService.unreadCountStream,
                          initialData: 0,
                          builder: (context, snap) {
                            final count = snap.data ?? 0;
                            return Badge(
                              isLabelVisible: count > 0,
                              label: Text(
                                count > 99 ? '99+' : '$count',
                                style: const TextStyle(fontSize: 10),
                              ),
                              child: Icon(
                                feature['icon'],
                                size: 48,
                                color: feature['color'],
                              ),
                            );
                          },
                        )
                      : Icon(
                          feature['icon'],
                          size: 48,
                          color: feature['color'],
                        ),
                  title: Text(feature['title']),
                  subtitle: Text(feature['description']),
                  onTap: () {
                    final routeName = feature['route'];
                    if (routeName != null) {
                      Navigator.pushNamed(context, routeName).then((_) {
                        if (isNotifications) {
                          _notificationService.refreshUnreadCount();
                        }
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Ruta no definida para ${feature['title']}'),
                        ),
                      );
                    }
                  },
                ),
              );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
