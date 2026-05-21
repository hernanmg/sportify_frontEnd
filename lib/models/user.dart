import 'package:sportify_amateur/models/role.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String? username;
  final List<Role> roles;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    required this.roles,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? json['username'] ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username'],
      roles: json['userRoles'] != null
          ? (json['userRoles'] as List)
              .map((userRole) => Role.fromJson(userRole['role']))
              .toList()
          : [],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'roles': roles.map((role) => role.toJson()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get displayName => name.isNotEmpty ? name : (username ?? email);

  bool hasRole(String roleName) {
    return roles.any((role) => role.name == roleName);
  }

  bool hasAnyRole(List<String> roleNames) {
    return roles.any((role) => roleNames.contains(role.name));
  }
}
