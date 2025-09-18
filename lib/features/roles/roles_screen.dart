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
      _rolesFuture = _roleService.fetchMockRoles();
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
      await _roleService.deleteMocRole(role.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${role.name} has been deleted')),
      );
      _loadRoles();
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
                return ListTile(
                  title: Text(role.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteRole(context, role),
                    // onPressed: () async {
                    //   await _roleService.deleteMocRole(role.id);
                    //   setState(() {
                    //     _rolesFuture = _roleService.fetchMockRoles();
                    //   });
                    // },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RoleDetailScreen(role: role)),
                    );
                  },
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
