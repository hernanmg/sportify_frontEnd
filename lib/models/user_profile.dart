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
  final String? googleId;
  final String? facebookId;
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
    this.googleId,
    this.facebookId,
    this.ultimoLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return UserProfile(
      id: json['id'] as int? ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      phone: json['phone']?.toString(),
      fechaNacimiento: parseDate(json['fechaNacimiento']),
      ciudad: json['ciudad']?.toString(),
      provincia: json['provincia']?.toString(),
      pais: json['pais']?.toString(),
      bio: json['bio']?.toString(),
      experienciaDeportiva: json['experienciaDeportiva']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      profileCompletion: (json['profileCompletion'] as num?)?.toInt() ?? 0,
      estadoRegistro: json['estadoRegistro']?.toString() ?? 'pending',
      emailVerified: json['emailVerified'] == true,
      phoneVerified: json['phoneVerified'] == true,
      isActive: json['isActive'] != false,
      googleId: json['googleId']?.toString(),
      facebookId: json['facebookId']?.toString(),
      ultimoLogin: parseDate(json['ultimoLogin']),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(json['updatedAt']) ?? DateTime.now(),
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
      'googleId': googleId,
      'facebookId': facebookId,
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
