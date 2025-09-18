class Team {
  final int id;
  final String name;
  final int sportId;
  final int? categoryId;
  final String? description;
  final int? foundedYear;
  final String? colors;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Team({
    required this.id,
    required this.name,
    required this.sportId,
    this.categoryId,
    this.description,
    this.foundedYear,
    this.colors,
    this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      sportId: json['sport_id'] ?? json['sportId'],
      categoryId: json['category_id'] ?? json['categoryId'],
      description: json['description'],
      foundedYear: json['founded_year'] ?? json['foundedYear'],
      colors: json['colors'],
      logoUrl: json['logo_url'] ?? json['logoUrl'],
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sport_id': sportId,
      'category_id': categoryId,
      'description': description,
      'founded_year': foundedYear,
      'colors': colors,
      'logo_url': logoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayName {
    if (foundedYear != null) {
      return '$name ($foundedYear)';
    }
    return name;
  }

  String get shortInfo {
    List<String> info = [];
    if (colors != null && colors!.isNotEmpty) {
      info.add('Colores: $colors');
    }
    if (foundedYear != null) {
      info.add('Fundado: $foundedYear');
    }
    return info.join(' • ');
  }
}
