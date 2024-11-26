import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  Future<String?> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  List<Map<String, dynamic>> get allFeatures => [
        {
          'title': 'Autenticación y Roles',
          'icon': Icons.security,
          'description': 'Gestiona accesos y permisos de usuarios',
          'requiredRole': 'admin',
          'color': Colors.blue,
        },
        {
          'title': 'Estadísticas de Juego',
          'icon': Icons.bar_chart,
          'description': 'Analiza el rendimiento de tus equipos y jugadores',
          'requiredRole': 'user',
          'color': Colors.indigo,
        },
        {
          'title': 'Finanzas y Pagos',
          'icon': Icons.attach_money,
          'description': 'Controla ingresos, gastos y pagos',
          'requiredRole': 'user',
          'color': Colors.green,
        },
        {
          'title': 'Gestión de Asistencia y Horarios',
          'icon': Icons.calendar_today,
          'description': 'Organiza entrenamientos y eventos',
          'requiredRole': 'user',
          'color': Colors.blueGrey,
        },
        {
          'title': 'Comunicaciones',
          'icon': Icons.message,
          'description': 'Mantén informados a todos los miembros del equipo',
          'requiredRole': 'user',
          'color': Colors.orange,
        },
        {
          'title': 'Configuración Multilenguaje',
          'icon': Icons.language,
          'description': 'Adapta la app a diferentes idiomas',
          'requiredRole': 'user',
          'color': Colors.amberAccent,
        },
        {
          'title': 'Administración y Reportes',
          'icon': Icons.assessment,
          'description': 'Genera informes detallados y gestiona la app',
          'requiredRole': 'admin',
          'color': Colors.teal,
        },
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SportManage Pro')),
      body: FutureBuilder<String?>(
        future: _getUserRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final role = snapshot.data;
          final features = allFeatures;
          final filteredFeatures = features
              .where((feature) =>
                  feature['requiredRole'] != null && role == 'admin' ||
                  feature['requiredRole'] == 'user')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: filteredFeatures.map((feature) {
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: Icon(feature['icon'], size: 48, color: feature['color'],),
                  title: Text(feature['title']),
                  subtitle: Text(feature['description']),
                  onTap: () {
                    Navigator.pushNamed(
                        context,
                        feature['title'] == 'Autenticación y Roles'
                            ? '/secondary'
                            : '/game-stats'); // Define la navegación
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
