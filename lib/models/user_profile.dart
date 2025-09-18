class UserProfile {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final DateTime? fechaNacimiento;
  final String? ciudad;
  final String? provincia;
  final String? pais;
  final String? bio;
  final String? experienciaDeportiva;
  final String? avatarUrl;
  final int profileCompletion;
  final String estadoRegistro;
  final bool emailVerified;
  final bool phoneVerified;
  final bool isActive;
  final DateTime? ultimoLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.fechaNacimiento,
    this.ciudad,
    this.provincia,
    this.pais,
    this.bio,
    this.experienciaDeportiva,
    this.avatarUrl,
    required this.profileCompletion,
    required this.estadoRegistro,
    required this.emailVerified,
    required this.phoneVerified,
    required this.isActive,
    this.ultimoLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      fechaNacimiento: json['fechaNacimiento'] != null
          ? DateTime.parse(json['fechaNacimiento'])
          : null,
      ciudad: json['ciudad'],
      provincia: json['provincia'],
      pais: json['pais'],
      bio: json['bio'],
      experienciaDeportiva: json['experienciaDeportiva'],
      avatarUrl: json['avatarUrl'],
      profileCompletion: json['profileCompletion'] ?? 0,
      estadoRegistro: json['estadoRegistro'] ?? 'pending',
      emailVerified: json['emailVerified'] ?? false,
      phoneVerified: json['phoneVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      ultimoLogin: json['ultimoLogin'] != null
          ? DateTime.parse(json['ultimoLogin'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'fechaNacimiento': fechaNacimiento?.toIso8601String(),
      'ciudad': ciudad,
      'provincia': provincia,
      'pais': pais,
      'bio': bio,
      'experienciaDeportiva': experienciaDeportiva,
      'avatarUrl': avatarUrl,
      'profileCompletion': profileCompletion,
      'estadoRegistro': estadoRegistro,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'isActive': isActive,
      'ultimoLogin': ultimoLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return username;
  }

  String get displayLocation {
    if (ciudad != null && provincia != null) {
      return '$ciudad, $provincia';
    } else if (ciudad != null) {
      return ciudad!;
    } else if (provincia != null) {
      return provincia!;
    }
    return 'Ubicación no especificada';
  }

  int get age {
    if (fechaNacimiento == null) return 0;
    final now = DateTime.now();
    int age = now.year - fechaNacimiento!.year;
    if (now.month < fechaNacimiento!.month ||
        (now.month == fechaNacimiento!.month &&
            now.day < fechaNacimiento!.day)) {
      age--;
    }
    return age;
  }

  bool get isProfileIncomplete => profileCompletion < 80;
}
