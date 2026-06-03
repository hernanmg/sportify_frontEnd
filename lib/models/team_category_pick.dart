import 'package:sportify_amateur/models/my_team_option.dart';

/// Equipo + categoría para convocatorias (un partido es por una categoría).
class TeamCategoryPick {
  final MyTeamOption team;
  final int? categoryId;
  final String? categoryName;

  const TeamCategoryPick({
    required this.team,
    this.categoryId,
    this.categoryName,
  });

  int get teamId => team.teamId;

  String get label {
    if (categoryName != null && categoryName!.trim().isNotEmpty) {
      return '${team.name} ($categoryName)';
    }
    return team.name;
  }

  /// Una opción por categoría del equipo (todas las categorías habilitadas).
  static List<TeamCategoryPick> fromMyTeams(List<MyTeamOption> teams) {
    final picks = <TeamCategoryPick>[];
    for (final t in teams) {
      final names = t.categories;
      final ids = t.categoryIds;
      if (names.isEmpty) {
        picks.add(TeamCategoryPick(team: t));
        continue;
      }
      for (var i = 0; i < names.length; i++) {
        picks.add(
          TeamCategoryPick(
            team: t,
            categoryId: i < ids.length ? ids[i] : null,
            categoryName: names[i],
          ),
        );
      }
    }
    return picks;
  }

  static TeamCategoryPick? findForTeam(
    List<TeamCategoryPick> picks,
    int teamId, {
    int? categoryId,
  }) {
    for (final p in picks) {
      if (p.teamId != teamId) continue;
      if (categoryId == null) return p;
      if (p.categoryId == categoryId) return p;
    }
    if (categoryId == null) {
      for (final p in picks) {
        if (p.teamId == teamId) return p;
      }
    }
    return null;
  }
}
