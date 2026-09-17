import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_amateur/core/services/roster_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';

/// Temporada activa compartida entre plantel, finanzas y eventos.
/// Las fechas desde/hasta se sincronizan con el servidor por equipo.
class SeasonProvider extends ChangeNotifier {
  static const _prefKey = 'active_season';

  final TeamService _teamService = TeamService();

  String _season = RosterService.getCurrentSeason();
  DateTime? _startDate;
  DateTime? _endDate;
  int? _teamId;

  String get season => _season;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int? get teamId => _teamId;

  List<String> get availableSeasons => RosterService.getSeasons();

  bool get hasDateRange => _startDate != null && _endDate != null;

  /// True si hay fecha de fin y ya pasó.
  bool get isSeasonEnded {
    if (_endDate == null) return false;
    final today = DateTime.now();
    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    final now = DateTime(today.year, today.month, today.day);
    return now.isAfter(end);
  }

  bool get isSeasonActive {
    if (!hasDateRange) return true;
    final today = DateTime.now();
    final now = DateTime(today.year, today.month, today.day);
    final start =
        DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    return !now.isBefore(start) && !now.isAfter(end);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    final options = availableSeasons;
    if (saved != null && options.contains(saved)) {
      _season = saved;
    } else if (saved != null && saved.isNotEmpty) {
      final normalized = RosterService.normalizeSeason(saved);
      if (options.contains(normalized)) {
        _season = normalized;
      }
    }
    if (_teamId != null) {
      await loadDatesForTeam(_teamId!);
    } else {
      notifyListeners();
    }
  }

  Future<void> setSeason(String value) async {
    if (_season == value) return;
    _season = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, value);
    if (_teamId != null) {
      await loadDatesForTeam(_teamId!);
    }
  }

  /// Carga fechas del servidor para el equipo activo.
  Future<void> bindTeam(int? teamId) async {
    if (_teamId == teamId) {
      if (teamId != null) await loadDatesForTeam(teamId);
      return;
    }
    _teamId = teamId;
    if (teamId == null) {
      _startDate = null;
      _endDate = null;
      notifyListeners();
      return;
    }
    await loadDatesForTeam(teamId);
  }

  Future<void> loadDatesForTeam(int teamId) async {
    try {
      final data = await _teamService.getSeasonPeriod(
        teamId: teamId,
        season: _season,
      );
      _startDate = _parseDate(data['startDate']);
      _endDate = _parseDate(data['endDate']);
      _teamId = teamId;
    } catch (_) {
      // Sin red o sin permiso: no romper la UI.
      _startDate = null;
      _endDate = null;
    }
    notifyListeners();
  }

  Future<void> setSeasonDates({
    DateTime? start,
    DateTime? end,
  }) async {
    _startDate = start;
    _endDate = end;
    notifyListeners();

    final teamId = _teamId;
    if (teamId == null) return;

    final startIso = start == null
        ? null
        : '${start.year.toString().padLeft(4, '0')}-'
            '${start.month.toString().padLeft(2, '0')}-'
            '${start.day.toString().padLeft(2, '0')}';
    final endIso = end == null
        ? null
        : '${end.year.toString().padLeft(4, '0')}-'
            '${end.month.toString().padLeft(2, '0')}-'
            '${end.day.toString().padLeft(2, '0')}';

    await _teamService.upsertSeasonPeriod(
      teamId: teamId,
      season: _season,
      startDate: startIso,
      endDate: endIso,
    );
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}
