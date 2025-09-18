import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/role_service.dart';
import 'package:sportify_amateur/models/role.dart';

class RoleFormScreen extends StatefulWidget {
  final Role? role;

  const RoleFormScreen({super.key, this.role});

  @override
  State<RoleFormScreen> createState() => _RoleFormScreenState();
}

class _RoleFormScreenState extends State<RoleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;

  final RoleService _roleService = RoleService();

  @override
  void initState() {
    super.initState();
    _name = widget.role?.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.role == null ? 'Create Role' : 'Edit Role'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Role Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Role name is required' : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final role = Role(
                      id: widget.role?.id ?? 0,
                      name: _name,
                      permissions: [], // Actualizar según permisos
                    );
                    if (widget.role == null) {
                      await _roleService.createRole(role);
                    } else {
                      // Editar rol si fuera necesario
                    }
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
