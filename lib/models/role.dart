import 'package:sportify_amateur/models/permission.dart';

class Role {
  final int id;
  final String name;
  final List<Permission> permissions;

  Role({
    required this.id,
    required this.name,
    required this.permissions,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
      permissions: (json['permissions'] as List)
          .map((perm) => Permission.fromJson(perm))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'permissions': permissions.map((perm) => perm.toJson()).toList(),
    };
  }
}
