import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/role_service.dart';
import 'package:sportify_amateur/features/roles/role_detail_screen.dart';
import 'package:sportify_amateur/features/roles/role_form_screen.dart';
import 'package:sportify_amateur/models/role.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  late Future<List<Role>> _rolesFuture;
  final RoleService _roleService = RoleService();

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  void _loadRoles() {
    setState(() {
      _rolesFuture = _roleService.getAllRoles();
    });
  }

  void _deleteRole(BuildContext context, Role role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete ${role.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Por ahora solo mostrar mensaje ya que no tenemos endpoint de eliminación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Función de eliminar rol no implementada aún'),
          backgroundColor: Colors.orange,
        ),
      );
      // _loadRoles(); // Comentado hasta implementar delete
    }
  }

  void _navigateToAddUser(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RoleFormScreen()),
    ).then((_) => _loadRoles()); // Refresh users after returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles'),
      ),
      body: FutureBuilder<List<Role>>(
        future: _rolesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No roles found'));
          } else {
            final roles = snapshot.data!;
            return ListView.builder(
              itemCount: roles.length,
              itemBuilder: (context, index) {
                final role = roles[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(role.name.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(RoleService.getRoleDisplayName(role.name)),
                    subtitle: Text(role.description ??
                        RoleService.getRoleDescription(role.name)),
                    trailing: PopupMenuButton(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteRole(context, role);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RoleDetailScreen(role: role)),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddUser(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
