import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/habit_models.dart';

class HabitRepository {
  static const String _keyPrefix = 'deener_alo_habit_';
  static const String _qazaKey = 'deener_alo_qaza_balance';

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<DailyHabitRecord> getRecord(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = _formatDate(date);
    final raw = prefs.getString('$_keyPrefix$dateStr');
    if (raw == null) {
      return DailyHabitRecord.empty(dateStr);
    }
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      return DailyHabitRecord.fromJson(map);
    } catch (_) {
      return DailyHabitRecord.empty(dateStr);
    }
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

  Future<HabitStreakSummary> getStreakSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // 1. Calculate continuous streak backward from today / yesterday
    int streakDays = 0;
    for (int i = 0; i < 60; i++) {
      final d = now.subtract(Duration(days: i));
      final dateStr = _formatDate(d);
      final raw = prefs.getString('$_keyPrefix$dateStr');
      if (raw != null) {
        try {
          final map = json.decode(raw) as Map<String, dynamic>;
          final rec = DailyHabitRecord.fromJson(map);
          // If at least 1 prayer or fasting was logged
          if (rec.completedPrayerCount > 0 ||
              rec.fasting != FastingStatus.notFasting) {
            streakDays++;
          } else if (i > 0) {
            // Gap broke the streak
            break;
          }
        } catch (_) {
          break;
        }
      } else if (i > 0) {
        break;
      }
    }

    // 2. Weekly calculations (last 7 days)
    int weeklyPrayersOffered = 0;
    int weeklyJamaatCount = 0;

    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      final dateStr = _formatDate(d);
      final raw = prefs.getString('$_keyPrefix$dateStr');
      if (raw != null) {
        try {
          final map = json.decode(raw) as Map<String, dynamic>;
          final rec = DailyHabitRecord.fromJson(map);
          weeklyPrayersOffered += rec.completedPrayerCount;
          weeklyJamaatCount += rec.prayers.values
              .where((s) => s == PrayerStatus.jamaat)
              .length;
        } catch (_) {}
      }
    }

    // 3. Monthly Fasting count (last 30 days)
    int monthlyFastingDays = 0;
    for (int i = 0; i < 30; i++) {
      final d = now.subtract(Duration(days: i));
      final dateStr = _formatDate(d);
      final raw = prefs.getString('$_keyPrefix$dateStr');
      if (raw != null) {
        try {
          final map = json.decode(raw) as Map<String, dynamic>;
          final rec = DailyHabitRecord.fromJson(map);
          if (rec.fasting != FastingStatus.notFasting) {
            monthlyFastingDays++;
          }
        } catch (_) {}
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
