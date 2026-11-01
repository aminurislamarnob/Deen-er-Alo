import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../calendar/domain/hijri_utils.dart';
import '../../prayer_times/domain/prayer_model.dart';
import '../domain/habit_models.dart';

class HabitRepository {
  static const String _keyPrefix = 'deener_alo_habit_';
  static const String _qazaKey = 'deener_alo_qaza_balance';

  /// Legacy keys written by the old home-screen prayer tracker:
  /// `pref_prayer_tracked_YYYY-M-D_<type>` (bool).
  static const String legacyPrayerPrefix = 'pref_prayer_tracked_';

  /// Upper bound for the streak walk (10 years). The walk stops at the first
  /// incomplete day, so the cost is proportional to the streak itself.
  static const int maxStreakLookbackDays = 3650;

  static String dateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static String legacyPrayerKey(DateTime dt, String typeName) =>
      '$legacyPrayerPrefix${dt.year}-${dt.month}-${dt.day}_$typeName';

  /// Parses a stored record; returns null when missing or corrupted.
  DailyHabitRecord? _tryParse(String? raw) {
    if (raw == null) return null;
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      return DailyHabitRecord.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<DailyHabitRecord> getRecord(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = dateKey(date);
    final record =
        _tryParse(prefs.getString('$_keyPrefix$dateStr')) ??
        DailyHabitRecord.empty(dateStr);
    return _migrateLegacyPrayerKeys(prefs, date, record);
  }

  /// One-time import of the old home tracker's booleans into the habit record.
  /// The legacy keys are removed afterwards so this only ever runs once.
  Future<DailyHabitRecord> _migrateLegacyPrayerKeys(
    SharedPreferences prefs,
    DateTime date,
    DailyHabitRecord record,
  ) async {
    final prayers = Map<PrayerType, PrayerStatus>.from(record.prayers);
    final foundKeys = <String>[];
    for (final type in fardPrayerTypes) {
      final key = legacyPrayerKey(date, type.name);
      if (!prefs.containsKey(key)) continue;
      foundKeys.add(key);
      bool? prayed;
      try {
        prayed = prefs.getBool(key);
      } catch (_) {}
      if (prayed == true &&
          (prayers[type] ?? PrayerStatus.none) == PrayerStatus.none) {
        prayers[type] = PrayerStatus.alone;
      }
    }
    if (foundKeys.isEmpty) return record;

    final updated = record.copyWith(prayers: prayers);
    await saveRecord(updated);
    for (final key in foundKeys) {
      await prefs.remove(key);
    }
    return updated;
  }

  Future<void> saveRecord(DailyHabitRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(record.toJson());
    await prefs.setString('$_keyPrefix${record.dateStr}', raw);
  }

  Future<int> getQazaBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_qazaKey) ?? 0;
  }

  Future<void> setQazaBalance(int balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_qazaKey, balance < 0 ? 0 : balance);
  }

  /// Number of days with any fast logged in the [days] days ending on
  /// [endDate] (inclusive).
  Future<int> countFastingDays({
    required DateTime endDate,
    int days = 30,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final end = dateOnly(endDate);
    int count = 0;
    for (int i = 0; i < days; i++) {
      final rec = _tryParse(
        prefs.getString('$_keyPrefix${dateKey(addDays(end, -i))}'),
      );
      if (rec != null && rec.fasting != FastingStatus.notFasting) count++;
    }
    return count;
  }

  /// Streak = consecutive days on which all five fard prayers were performed
  /// (jama'at, alone or made up as qaza). Today only adds to the streak once it
  /// is complete; an incomplete (or unreadable) today never breaks it.
  Future<HabitStreakSummary> getStreakSummary({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = dateOnly(now ?? DateTime.now());

    DailyHabitRecord? recordAt(int daysAgo) => _tryParse(
      prefs.getString('$_keyPrefix${dateKey(addDays(today, -daysAgo))}'),
    );

    // 1. Continuous streak backward from today.
    int streakDays = 0;
    for (int i = 0; i < maxStreakLookbackDays; i++) {
      final complete = recordAt(i)?.isAllFardPrayed ?? false;
      if (complete) {
        streakDays++;
      } else if (i == 0) {
        continue; // Today is still in progress (or unreadable): skip it.
      } else {
        break;
      }
    }

    // 2. Weekly calculations (last 7 days).
    int weeklyPrayersOffered = 0;
    int weeklyJamaatCount = 0;
    for (int i = 0; i < 7; i++) {
      final rec = recordAt(i);
      if (rec == null) continue;
      weeklyPrayersOffered += rec.prayedCount;
      weeklyJamaatCount += rec.prayers.values
          .where((s) => s == PrayerStatus.jamaat)
          .length;
    }

    // 3. Fasting count (last 30 days).
    int monthlyFastingDays = 0;
    for (int i = 0; i < 30; i++) {
      final rec = recordAt(i);
      if (rec != null && rec.fasting != FastingStatus.notFasting) {
        monthlyFastingDays++;
      }
    }

    final qazaBalance = prefs.getInt(_qazaKey) ?? 0;

    return HabitStreakSummary(
      streakDays: streakDays,
      weeklyPrayersOffered: weeklyPrayersOffered,
      weeklyJamaatCount: weeklyJamaatCount,
      monthlyFastingDays: monthlyFastingDays,
      qazaBalance: qazaBalance,
    );
  }
}
