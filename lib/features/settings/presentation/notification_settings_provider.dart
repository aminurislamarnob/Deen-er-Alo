import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/prayer_alarm_scheduler.dart';
import '../../prayer_times/presentation/prayer_providers.dart';
import '../domain/notification_settings.dart';

final prayerAlarmSchedulerProvider = Provider<PrayerAlarmScheduler>((ref) {
  final prayerEngine = ref.watch(prayerEngineProvider);
  return PrayerAlarmScheduler(prayerEngine: prayerEngine);
});

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
        (ref) {
  return NotificationSettingsNotifier(ref);
});

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  static const _prefKey = 'deener_alo_notification_settings_v1';
  final Ref _ref;

  NotificationSettingsNotifier(this._ref)
      : super(const NotificationSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKey);
    if (jsonStr != null) {
      try {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        state = NotificationSettings.fromJson(map);
      } catch (_) {}
    }
  }

  Future<void> updateSettings(NotificationSettings newSettings) async {
    state = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, json.encode(newSettings.toJson()));

    // Trigger rescheduling if city is available
    final cityAsync = _ref.read(selectedCityProvider);
    final city = cityAsync.valueOrNull;
    if (city != null) {
      final scheduler = _ref.read(prayerAlarmSchedulerProvider);
      await scheduler.scheduleRollingAlarms(city: city, settings: newSettings);
    }
  }

  Future<void> toggleMaster(bool enabled) async {
    await updateSettings(state.copyWith(masterEnabled: enabled));
  }

  Future<void> setTone(String prayerKey, NotificationAlarmTone tone) async {
    switch (prayerKey) {
      case 'fajr':
        await updateSettings(state.copyWith(fajrTone: tone));
        break;
      case 'dhuhr':
        await updateSettings(state.copyWith(dhuhrTone: tone));
        break;
      case 'asr':
        await updateSettings(state.copyWith(asrTone: tone));
        break;
      case 'maghrib':
        await updateSettings(state.copyWith(maghribTone: tone));
        break;
      case 'isha':
        await updateSettings(state.copyWith(ishaTone: tone));
        break;
    }
  }

  Future<void> toggleTahajjud(bool val) async {
    await updateSettings(state.copyWith(tahajjudReminder: val));
  }

  Future<void> toggleDuha(bool val) async {
    await updateSettings(state.copyWith(duhaReminder: val));
  }

  Future<void> toggleSehriWarning(bool val) async {
    await updateSettings(state.copyWith(sehriWarning: val));
  }

  Future<void> toggleIftarReminder(bool val) async {
    await updateSettings(state.copyWith(iftarReminder: val));
  }

  Future<void> toggleAdhkar(bool val) async {
    await updateSettings(state.copyWith(dailyAdhkarReminder: val));
  }

  Future<void> setAdvanceMinutes(int minutes) async {
    await updateSettings(state.copyWith(advanceMinutes: minutes));
  }
}
