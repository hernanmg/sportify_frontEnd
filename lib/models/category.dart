class Category {
  final int id;
  final String name;
  final String? description;
  final int sportId;
  final int? ageMin;
  final int? ageMax;
  final String? gender;
  final bool isActive;
  final int sortOrder;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.sportId,
    this.ageMin,
    this.ageMax,
    this.gender,
    required this.isActive,
    required this.sortOrder,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      sportId: json['sportId'],
      ageMin: json['ageMin'],
      ageMax: json['ageMax'],
      gender: json['gender'],
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sportId': sportId,
      'ageMin': ageMin,
      'ageMax': ageMax,
      'gender': gender,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }

  String get displayName {
    String display = name;
    if (ageMin != null) {
      display += ' (${ageMin}+ años)';
    } else if (ageMax != null) {
      display += ' (hasta $ageMax años)';
    }
    if (gender != null && gender != 'mixto') {
      display += ' - ${gender?.toUpperCase()}';
    }
    return display;
  }
}
