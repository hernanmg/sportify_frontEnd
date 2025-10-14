import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/user_service.dart';
import 'package:sportify_amateur/core/services/role_service.dart';
import 'package:sportify_amateur/models/user.dart';
import 'package:sportify_amateur/models/role.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final UserService _userService = UserService();
  final RoleService _roleService = RoleService();
  final TextEditingController _searchController = TextEditingController();

  List<User> _users = [];
  List<User> _filteredUsers = [];
  List<Role> _availableRoles = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.findAll();
      final roles = await _roleService.getAllRoles();

      setState(() {
        _users = users;
        _filteredUsers = users;
        _availableRoles = roles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchQuery = query;
      _filteredUsers = _users.where((user) {
        return user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            (user.username?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar a "${user.name}"?\n\n'
          'El usuario será movido a la papelera y podrá ser restaurado más tarde.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _userService.delete(user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario "${user.name}" eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar usuario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changeUserRole(User user) async {
    Role? selectedRole = user.roles.isNotEmpty ? user.roles.first : null;

    final result = await showDialog<Role>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Cambiar rol de ${user.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Rol actual: ${user.roles.isNotEmpty ? RoleService.getRoleDisplayName(user.roles.first.name) : 'Sin rol'}'),
                const SizedBox(height: 16),
                DropdownButtonFormField<Role>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Nuevo rol',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true, // Previene overflow
                  items: _availableRoles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(
                        RoleService.getRoleDisplayName(role.name),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (role) {
                    setState(() {
                      selectedRole = role;
                    });
                  },
                ),
                if (selectedRole != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Descripción del rol:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          RoleService.getRoleDescription(selectedRole!.name),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(selectedRole),
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        final updatedUser =
            await _userService.updateUserRole(user.id, result.id);

        // Actualizar la lista local con el usuario modificado
        setState(() {
          final index = _filteredUsers.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            _filteredUsers[index] = updatedUser;
          }
          final allIndex = _users.indexWhere((u) => u.id == user.id);
          if (allIndex != -1) {
            _users[allIndex] = updatedUser;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Rol de "${updatedUser.name}" cambiado a "${RoleService.getRoleDisplayName(result.name)}"'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar rol: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/admin/deleted-users');
            },
            tooltip: 'Ver usuarios eliminados',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar usuarios por nombre o email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Estadísticas
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Total Usuarios',
                  _users.length.toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Resultados',
                  _filteredUsers.length.toString(),
                  Icons.search,
                  Colors.green,
                ),
                _buildStatCard(
                  'Activos',
                  _users.where((u) => u.isActive).length.toString(),
                  Icons.check_circle,
                  Colors.orange,
                ),
              ],
            ),
          ),

          // Lista de usuarios
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return _buildUserCard(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No se encontraron usuarios con "$_searchQuery"'
                : 'No hay usuarios disponibles',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Intenta con otros términos de búsqueda'
                : 'Los usuarios aparecerán aquí cuando se registren',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final primaryRole = user.roles.isNotEmpty ? user.roles.first : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive ? Colors.green : Colors.red,
          child: Text(
            user.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                if (primaryRole != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRoleColor(primaryRole.name).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      RoleService.getRoleDisplayName(primaryRole.name),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getRoleColor(primaryRole.name),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 12,
                      color: user.isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          onSelected: (value) {
            switch (value) {
              case 'role':
                _changeUserRole(user);
                break;
              case 'delete':
                _deleteUser(user);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'role',
              child: Row(
                children: [
                  Icon(Icons.badge, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Cambiar rol'),
                ],
              ),
            ),
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
      ),
    );
  }

  Color _getRoleColor(String roleName) {
    switch (roleName) {
      case 'super_admin':
        return Colors.red;
      case 'manager':
        return Colors.purple;
      case 'team_captain':
        return Colors.orange;
      case 'player':
        return Colors.blue;
      case 'guest':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
