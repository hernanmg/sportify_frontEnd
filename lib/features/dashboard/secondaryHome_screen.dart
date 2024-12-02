import 'package:flutter/material.dart';

class SecondaryHomeScreen extends StatelessWidget {
  const SecondaryHomeScreen({super.key});

  List<Map<String, dynamic>> get allFeatures => [
        {
          'title': 'Usuarios',
          'icon': Icons.people,
          'description': 'Gestiona accesos y permisos de usuarios',
          'requiredRole': 'admin',
          'color': Colors.blue,
          'route': '/users',
        },
        {
          'title': 'Roles',
          'icon': Icons.manage_accounts     ,
          'description': 'Gestiona Roles para la aplicación',
          'requiredRole': 'admin',
          'color': Colors.indigo,
          'route': '/roles',
        }
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Cuentas')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: allFeatures.map((feature) {
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
      ),
    );
  }
}
