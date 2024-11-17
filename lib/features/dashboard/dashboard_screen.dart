import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SportManage Pro'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
              'assets/logo_placeholder.png'), // Placeholder para el logo
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFeatureCard(
            context,
            'Autenticación y Roles',
            Icons.security,
            'Gestiona accesos y permisos de usuarios',
          ),
          _buildFeatureCard(
            context,
            'Estadísticas de Juego',
            Icons.bar_chart,
            'Analiza el rendimiento de tus equipos y jugadores',
          ),
          _buildFeatureCard(
            context,
            'Finanzas y Pagos',
            Icons.attach_money,
            'Controla ingresos, gastos y pagos',
          ),
          _buildFeatureCard(
            context,
            'Gestión de Asistencia y Horarios',
            Icons.calendar_today,
            'Organiza entrenamientos y eventos',
          ),
          _buildFeatureCard(
            context,
            'Comunicaciones',
            Icons.message,
            'Mantén informados a todos los miembros del equipo',
          ),
          _buildFeatureCard(
            context,
            'Configuración Multilenguaje',
            Icons.language,
            'Adapta la app a diferentes idiomas',
          ),
          _buildFeatureCard(
            context,
            'Administración y Reportes',
            Icons.assessment,
            'Genera informes detallados y gestiona la app',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, String title, IconData icon, String description) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, size: 48, color: Theme.of(context).primaryColor),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        subtitle: Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        onTap: () {
          // Aquí puedes agregar la navegación a cada módulo
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navegando a $title')),
          );
        },
      ),
    );
  }
}
