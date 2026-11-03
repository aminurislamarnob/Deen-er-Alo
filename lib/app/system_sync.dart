import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/notification_service.dart';
import '../core/services/prayer_alarm_scheduler.dart';
import '../core/services/widget_sync_service.dart';
import '../core/utils/bangla_numbers.dart';
import '../core/utils/city_clock.dart';
import '../features/calendar/domain/hijri_utils.dart';
import '../features/calendar/presentation/hijri_providers.dart';
import '../features/prayer_times/domain/city_model.dart';
import '../features/prayer_times/domain/prayer_model.dart';
import '../features/prayer_times/presentation/prayer_providers.dart';
import '../features/settings/presentation/notification_settings_provider.dart';
import '../features/tracker/data/habit_repository.dart';
import '../features/tracker/domain/habit_models.dart';
import '../features/tracker/presentation/habit_tracker_provider.dart';

/// Keeps alarms and home screen widgets in sync with the app state.
///
/// It is the single place that (re)schedules alarms and refreshes widgets,
/// triggered on app start, on resume, at the city's midnight, and whenever the
/// selected city, notification settings or moon-sighting offset change.
class SystemSyncController with WidgetsBindingObserver {
  static const _permissionAskedKey = 'deener_alo_notif_permission_asked_v1';
  static const Duration _debounce = Duration(milliseconds: 600);
  static const Duration _resumeThrottle = Duration(minutes: 15);

  final Ref _ref;
  Timer? _debounceTimer;
  Timer? _midnightTimer;
  DateTime? _lastSyncAt;
  DateTime? _lastSyncDate;
  bool _syncing = false;
  bool _pending = false;
  bool _started = false;

  SystemSyncController(this._ref);

  /// Called once from the app root.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);

    _ref.listen<AsyncValue<CityModel>>(selectedCityProvider, (prev, next) {
      final city = next.valueOrNull;
      if (city != null && city != prev?.valueOrNull) requestSync();
    });
    _ref.listen(notificationSettingsProvider, (_, __) => requestSync());
    _ref.listen(moonOffsetProvider, (_, __) => requestSync());
    _ref.listen(prayerSourceProvider, (_, __) => requestSync());

    requestSync();
    _askNotificationPermissionOnce();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _midnightTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _ref.read(currentDayProvider.notifier).refresh();
    final zone = _ref.read(cityTimeZoneProvider);
    final today = CityClock.dateOnly(CityClock.now(zone));
    final stale = _lastSyncAt == null ||
        DateTime.now().difference(_lastSyncAt!) > _resumeThrottle ||
        _lastSyncDate != today;
    if (stale) requestSync();
  }

  /// Debounced request to reschedule alarms and refresh widgets.
  void requestSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, _runSync);
  }

  Future<void> _runSync() async {
    if (_syncing) {
      _pending = true;
      return;
    }
    _syncing = true;
    try {
      await _sync();
    } catch (e, st) {
      debugPrint('SystemSync failed: $e\n$st');
    } finally {
      _syncing = false;
      if (_pending) {
        _pending = false;
        requestSync();
      }
    }
  }

  Future<void> _sync() async {
    final city = _ref.read(selectedCityProvider).valueOrNull;
    if (city == null) return; // Will be triggered again once loaded.

    await _ref.read(notificationSettingsProvider.notifier).ready;
    await _ref.read(moonOffsetProvider.notifier).ready;
    await _ref.read(prayerSourceProvider.notifier).ready;
    final settings = _ref.read(notificationSettingsProvider);
    final moonOffset = _ref.read(moonOffsetProvider);
    final source = _ref.read(prayerSourceProvider);
    final engine = _ref.read(prayerEngineProvider);
    final habits = _ref.read(habitRepositoryProvider);

    final zone = city.effectiveTimeZone;
    final today = CityClock.dateOnly(CityClock.now(zone));

    final days = <DayPrayerTimes>[];
    final fastingDays = <DateTime>{};
    for (var i = 0; i <= PrayerAlarmScheduler.horizonDays; i++) {
      final date = DateTime(today.year, today.month, today.day + i);
      days.add(await engine.calculateDayPrayers(
        city: city,
        date: date,
        source: source,
      ));
      if (await _isFastingDay(date, moonOffset, habits)) fastingDays.add(date);
    }

    await PrayerAlarmScheduler(prayerEngine: engine).scheduleRollingAlarms(
      city: city,
      settings: settings,
      precomputedDays: days,
      isFastingDay: (d) => fastingDays.contains(CityClock.dateOnly(d)),
    );

    await WidgetSyncService.instance.syncSchedule(
      city: city,
      days: days,
      hijriLabel: (d) => hijriLabel(d, moonOffset),
    );

    _lastSyncAt = DateTime.now();
    _lastSyncDate = today;
    _scheduleMidnightRefresh(zone);
  }

  Future<bool> _isFastingDay(
      DateTime date, int moonOffset, HabitRepository habits) async {
    if (hijriForDate(date, moonOffset).hMonth == 9) return true;
    try {
      final record = await habits.getRecord(date);
      return record.fasting != FastingStatus.notFasting;
    } catch (_) {
      return false;
    }
  }

  /// Hijri date label, e.g. "১২ রমজান, ১৪৪৮ হিজরি".
  static String hijriLabel(DateTime date, int moonOffset) {
    final h = hijriForDate(date, moonOffset);
    final month = BanglaUtils.hijriMonthBengali[h.hMonth] ?? h.longMonthName;
    return '${BanglaUtils.toBanglaDigits(h.hDay)} $month, '
        '${BanglaUtils.toBanglaDigits(h.hYear)} হিজরি';
  }

  void _scheduleMidnightRefresh(String? zone) {
    _midnightTimer?.cancel();
    final now = CityClock.now(zone);
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
    _midnightTimer = Timer(nextMidnight.difference(now), requestSync);
  }

  Future<void> _askNotificationPermissionOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_permissionAskedKey) ?? false) return;
      // Let the first frame render before showing a system dialog.
      await Future<void>.delayed(const Duration(seconds: 1));
      await NotificationService.instance.requestNotificationPermission();
      await prefs.setBool(_permissionAskedKey, true);
      requestSync();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }
}

final systemSyncProvider = Provider<SystemSyncController>((ref) {
  final controller = SystemSyncController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});
