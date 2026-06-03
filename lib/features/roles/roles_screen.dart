import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/role_service.dart';
import 'package:sportify_amateur/core/services/permission_service.dart';
import 'package:sportify_amateur/features/roles/role_detail_screen.dart';
import 'package:sportify_amateur/features/roles/role_form_screen.dart';
import 'package:sportify_amateur/models/role.dart';
import 'package:sportify_amateur/models/permission.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final RoleService _roleService = RoleService();
  final PermissionService _permissionService = PermissionService();

  List<Role> _roles = [];
  List<Permission> _permissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final roles = await _roleService.getAllRoles();
      final permissions = await _permissionService.getAllPermissions();

      setState(() {
        _roles = roles;
        _permissions = permissions;
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

  Future<void> _deleteRole(Role role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
            '¿Estás seguro de que quieres eliminar el rol "${RoleService.getRoleDisplayName(role.name)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _roleService.deleteRole(role.id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Rol "${RoleService.getRoleDisplayName(role.name)}" eliminado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar rol: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editRolePermissions(Role role) async {
    final rolePermissions = role.rolePermissions
            ?.map((rp) => rp.permission)
            .whereType<Permission>()
            .toList() ??
        [];
    final selectedPermissions = Set<int>.from(rolePermissions.map((p) => p.id));

    final result = await showDialog<Set<int>>(
      context: context,
      builder: (context) => _PermissionsDialog(
        permissions: _permissions,
        selectedPermissions: selectedPermissions,
        roleDisplayName: RoleService.getRoleDisplayName(role.name),
      ),
    );

    if (result != null) {
      try {
        await _roleService.updateRolePermissions(role.id, result.toList());
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Permisos actualizados para "${RoleService.getRoleDisplayName(role.name)}"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar permisos: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildRoleCard(Role role) {
    final rolePermissions = role.rolePermissions
            ?.map((rp) => rp.permission)
            .whereType<Permission>()
            .toList() ??
        [];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(role.name),
          child: Icon(
            _getRoleIcon(role.name),
            color: Colors.white,
          ),
        ),
        title: Text(
          RoleService.getRoleDisplayName(role.name),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(RoleService.getRoleDescription(role.name)),
            const SizedBox(height: 4),
            Text(
              '${rolePermissions.length} permisos asignados',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RoleDetailScreen(roleId: role.id),
                  ),
                );
                break;
              case 'edit':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RoleFormScreen(role: role),
                  ),
                ).then((_) => _loadData());
                break;
              case 'permissions':
                _editRolePermissions(role);
                break;
              case 'delete':
                if (!_isSystemRole(role.name)) {
                  _deleteRole(role);
                }
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Ver detalles'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (!_isSystemRole(role.name))
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Editar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            const PopupMenuItem(
              value: 'permissions',
              child: ListTile(
                leading: Icon(Icons.security),
                title: Text('Gestionar permisos'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (!_isSystemRole(role.name))
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoleDetailScreen(roleId: role.id),
            ),
          );
        },
      ),
    );
  }

  Color _getRoleColor(String roleName) {
    switch (roleName) {
      case 'super_admin':
        return Colors.red[700]!;
      case 'manager':
        return Colors.blue[700]!;
      case 'team_captain':
        return Colors.green[700]!;
      case 'player':
        return Colors.orange[700]!;
      case 'guest':
        return Colors.grey[700]!;
      default:
        return Colors.purple[700]!;
    }
  }

  IconData _getRoleIcon(String roleName) {
    switch (roleName) {
      case 'super_admin':
        return Icons.admin_panel_settings;
      case 'manager':
        return Icons.manage_accounts;
      case 'team_captain':
        return Icons.sports;
      case 'player':
        return Icons.person;
      case 'guest':
        return Icons.person_outline;
      default:
        return Icons.group;
    }
  }

  bool _isSystemRole(String roleName) {
    return ['super_admin', 'manager', 'dt', 'team_captain', 'player', 'guest']
        .contains(roleName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Roles'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _roles.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay roles disponibles',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    itemCount: _roles.length,
                    itemBuilder: (context, index) =>
                        _buildRoleCard(_roles[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RoleFormScreen(),
            ),
          ).then((_) => _loadData());
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _PermissionsDialog extends StatefulWidget {
  final List<Permission> permissions;
  final Set<int> selectedPermissions;
  final String roleDisplayName;

  const _PermissionsDialog({
    required this.permissions,
    required this.selectedPermissions,
    required this.roleDisplayName,
  });

  @override
  State<_PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<_PermissionsDialog> {
  late Set<int> _selectedPermissions;

  @override
  void initState() {
    super.initState();
    _selectedPermissions = Set.from(widget.selectedPermissions);
  }

  @override
  Widget build(BuildContext context) {
    final groupedPermissions = <String, List<Permission>>{};

    for (final permission in widget.permissions) {
      final category = PermissionService.getPermissionCategory(permission.name);
      groupedPermissions.putIfAbsent(category, () => []).add(permission);
    }

    return AlertDialog(
      title: Text('Permisos para ${widget.roleDisplayName}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: groupedPermissions.entries.map((entry) {
              return ExpansionTile(
                title: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                initiallyExpanded: true,
                children: entry.value.map((permission) {
                  return CheckboxListTile(
                    title: Text(PermissionService.getPermissionDisplayName(
                        permission.name)),
                    subtitle: Text(
                      PermissionService.getPermissionDescription(
                          permission.name),
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _selectedPermissions.contains(permission.id),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedPermissions.add(permission.id);
                        } else {
                          _selectedPermissions.remove(permission.id);
                        }
                      });
                    },
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedPermissions),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
