class Team {
  final int id;
  final String name;
  final String? description;
  final String? sport;
  final String? category;
  final int? sportId;
  final int? categoryId;
  final String? colors;
  final int? foundedYear;
  final DateTime createdAt;
  final DateTime updatedAt;

  Team({
    required this.id,
    required this.name,
    this.description,
    this.sport,
    this.category,
    this.sportId,
    this.categoryId,
    this.colors,
    this.foundedYear,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      sport:
          json['sport']?['name'] ?? json['sport'], // Puede ser objeto o string
      category: json['category']?['name'] ??
          json['category'], // Puede ser objeto o string
      sportId: json['sportId'] ?? json['sport_id'] ?? json['sport']?['id'],
      categoryId:
          json['categoryId'] ?? json['category_id'] ?? json['category']?['id'],
      colors: json['colors'],
      foundedYear: json['foundedYear'] ?? json['founded_year'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
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
      'foundedYear': foundedYear,
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
      'foundedYear': foundedYear,
    };
  }

  // Helpers para UI
  String get displayName => name;

  String get fullName {
    final parts = <String>[name];
    if (category != null) parts.add(category!);
    if (sport != null) parts.add(sport!);
    return parts.join(' - ');
  }

  String get sportName => sport ?? 'Sin deporte';
  String get categoryName => category ?? 'Sin categoría';

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
    int? foundedYear,
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
      foundedYear: foundedYear ?? this.foundedYear,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
