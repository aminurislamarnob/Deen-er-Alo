import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/prayer_alarm_scheduler.dart';
import '../../../core/services/system_settings_service.dart';
import '../../prayer_times/domain/prayer_model.dart';
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

  final Completer<void> _loaded = Completer<void>();

  /// Last non-off tone per prayer, so re-enabling a bell restores it.
  final Map<String, NotificationAlarmTone> _lastTone = {};

  NotificationSettingsNotifier(Ref ref) : super(const NotificationSettings()) {
    _loadSettings();
  }

  /// Completes once saved settings have been applied.
  Future<void> get ready => _loaded.future;

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);
      if (jsonStr != null) {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        if (mounted) state = NotificationSettings.fromJson(map);
      }
    } catch (_) {
      // Corrupt settings: keep defaults.
    } finally {
      if (!_loaded.isCompleted) _loaded.complete();
    }
  }

  /// Persists [newSettings]. Rescheduling is handled centrally by the
  /// system sync controller, which listens to this provider.
  Future<void> updateSettings(NotificationSettings newSettings) async {
    await ready; // Never overwrite saved settings with defaults.
    if (!mounted) return;
    state = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, json.encode(newSettings.toJson()));
  }

  NotificationAlarmTone toneFor(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return state.fajrTone;
      case PrayerType.dhuhr:
        return state.dhuhrTone;
      case PrayerType.asr:
        return state.asrTone;
      case PrayerType.maghrib:
        return state.maghribTone;
      case PrayerType.isha:
        return state.ishaTone;
      case PrayerType.sunrise:
        return state.sunriseReminder
            ? NotificationAlarmTone.chime
            : NotificationAlarmTone.off;
    }
  }

  /// Turns a prayer's alarm on (restoring its last tone) or off.
  Future<void> setPrayerAlarmEnabled(PrayerType type, bool enabled) async {
    await ready;
    if (type == PrayerType.sunrise) {
      await toggleSunrise(enabled);
      return;
    }
    final current = toneFor(type);
    if (enabled) {
      if (current != NotificationAlarmTone.off) return;
      await setTone(
        type.name,
        _lastTone[type.name] ?? NotificationAlarmTone.adhan,
      );
    } else {
      if (current == NotificationAlarmTone.off) return;
      _lastTone[type.name] = current;
      await setTone(type.name, NotificationAlarmTone.off);
    }
  }

  Future<void> toggleSunrise(bool val) async {
    await updateSettings(state.copyWith(sunriseReminder: val));
  }

  Future<void> toggleMaster(bool enabled) async {
    await updateSettings(state.copyWith(masterEnabled: enabled));
  }

  Future<void> setTone(String prayerKey, NotificationAlarmTone tone) async {
    await ready;
    if (tone != NotificationAlarmTone.off) _lastTone[prayerKey] = tone;
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

/// Per-prayer alarm bells shown on Home and the Prayers tab. This is a view
/// over [notificationSettingsProvider] (bell on ⇔ tone ≠ off), so the bells,
/// the settings screen and the scheduled alarms can never disagree.
class PrayerAlarmToggles extends StateNotifier<Map<PrayerType, bool>> {
  final Ref _ref;

  PrayerAlarmToggles(this._ref, NotificationSettings settings)
      : super(fromSettings(settings));

  static Map<PrayerType, bool> fromSettings(NotificationSettings s) => {
        PrayerType.fajr: s.fajrTone != NotificationAlarmTone.off,
        PrayerType.sunrise: s.sunriseReminder,
        PrayerType.dhuhr: s.dhuhrTone != NotificationAlarmTone.off,
        PrayerType.asr: s.asrTone != NotificationAlarmTone.off,
        PrayerType.maghrib: s.maghribTone != NotificationAlarmTone.off,
        PrayerType.isha: s.ishaTone != NotificationAlarmTone.off,
      };

  Future<void> toggleAlarm(PrayerType type) async {
    final enabled = !(state[type] ?? false);
    state = {...state, type: enabled}; // Optimistic UI update.
    await _ref
        .read(notificationSettingsProvider.notifier)
        .setPrayerAlarmEnabled(type, enabled);
  }
}

final prayerAlarmProvider =
    StateNotifierProvider<PrayerAlarmToggles, Map<PrayerType, bool>>((ref) {
  return PrayerAlarmToggles(ref, ref.watch(notificationSettingsProvider));
});

/// Device conditions that decide whether alarms actually fire on time.
class AlarmHealth {
  final bool notificationsAllowed;
  final bool exactAlarmsAllowed;
  final bool batteryUnrestricted;

  const AlarmHealth({
    required this.notificationsAllowed,
    required this.exactAlarmsAllowed,
    required this.batteryUnrestricted,
  });

  bool get allGood =>
      notificationsAllowed && exactAlarmsAllowed && batteryUnrestricted;
}

final alarmHealthProvider = FutureProvider.autoDispose<AlarmHealth>((ref) async {
  final notifications = NotificationService.instance;
  if (!notifications.isInitialized) await notifications.init();
  return AlarmHealth(
    notificationsAllowed: await notifications.areNotificationsEnabled(),
    exactAlarmsAllowed: await notifications.canScheduleExactAlarms(),
    batteryUnrestricted:
        await SystemSettingsService.instance.isIgnoringBatteryOptimizations(),
  );
});
