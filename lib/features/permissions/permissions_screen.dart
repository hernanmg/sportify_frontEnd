import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/permission_service.dart';
import 'package:sportify_amateur/models/permission.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final PermissionService _permissionService = PermissionService();

  List<Permission> _permissions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoading = true);
    try {
      final permissions = await _permissionService.getAllPermissions();
      setState(() {
        _permissions = permissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar permisos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Permission> get _filteredPermissions {
    if (_searchQuery.isEmpty) return _permissions;

    return _permissions.where((permission) {
      final displayName =
          PermissionService.getPermissionDisplayName(permission.name)
              .toLowerCase();
      final description =
          PermissionService.getPermissionDescription(permission.name)
              .toLowerCase();
      final query = _searchQuery.toLowerCase();

      return displayName.contains(query) ||
          description.contains(query) ||
          permission.name.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _createPermission() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _PermissionFormDialog(),
    );

    if (result != null) {
      try {
        await _permissionService.createPermission(result);
        await _loadPermissions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permiso "${result['name']}" creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear permiso: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editPermission(Permission permission) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _PermissionFormDialog(
        initialName: permission.name,
        initialDescription: permission.description ?? '',
      ),
    );

    if (result != null) {
      try {
        await _permissionService.updatePermission(permission.id, result);
        await _loadPermissions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Permiso "${result['name']}" actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar permiso: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deletePermission(Permission permission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el permiso "${PermissionService.getPermissionDisplayName(permission.name)}"?\n\n'
          'Esta acción puede afectar a los roles que tengan este permiso asignado.',
        ),
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
        await _permissionService.deletePermission(permission.id);
        await _loadPermissions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Permiso "${PermissionService.getPermissionDisplayName(permission.name)}" eliminado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar permiso: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildPermissionCard(Permission permission) {
    final category = PermissionService.getPermissionCategory(permission.name);
    final displayName =
        PermissionService.getPermissionDisplayName(permission.name);
    final description =
        PermissionService.getPermissionDescription(permission.name);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(category),
          child: Icon(
            _getCategoryIcon(category),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getCategoryColor(category).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 11,
                  color: _getCategoryColor(category),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editPermission(permission);
                break;
              case 'delete':
                _deletePermission(permission);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
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
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Usuarios':
        return Colors.blue;
      case 'Roles y Permisos':
        return Colors.purple;
      case 'Equipos':
        return Colors.green;
      case 'Eventos':
        return Colors.orange;
      case 'Partidos':
        return Colors.red;
      case 'Reportes':
        return Colors.indigo;
      case 'Sistema':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Usuarios':
        return Icons.people;
      case 'Roles y Permisos':
        return Icons.security;
      case 'Equipos':
        return Icons.groups;
      case 'Eventos':
        return Icons.event;
      case 'Partidos':
        return Icons.sports_soccer;
      case 'Reportes':
        return Icons.analytics;
      case 'Sistema':
        return Icons.settings;
      default:
        return Icons.lock;
    }
  }

  Widget _buildGroupedPermissions() {
    final groupedPermissions = <String, List<Permission>>{};

    for (final permission in _filteredPermissions) {
      final category = PermissionService.getPermissionCategory(permission.name);
      groupedPermissions.putIfAbsent(category, () => []).add(permission);
    }

    return ListView(
      children: groupedPermissions.entries.map((entry) {
        return ExpansionTile(
          title: Row(
            children: [
              Icon(
                _getCategoryIcon(entry.key),
                color: _getCategoryColor(entry.key),
              ),
              const SizedBox(width: 8),
              Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCategoryColor(entry.key).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entry.value.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getCategoryColor(entry.key),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          initiallyExpanded: true,
          children: entry.value.map((permission) {
            return _buildPermissionCard(permission);
          }).toList(),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Permisos'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPermissions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar permisos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildStatItem(
                  icon: Icons.security,
                  label: 'Total',
                  value: '${_permissions.length}',
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  icon: Icons.visibility,
                  label: 'Mostrando',
                  value: '${_filteredPermissions.length}',
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  icon: Icons.category,
                  label: 'Categorías',
                  value:
                      '${PermissionService.getPermissionCategories().length}',
                  color: Colors.orange,
                ),
              ],
            ),
          ),

          const Divider(),

          // Lista de permisos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPermissions.isEmpty
                    ? _buildEmptyState()
                    : _buildGroupedPermissions(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPermission,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No hay permisos disponibles'
                : 'Sin resultados',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Crea tu primer permiso para comenzar'
                : 'Intenta con otros términos de búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionFormDialog extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;

  const _PermissionFormDialog({
    this.initialName,
    this.initialDescription,
  });

  @override
  State<_PermissionFormDialog> createState() => _PermissionFormDialogState();
}

class _PermissionFormDialogState extends State<_PermissionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialName != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Permiso' : 'Crear Permiso'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Permiso',
                  hintText: 'ej. create_user, manage_team',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  if (value.contains(' ')) {
                    return 'Use guiones bajos en lugar de espacios';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Describe qué permite hacer este permiso',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La descripción es requerida';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'description': _descriptionController.text.trim(),
              });
            }
          },
          child: Text(isEditing ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }
}
