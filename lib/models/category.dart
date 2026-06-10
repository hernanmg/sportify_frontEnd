import 'package:sportify_amateur/core/utils/category_label.dart';

class Category {
  final int id;
  final String name;
  final String? description;
  final int sportId;
  final String? sportName;
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
    this.sportName,
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
      sportName: json['sport'] is Map ? json['sport']['name'] : null,
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
    final short = CategoryLabels.short(name);
    if (short.isNotEmpty) return short;
    return name;
  }
}
