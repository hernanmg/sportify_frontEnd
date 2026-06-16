import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_amateur/core/services/roster_service.dart';

/// Temporada activa compartida entre plantel, finanzas y eventos.
class SeasonProvider extends ChangeNotifier {
  static const _prefKey = 'active_season';

  String _season = RosterService.getCurrentSeason();

  String get season => _season;

  List<String> get availableSeasons => RosterService.getSeasons();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    final options = availableSeasons;
    if (saved != null && options.contains(saved)) {
      _season = saved;
      notifyListeners();
    } else if (saved != null && saved.isNotEmpty) {
      final normalized = RosterService.normalizeSeason(saved);
      if (options.contains(normalized)) {
        _season = normalized;
        notifyListeners();
      }
    }
  }

  Future<void> setSeason(String value) async {
    if (_season == value) return;
    _season = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, value);
  }
}
