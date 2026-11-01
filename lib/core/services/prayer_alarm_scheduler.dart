import 'package:flutter/foundation.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../features/prayer_times/data/prayer_engine.dart';
import '../../features/prayer_times/domain/city_model.dart';
import '../../features/prayer_times/domain/prayer_model.dart';
import '../../features/settings/domain/notification_settings.dart';
import '../utils/bangla_numbers.dart';
import '../utils/city_clock.dart';
import 'notification_service.dart';

/// A single notification the scheduler intends to post.
@immutable
class PlannedAlarm {
  final int id;
  final String title;
  final String body;

  /// Real instant (UTC) at which the alarm fires.
  final DateTime fireAt;
  final String channelId;

  const PlannedAlarm({
    required this.id,
    required this.title,
    required this.body,
    required this.fireAt,
    required this.channelId,
  });

  @override
  String toString() => 'PlannedAlarm($id, $title, $fireAt, $channelId)';
}

/// Decides whether the given city-local date is a fasting day.
typedef FastingDayPredicate = bool Function(DateTime cityDate);

/// Default predicate: Ramadan according to the tabular Hijri calendar.
bool isRamadanDay(DateTime cityDate) =>
    HijriCalendar.fromDate(cityDate).hMonth == 9;

/// Schedules prayer alarms and reminders for a rolling window of days.
///
/// Android's AlarmManager (via flutter_local_notifications) keeps these
/// across reboots. The window is refreshed whenever the app starts, resumes,
/// or the city / settings / date change, so alarms keep firing for
/// [horizonDays] days even if the app is not opened.
class PrayerAlarmScheduler {
  /// How many days ahead alarms are scheduled (≤ ~13 alarms per day).
  static const int horizonDays = 7;

  /// Alarm ids are `dayIndex * idStride + slot`.
  static const int idStride = 100;

  final NotificationService _notificationService;
  final PrayerEngine _prayerEngine;

  PrayerAlarmScheduler({
    NotificationService? notificationService,
    PrayerEngine? prayerEngine,
  })  : _notificationService =
            notificationService ?? NotificationService.instance,
        _prayerEngine = prayerEngine ?? PrayerEngine();

  /// Recomputes and re-posts every alarm. Previously scheduled alarms are
  /// always cancelled first, so disabled reminders and stale times (e.g.
  /// after a city change) never fire.
  Future<int> scheduleRollingAlarms({
    required CityModel city,
    required NotificationSettings settings,
    FastingDayPredicate isFastingDay = isRamadanDay,
    DateTime? now,
    List<DayPrayerTimes>? precomputedDays,
  }) async {
    if (!_notificationService.isInitialized) {
      await _notificationService.init();
    }
    await _notificationService.cancelAll();

    if (!settings.masterEnabled) {
      debugPrint('Alarms disabled (master switch off).');
      return 0;
    }

    final zone = city.effectiveTimeZone;
    final nowInstant = (now ?? DateTime.now()).toUtc();
    final todayWall = CityClock.dateOnly(CityClock.toWall(nowInstant, zone));

    final days = <DayPrayerTimes>[...?precomputedDays];
    final needsCompute = days.isEmpty;
    for (var i = 0; needsCompute && i <= horizonDays; i++) {
      final date = DateTime(todayWall.year, todayWall.month, todayWall.day + i);
      try {
        days.add(await _prayerEngine.calculateDayPrayers(
          city: city,
          date: date,
        ));
      } catch (e) {
        debugPrint('Alarm planning failed for $date: $e');
      }
    }

    final plan = planAlarms(
      city: city,
      settings: settings,
      days: days,
      isFastingDay: isFastingDay,
      now: nowInstant,
    );

    for (final alarm in plan) {
      await _notificationService.scheduleAlarm(
        id: alarm.id,
        title: alarm.title,
        body: alarm.body,
        scheduledDate: alarm.fireAt,
        channelId: alarm.channelId,
      );
    }
    debugPrint('Scheduled ${plan.length} alarms for ${city.name}.');
    return plan.length;
  }

  /// Pure planning step (unit-testable): returns the alarms that should be
  /// posted for [days], keeping only those strictly after [now] and within
  /// [horizonDays] days of it.
  static List<PlannedAlarm> planAlarms({
    required CityModel city,
    required NotificationSettings settings,
    required List<DayPrayerTimes> days,
    FastingDayPredicate isFastingDay = isRamadanDay,
    required DateTime now,
  }) {
    if (!settings.masterEnabled) return const [];
    final zone = city.effectiveTimeZone;
    final nowUtc = now.toUtc();
    final limit = nowUtc.add(const Duration(days: horizonDays));
    final advance = Duration(minutes: settings.advanceMinutes);
    final result = <PlannedAlarm>[];

    String t(DateTime wall) => BanglaUtils.formatBanglaTime(wall);

    void add(int dayIndex, int slot, DateTime wall, String title, String body,
        String channelId) {
      final fireAt = CityClock.toInstant(wall, zone);
      if (!fireAt.isAfter(nowUtc) || fireAt.isAfter(limit)) return;
      result.add(PlannedAlarm(
        id: dayIndex * idStride + slot,
        title: title,
        body: body,
        fireAt: fireAt,
        channelId: channelId,
      ));
    }

    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final fasting = isFastingDay(day.date);

      void prayer(int slot, PrayerType type, DateTime start,
          NotificationAlarmTone tone) {
        if (tone == NotificationAlarmTone.off) return;
        final name = type.bengaliName;
        final isMaghribIftar = type == PrayerType.maghrib && fasting;
        final String title;
        final String body;
        if (settings.advanceMinutes > 0) {
          final mins = BanglaUtils.toBanglaDigits(settings.advanceMinutes);
          title = '$name-এর ওয়াক্ত আসন্ন';
          body = '$mins মিনিট পর $name-এর ওয়াক্ত শুরু হবে '
              '(${city.name}: ${t(start)})';
        } else {
          title = isMaghribIftar
              ? 'মাগরিবের ওয়াক্ত ও ইফতার'
              : '$name-এর ওয়াক্ত শুরু';
          body = '$name-এর নামাজের সময় হয়েছে (${city.name}: ${t(start)})';
        }
        add(i, slot, start.subtract(advance), title, body, tone.channelId);
      }

      prayer(1, PrayerType.fajr, day.fajr, settings.fajrTone);
      prayer(2, PrayerType.dhuhr, day.dhuhr, settings.dhuhrTone);
      prayer(3, PrayerType.asr, day.asr, settings.asrTone);
      prayer(4, PrayerType.maghrib, day.maghrib, settings.maghribTone);
      prayer(5, PrayerType.isha, day.isha, settings.ishaTone);

      if (settings.sunriseReminder) {
        add(
          i,
          6,
          day.sunrise,
          'সূর্যোদয়',
          'সূর্যোদয়ের সময়: ${t(day.sunrise)}। ফজরের ওয়াক্ত সমাপ্ত।',
          NotificationService.channelPrayerChime,
        );
      }

      if (settings.tahajjudReminder) {
        add(
          i,
          7,
          day.fajr.subtract(const Duration(minutes: 45)),
          'তাহাজ্জুদ নামাজের স্মরণিকা',
          'রাতের শেষ তৃতীয়াংশ। তাহাজ্জুদ ও দোয়ার সুবর্ণ সময়।',
          NotificationService.channelPrayerChime,
        );
      }

      if (settings.duhaReminder) {
        add(
          i,
          8,
          day.sunrise.add(const Duration(minutes: 25)),
          'ইশরাক ও চাশতের ওয়াক্ত',
          'সূর্যোদয়ের পর চাশত (সালাতুদ দুহা) আদায়ের উত্তম সময়।',
          NotificationService.channelPrayerChime,
        );
      }

      // Fasting reminders only on fasting days (Ramadan or logged fasts).
      if (fasting && settings.sehriWarning && day.sehriEnd != null) {
        add(
          i,
          9,
          day.sehriEnd!.subtract(const Duration(minutes: 15)),
          'সাহরির শেষ সময় সতর্কবার্তা',
          'সাহরির বাকি মাত্র ১৫ মিনিট! শেষ সময়: ${t(day.sehriEnd!)}',
          NotificationService.channelFasting,
        );
      }

      if (fasting && settings.iftarReminder && day.iftar != null) {
        add(
          i,
          10,
          day.iftar!.subtract(const Duration(minutes: 10)),
          'ইফতারের প্রস্তুতি নিন',
          'ইফতারের বাকি মাত্র ১০ মিনিট! ইফতারের সময়: ${t(day.iftar!)}',
          NotificationService.channelFasting,
        );
      }

      if (settings.dailyAdhkarReminder) {
        add(
          i,
          11,
          day.sunrise.add(const Duration(minutes: 30)),
          'সকালের মাসনুন জিকির',
          'সকালের দোয়া ও জিকির পাঠ করে দিনটি বরকতময় করুন।',
          NotificationService.channelAdhkar,
        );
        add(
          i,
          12,
          day.maghrib.subtract(const Duration(minutes: 45)),
          'সন্ধ্যার মাসনুন জিকির ও দরূদ',
          'সন্ধ্যার হেফাজতের দোয়া ও ইস্তিগফার পাঠ করুন।',
          NotificationService.channelAdhkar,
        );
      }
    }

    result.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return result;
  }
}
