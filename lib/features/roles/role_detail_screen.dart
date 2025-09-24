import 'package:flutter/material.dart';
import 'package:sportify_amateur/models/role.dart';
import 'package:sportify_amateur/core/services/role_service.dart';

class RoleDetailScreen extends StatelessWidget {
  final Role role;

  const RoleDetailScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(role.name),
      ),
      body: Center(
        child: Card(
          elevation: 8.0, // Sombra para el efecto flotante
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Bordes redondeados
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    role.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  role.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  role.description ?? RoleService.getRoleDescription(role.name),
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color.fromARGB(255, 39, 37, 37),
                  ),
                ),
                const Divider(
                  height: 30,
                  thickness: 1,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Información del Rol:',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.badge, color: Colors.blue),
                  title: const Text('Nombre del Rol'),
                  subtitle: Text(RoleService.getRoleDisplayName(role.name)),
                ),
                ListTile(
                  leading: const Icon(Icons.info, color: Colors.orange),
                  title: const Text('Jerarquía'),
                  subtitle:
                      Text('Nivel ${RoleService.getRoleHierarchy(role.name)}'),
                ),
                ListTile(
                  leading: const Icon(Icons.date_range, color: Colors.green),
                  title: const Text('Creado'),
                  subtitle: Text(
                      '${role.createdAt.day}/${role.createdAt.month}/${role.createdAt.year}'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
