import 'package:shared_preferences/shared_preferences.dart';

/// Flags locales de tours y guías (se borran al desinstalar la app).
class OnboardingFlagsService {
  OnboardingFlagsService._();
  static final OnboardingFlagsService instance = OnboardingFlagsService._();

  String _dtTourKey(String userId) => 'dt_guided_tour_v1_$userId';

  Future<bool> hasCompletedDtTour(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dtTourKey(userId)) ?? false;
  }

  Future<void> setDtTourCompleted(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dtTourKey(userId), true);
  }
}
