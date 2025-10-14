import 'package:sportify_amateur/models/permission.dart';

class RolePermission {
  final int roleId;
  final int permissionId;
  final Permission? permission;

  RolePermission({
    required this.roleId,
    required this.permissionId,
    this.permission,
  });

  factory RolePermission.fromJson(Map<String, dynamic> json) {
    return RolePermission(
      roleId: json['roleId'],
      permissionId: json['permissionId'],
      permission: json['permission'] != null
          ? Permission.fromJson(json['permission'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Role {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RolePermission>? rolePermissions;

  Role({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.rolePermissions,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      rolePermissions: json['rolePermissions'] != null
          ? (json['rolePermissions'] as List)
              .map((rp) => RolePermission.fromJson(rp as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'rolePermissions': rolePermissions
          ?.map((rp) => {
                'roleId': rp.roleId,
                'permissionId': rp.permissionId,
                'permission': rp.permission?.toJson(),
              })
          .toList(),
    };
  }

  @override
  String toString() {
    return 'Role{id: $id, name: $name, description: $description}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Role && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
