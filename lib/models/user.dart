import 'package:sportify_amateur/models/role.dart';

class User {
  final int id;
  final String name;
  final String email;
  final List<Role> roles;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      roles: (json['roles'] as List).map((role) => Role.fromJson(role)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'roles': roles.map((role) => role.toJson()).toList(),
    };
  }
}
