import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/role_service.dart';
import 'package:sportify_amateur/core/services/permission_service.dart';
import 'package:sportify_amateur/models/role.dart';
import 'package:sportify_amateur/models/permission.dart';

class RoleFormScreen extends StatefulWidget {
  final Role? role;

  const RoleFormScreen({super.key, this.role});

  @override
  State<RoleFormScreen> createState() => _RoleFormScreenState();
}

class _RoleFormScreenState extends State<RoleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _description;
  Set<int> _selectedPermissions = <int>{};

  final RoleService _roleService = RoleService();
  final PermissionService _permissionService = PermissionService();

  List<Permission> _availablePermissions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _name = widget.role?.name ?? '';
    _description = widget.role?.description ?? '';

    if (widget.role != null) {
      final rolePermissions = widget.role!.rolePermissions
              ?.map((rp) => rp.permission)
              .whereType<Permission>()
              .toList() ??
          [];
      _selectedPermissions = Set<int>.from(rolePermissions.map((p) => p.id));
    }

    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      final permissions = await _permissionService.getAllPermissions();
      setState(() {
        _availablePermissions = permissions;
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

  Future<void> _saveRole() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);

    try {
      Role savedRole;

      if (widget.role == null) {
        // Crear nuevo rol
        savedRole = await _roleService.createRole({
          'name': _name,
          'description': _description,
        });
      } else {
        // Actualizar rol existente
        savedRole = await _roleService.updateRole(widget.role!.id, {
          'name': _name,
          'description': _description,
        });
      }

      // Asignar permisos
      if (_selectedPermissions.isNotEmpty) {
        await _roleService.updateRolePermissions(
            savedRole.id, _selectedPermissions.toList());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.role == null
                ? 'Rol "$_name" creado exitosamente'
                : 'Rol "$_name" actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildPermissionsSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final groupedPermissions = <String, List<Permission>>{};

    for (final permission in _availablePermissions) {
      final category = PermissionService.getPermissionCategory(permission.name);
      groupedPermissions.putIfAbsent(category, () => []).add(permission);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Permisos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...groupedPermissions.entries.map((entry) {
          return Card(
            child: ExpansionTile(
              title: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('${entry.value.length} permisos disponibles'),
              children: entry.value.map((permission) {
                return CheckboxListTile(
                  title: Text(PermissionService.getPermissionDisplayName(
                      permission.name)),
                  subtitle: Text(
                    PermissionService.getPermissionDescription(permission.name),
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
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.role != null;
    final isSystemRole = isEditing &&
        ['super_admin', 'manager', 'dt', 'team_captain', 'player', 'guest']
            .contains(widget.role!.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Rol' : 'Crear Rol'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isSystemRole)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Este es un rol del sistema. Solo se pueden modificar los permisos.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isSystemRole) const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Rol',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.group),
                      ),
                      enabled: !isSystemRole,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El nombre del rol es requerido';
                        }
                        if (value.contains(' ')) {
                          return 'El nombre no puede contener espacios';
                        }
                        return null;
                      },
                      onSaved: (value) => _name = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _description,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value!.isEmpty ? 'La descripción es requerida' : null,
                      onSaved: (value) => _description = value!,
                    ),
                    const SizedBox(height: 24),
                    _buildPermissionsSection(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _saveRole,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSubmitting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Guardando...'),
                                ],
                              )
                            : Text(isEditing ? 'Actualizar Rol' : 'Crear Rol'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
