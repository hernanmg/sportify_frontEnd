import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/user_service.dart';
import 'package:sportify_amateur/features/users/user_detail_screen.dart';
import 'package:sportify_amateur/features/users/users_form_screen.dart';
import 'package:sportify_amateur/models/user.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late Future<List<User>> _usersFuture;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = _userService.fetchMockUsers();
    });
  }

  void _deleteUser(BuildContext context, User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete ${user.name}?'),
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
      await _userService.deleteMockUser(user.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} has been deleted')),
      );
      _loadUsers();
    }
  }

  void _navigateToAddUser(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserFormScreen()),
    ).then((_) => _loadUsers()); // Refresh users after returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
      ),
      body: FutureBuilder<List<User>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found'));
          } else {
            final users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final selectedUser = users[index];
                return ListTile(
                  title: Text(selectedUser.name),
                  subtitle: Text(selectedUser.email),
                  onTap: () {
                    // Navega a detalles del usuario (puedes implementarlo después)
                    //  Navigator.pushNamed(context, '/userDetail');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              UserDetailScreen(user: selectedUser)),
                    );
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteUser(context, selectedUser),
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
