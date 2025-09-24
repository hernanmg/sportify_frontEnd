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
  late String _description;

  final RoleService _roleService = RoleService();

  @override
  void initState() {
    super.initState();
    _name = widget.role?.name ?? '';
    _description = widget.role?.description ?? '';
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
                decoration: const InputDecoration(labelText: 'Nombre del Rol'),
                validator: (value) =>
                    value!.isEmpty ? 'El nombre del rol es requerido' : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) =>
                    value!.isEmpty ? 'La descripción es requerida' : null,
                onSaved: (value) => _description = value!,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    try {
                      // Por ahora solo mostrar mensaje ya que no tenemos endpoint de creación
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(widget.role == null
                              ? 'Función de crear rol no implementada aún'
                              : 'Función de editar rol no implementada aún'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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
