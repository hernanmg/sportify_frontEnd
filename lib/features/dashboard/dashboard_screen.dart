import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/themes_provider.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<String?> _getUserRole() async {
    final authStorage = AuthStorageService();
    return await authStorage.getRole();
  }

  List<Map<String, dynamic>> get allFeatures => [
        {
          'title': 'Gestión Deportiva',
          'icon': Icons.sports_soccer,
          'description':
              'Lista de buena fe, convocatorias y eventos del equipo',
          'requiredRole': 'manager',
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
          'route': '/game-stats',
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

            // Manager puede ver características de manager y user
            if (role == 'manager' &&
                (requiredRole == 'manager' || requiredRole == 'user'))
              return true;

            // Team captain puede ver características de team_captain y user
            if (role == 'team_captain' &&
                (requiredRole == 'team_captain' || requiredRole == 'user'))
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
            children: filteredFeatures.map((feature) {
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: Icon(
                    feature['icon'],
                    size: 48,
                    color: feature['color'],
                  ),
                  title: Text(feature['title']),
                  subtitle: Text(feature['description']),
                  onTap: () {
                    final routeName = feature['route'];
                    if (routeName != null) {
                      Navigator.pushNamed(context, routeName);
                    } else {
                      // Manejo para rutas no definidas
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Ruta no definida para ${feature['title']}'),
                        ),
                      );
                    }
                    // Navigator.pushNamed(
                    //     context,
                    //     feature['title'] == 'Autenticación y Roles'
                    //         ? '/secondary'
                    //         : '/game-stats'); // Define la navegación
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
