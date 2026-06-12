class Team {
  final int id;
  final String name;
  final String? description;
  final String? sport;
  final String? category;
  final List<String> categoryNames;
  final List<int> categoryIds;
  final int? sportId;
  final int? categoryId;
  final String? colors;
  final String? logoUrl;
  final int? foundedYear;
  final int birthdayNotificationHour;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> adminEmails;

  Team({
    required this.id,
    required this.name,
    this.description,
    this.sport,
    this.category,
    this.categoryNames = const [],
    this.categoryIds = const [],
    this.sportId,
    this.categoryId,
    this.colors,
    this.logoUrl,
    this.foundedYear,
    this.birthdayNotificationHour = 9,
    required this.createdAt,
    required this.updatedAt,
    this.adminEmails = const [],
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    final categoriesList = json['categories'] as List<dynamic>?;
    final namesFromApi = (json['categoryNames'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (categoriesList
                ?.map((c) => c is Map ? c['name']?.toString() : c.toString())
                .whereType<String>()
                .toList() ??
            []);
    final idsFromApi = (json['categoryIds'] as List<dynamic>?)
            ?.map((e) => e is int ? e : int.tryParse(e.toString()))
            .whereType<int>()
            .toList() ??
        (categoriesList
                ?.map((c) => c is Map ? c['id'] as int? : null)
                .whereType<int>()
                .toList() ??
            []);

    return Team(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      sport:
          json['sport']?['name'] ?? json['sport'], // Puede ser objeto o string
      category: namesFromApi.isNotEmpty
          ? namesFromApi.join(', ')
          : (json['category']?['name'] ?? json['category']?.toString()),
      categoryNames: namesFromApi,
      categoryIds: idsFromApi,
      sportId: json['sportId'] ?? json['sport_id'] ?? json['sport']?['id'],
      categoryId: idsFromApi.isNotEmpty
          ? idsFromApi.first
          : (json['categoryId'] ??
              json['category_id'] ??
              json['category']?['id']),
      colors: json['colors'],
      logoUrl: json['logoUrl']?.toString() ?? json['logo_url']?.toString(),
      foundedYear: json['foundedYear'] ?? json['founded_year'],
      birthdayNotificationHour:
          ((json['birthdayNotificationHour'] ??
                      json['birthday_notification_hour']) as num?)
                  ?.toInt() ??
              9,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
      adminEmails: (json['adminEmails'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sport': sport,
      'category': category,
      'sportId': sportId,
      'categoryId': categoryId,
      'colors': colors,
      'logoUrl': logoUrl,
      'foundedYear': foundedYear,
      'birthdayNotificationHour': birthdayNotificationHour,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Para crear un equipo nuevo (sin ID)
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'description': description,
      'sportId': sportId,
      'categoryId': categoryId,
      'colors': colors,
      'logoUrl': logoUrl,
      'foundedYear': foundedYear,
    };
  }

  // Para actualizar un equipo (solo campos modificables)
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'description': description,
      'sportId': sportId,
      'categoryId': categoryId,
      'colors': colors,
      'logoUrl': logoUrl,
      'foundedYear': foundedYear,
    };
  }

  // Helpers para UI
  String get displayName => name;

  /// Si hay varios equipos con el mismo nombre, incluye el id (ej. ZFC (#2)).
  static String listLabel(Team team, Iterable<Team> all) {
    final dup = all
            .where(
              (t) => t.name.toLowerCase() == team.name.toLowerCase(),
            )
            .length >
        1;
    if (dup) return '${team.name} (#${team.id})';
    return team.name;
  }

  String get fullName {
    final parts = <String>[name];
    if (category != null) parts.add(category!);
    if (sport != null) parts.add(sport!);
    return parts.join(' - ');
  }

  String get sportName => sport ?? 'Sin deporte';
  String get categoryName =>
      categoryNames.isNotEmpty
          ? categoryNames.join(', ')
          : (category ?? 'Sin categoría');

  String get shortInfo {
    final parts = <String>[];
    if (sport != null) parts.add(sport!);
    if (category != null) parts.add(category!);
    return parts.join(' • ');
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Team && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Método para copiar con cambios
  Team copyWith({
    int? id,
    String? name,
    String? description,
    String? sport,
    String? category,
    int? sportId,
    int? categoryId,
    String? colors,
    String? logoUrl,
    int? foundedYear,
    int? birthdayNotificationHour,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sport: sport ?? this.sport,
      category: category ?? this.category,
      sportId: sportId ?? this.sportId,
      categoryId: categoryId ?? this.categoryId,
      colors: colors ?? this.colors,
      logoUrl: logoUrl ?? this.logoUrl,
      foundedYear: foundedYear ?? this.foundedYear,
      birthdayNotificationHour:
          birthdayNotificationHour ?? this.birthdayNotificationHour,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
