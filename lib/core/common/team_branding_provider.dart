import 'package:flutter/foundation.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/models/my_team_option.dart';
import 'package:sportify_amateur/models/team.dart';

/// Escudo/colores del equipo activo para cabeceras de la app.
class TeamBrandingProvider extends ChangeNotifier {
  final TeamService _teamService = TeamService();

  Team? _team;
  bool _loading = false;

  Team? get team => _team;
  String? get logoUrl => _team?.logoUrl;
  bool get hasLogo => logoUrl != null && logoUrl!.trim().isNotEmpty;

  static bool _teamHasLogo(Team team) {
    final logo = team.logoUrl;
    return logo != null && logo.trim().isNotEmpty;
  }

  static Team? _pickBrandingTeam(List<Team> primary, [List<Team>? fallback]) {
    for (final team in primary) {
      if (_teamHasLogo(team)) return team;
    }
    if (fallback != null) {
      for (final team in fallback) {
        if (_teamHasLogo(team)) return team;
      }
    }
    if (primary.isNotEmpty) return primary.first;
    if (fallback != null && fallback.isNotEmpty) return fallback.first;
    return null;
  }

  /// Actualiza al instante tras guardar escudo/colores en el formulario de equipo.
  void applyTeam(Team team) {
    if (_team?.id == team.id && _team?.logoUrl == team.logoUrl) return;
    _team = team;
    notifyListeners();
  }

  Future<void> load({bool force = false}) async {
    if (_loading && !force) return;
    _loading = true;
    try {
      final myOptions =
          MyTeamOption.dedupeByTeamId(await _teamService.getMyTeams());
      final myTeams = myOptions.map((t) => t.team).toList();

      List<Team> allTeams = const [];
      final needsFallback =
          myTeams.isEmpty || !myTeams.any(_teamHasLogo);
      if (needsFallback) {
        allTeams = await _teamService.getAllTeams();
      }

      final picked = _pickBrandingTeam(myTeams, needsFallback ? allTeams : null);
      if (_team?.id != picked?.id || _team?.logoUrl != picked?.logoUrl) {
        _team = picked;
        notifyListeners();
      }
    } catch (_) {
      // Sin sesión o sin equipos: mantener degradado por defecto.
    } finally {
      _loading = false;
    }
  }

  void clear() {
    _team = null;
    notifyListeners();
  }
}
