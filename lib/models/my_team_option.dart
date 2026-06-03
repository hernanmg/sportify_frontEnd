import 'package:flutter/foundation.dart';
import 'package:sportify_amateur/models/team.dart';

class MyTeamOption {
  final int teamId;
  final String name;
  final List<String> categories;
  final List<int> categoryIds;
  final bool isTeamAdmin;
  final Team team;

  MyTeamOption({
    required this.teamId,
    required this.name,
    required this.categories,
    this.categoryIds = const [],
    this.isTeamAdmin = false,
    required this.team,
  });

  String get displayLabel {
    if (categories.isEmpty) return name;
    if (categories.length == 1) return '$name (${categories.first})';
    return '$name (${categories.join(', ')})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyTeamOption &&
          other.teamId == teamId &&
          listEquals(other.categoryIds, categoryIds);

  @override
  int get hashCode => Object.hash(teamId, Object.hashAll(categoryIds));

  /// Una fila por categoría (ej. ZFC +40 y ZFC +35 por separado).
  static List<MyTeamOption> expandByCategory(List<MyTeamOption> list) {
    final out = <MyTeamOption>[];
    for (final t in list) {
      if (t.categoryIds.length <= 1) {
        out.add(t);
        continue;
      }
      for (var i = 0; i < t.categoryIds.length; i++) {
        final id = t.categoryIds[i];
        final name = i < t.categories.length
            ? t.categories[i]
            : 'Categoría $id';
        out.add(MyTeamOption(
          teamId: t.teamId,
          name: t.name,
          categories: [name],
          categoryIds: [id],
          isTeamAdmin: t.isTeamAdmin,
          team: t.team,
        ));
      }
    }
    return out;
  }

  /// Un equipo por `teamId` (evita ítems duplicados en dropdowns).
  static List<MyTeamOption> dedupeByTeamId(List<MyTeamOption> list) {
    final byId = <int, MyTeamOption>{};
    for (final t in list) {
      byId.putIfAbsent(t.teamId, () => t);
    }
    return byId.values.toList();
  }

  static MyTeamOption? findInList(List<MyTeamOption> list, int teamId) {
    for (final t in list) {
      if (t.teamId == teamId) return t;
    }
    return null;
  }

  factory MyTeamOption.fromJson(Map<String, dynamic> json) {
    final teamJson = json['team'] as Map<String, dynamic>? ?? json;
    final team = Team.fromJson(Map<String, dynamic>.from(teamJson));
    final cats = (json['categories'] as List<dynamic>?)
            ?.map((c) => c.toString())
            .toList() ??
        team.categoryNames;
    final catIds = (json['categoryIds'] as List<dynamic>?)
            ?.map((c) => c is int ? c : int.tryParse(c.toString()) ?? 0)
            .where((id) => id > 0)
            .toList() ??
        team.categoryIds;
    return MyTeamOption(
      teamId: json['teamId'] as int? ?? teamJson['id'] as int,
      name: json['name'] as String? ?? teamJson['name'] as String? ?? '',
      categories: cats,
      categoryIds: catIds,
      isTeamAdmin: json['isTeamAdmin'] == true,
      team: team,
    );
  }
}
