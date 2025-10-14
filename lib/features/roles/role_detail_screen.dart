import 'package:flutter/material.dart';
import 'package:sportify_amateur/models/role.dart';
import 'package:sportify_amateur/core/services/role_service.dart';
import 'package:sportify_amateur/core/services/permission_service.dart';
import 'package:sportify_amateur/features/roles/role_form_screen.dart';

class RoleDetailScreen extends StatefulWidget {
  final int roleId;

  const RoleDetailScreen({super.key, required this.roleId});

  @override
  State<RoleDetailScreen> createState() => _RoleDetailScreenState();
}

class _RoleDetailScreenState extends State<RoleDetailScreen> {
  late Future<Role> futureRole;
  final RoleService _roleService = RoleService();

  @override
  void initState() {
    super.initState();
    futureRole = _roleService.fetchRoleWithPermissions(widget.roleId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle del Rol"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              try {
                final role = await futureRole;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RoleFormScreen(role: role),
                  ),
                );
                if (result == true) {
                  // Recargar los datos si se editó el rol
                  setState(() {
                    futureRole =
                        _roleService.fetchRoleWithPermissions(widget.roleId);
                  });
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al cargar rol para editar: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Role>(
        future: futureRole,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar el rol',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        futureRole = _roleService
                            .fetchRoleWithPermissions(widget.roleId);
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final role = snapshot.data!;
            final permissions =
                role.rolePermissions?.map((rp) => rp.permission!).toList() ??
                    [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header del rol
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.purple.withOpacity(0.1),
                            child: Icon(
                              RoleService.getRoleIcon(role.name),
                              size: 40,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  RoleService.getRoleDisplayName(role.name),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  role.description ??
                                      RoleService.getRoleDescription(role.name),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${permissions.length} permisos asignados',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.purple[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Información del sistema
                  const Text(
                    'Información del Sistema',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow('ID del Rol:', role.id.toString()),
                          _buildInfoRow('Nombre técnico:', role.name),
                          _buildInfoRow('Creado:', _formatDate(role.createdAt)),
                          _buildInfoRow(
                              'Actualizado:', _formatDate(role.updatedAt)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Permisos asignados
                  Text(
                    'Permisos Asignados (${permissions.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (permissions.isEmpty)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.security_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Sin permisos asignados',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Este rol no tiene permisos específicos asignados.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    _buildPermissionsSection(permissions),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No se encontraron datos'));
          }
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildPermissionsSection(List permissions) {
    // Agrupar permisos por categoría
    final Map<String, List> groupedPermissions = {};
    for (var permission in permissions) {
      final category = PermissionService.getPermissionCategory(permission.name);
      if (!groupedPermissions.containsKey(category)) {
        groupedPermissions[category] = [];
      }
      groupedPermissions[category]!.add(permission);
    }

    return Column(
      children: groupedPermissions.entries.map((entry) {
        final category = entry.key;
        final categoryPermissions = entry.value;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              category,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              '${categoryPermissions.length} permisos',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            leading: Icon(
              PermissionService.getPermissionIcon(
                  categoryPermissions.first.name),
              color: Colors.purple,
            ),
            children: categoryPermissions.map<Widget>((permission) {
              return ListTile(
                dense: true,
                leading: Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 20,
                ),
                title: Text(
                  PermissionService.getPermissionDisplayName(permission.name),
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: permission.description != null
                    ? Text(
                        permission.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      )
                    : null,
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
