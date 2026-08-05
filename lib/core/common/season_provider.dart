import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_amateur/core/services/roster_service.dart';

/// Temporada activa compartida entre plantel, finanzas y eventos.
class SeasonProvider extends ChangeNotifier {
  static const _prefKey = 'active_season';
  static const _datesPrefix = 'season_dates_';

  String _season = RosterService.getCurrentSeason();
  DateTime? _startDate;
  DateTime? _endDate;

  String get season => _season;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  List<String> get availableSeasons => RosterService.getSeasons();

  bool get hasDateRange => _startDate != null && _endDate != null;

  /// True si hay fecha de fin y ya pasó (incluye el día siguiente).
  bool get isSeasonEnded {
    if (_endDate == null) return false;
    final today = DateTime.now();
    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    final now = DateTime(today.year, today.month, today.day);
    return now.isAfter(end);
  }

  /// True si estamos en el rango o sin fechas configuradas.
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
    await _loadDatesFor(_season);
    notifyListeners();
  }

  Future<void> setSeason(String value) async {
    if (_season == value) return;
    _season = value;
    await _loadDatesFor(value);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, value);
  }

  Future<void> setSeasonDates({
    DateTime? start,
    DateTime? end,
  }) async {
    _startDate = start;
    _endDate = end;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final key = '$_datesPrefix$_season';
    if (start == null && end == null) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(
      key,
      '${start?.toIso8601String() ?? ''}|${end?.toIso8601String() ?? ''}',
    );
  }

  Future<void> _loadDatesFor(String season) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_datesPrefix$season');
    if (raw == null || raw.isEmpty) {
      _startDate = null;
      _endDate = null;
      return;
    }
    final parts = raw.split('|');
    _startDate = parts.isNotEmpty && parts[0].isNotEmpty
        ? DateTime.tryParse(parts[0])
        : null;
    _endDate = parts.length > 1 && parts[1].isNotEmpty
        ? DateTime.tryParse(parts[1])
        : null;
  }
}
