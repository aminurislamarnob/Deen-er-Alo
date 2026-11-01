import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../prayer_times/domain/prayer_model.dart';

class PrayerTrackerNotifier extends StateNotifier<Map<PrayerType, bool>> {
  static const String _prefPrefix = 'pref_prayer_tracked_';

  PrayerTrackerNotifier()
      : super({
          PrayerType.fajr: false,
          PrayerType.dhuhr: false,
          PrayerType.asr: false,
          PrayerType.maghrib: false,
          PrayerType.isha: false,
        }) {
    _loadTodayTracker();
  }

  String _getTodayKey(PrayerType type) {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month}-${now.day}';
    return '$_prefPrefix${dateStr}_${type.name}';
  }

  Future<void> _loadTodayTracker() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<PrayerType, bool> map = {};
    for (final type in PrayerType.values) {
      if (type == PrayerType.sunrise) continue;
      map[type] = prefs.getBool(_getTodayKey(type)) ?? false;
    }
    state = map;
  }

  Future<void> togglePrayer(PrayerType type) async {
    final current = state[type] ?? false;
    final updated = !current;
    state = {
      ...state,
      type: updated,
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_getTodayKey(type), updated);
  }
}

final prayerTrackerProvider =
    StateNotifierProvider<PrayerTrackerNotifier, Map<PrayerType, bool>>((ref) {
  return PrayerTrackerNotifier();
});

