import 'package:flutter/foundation.dart';
import '../../features/prayer_times/data/prayer_engine.dart';
import '../../features/prayer_times/domain/city_model.dart';
import '../../features/settings/domain/notification_settings.dart';
import '../utils/bangla_numbers.dart';
import 'notification_service.dart';

class PrayerAlarmScheduler {
  final NotificationService _notificationService;
  final PrayerEngine _prayerEngine;

  PrayerAlarmScheduler({
    NotificationService? notificationService,
    PrayerEngine? prayerEngine,
  })  : _notificationService = notificationService ?? NotificationService.instance,
        _prayerEngine = prayerEngine ?? PrayerEngine();

  Future<void> scheduleRollingAlarms({
    required CityModel city,
    required NotificationSettings settings,
  }) async {
    if (!settings.masterEnabled) {
      await _notificationService.cancelAll();
      debugPrint('All alarms canceled because masterEnabled is false.');
      return;
    }

    if (!_notificationService.isInitialized) {
      await _notificationService.init();
    }

    final now = DateTime.now();

    for (int dayOffset = 0; dayOffset < 2; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final baseId = dayOffset * 100;

      try {
        final dayPrayers = await _prayerEngine.calculateDayPrayers(
          city: city,
          date: targetDate,
          now: now,
        );

        // 1. Fajr
        if (settings.fajrTone != NotificationAlarmTone.off) {
          final fajrTime = dayPrayers.fajr.subtract(
            Duration(minutes: settings.advanceMinutes),
          );
          await _notificationService.scheduleAlarm(
            id: baseId + 1,
            title: 'ফজরের ওয়াক্ত শুরু',
            body: 'ফজরের নামাজের সময় হয়েছে (${city.name}: ${BanglaUtils.formatBanglaTime(dayPrayers.fajr)})',
            scheduledDate: fajrTime,
            channelId: settings.fajrTone.channelId,
          );
        }

        // 2. Dhuhr
        if (settings.dhuhrTone != NotificationAlarmTone.off) {
          final dhuhrTime = dayPrayers.dhuhr.subtract(
            Duration(minutes: settings.advanceMinutes),
          );
          await _notificationService.scheduleAlarm(
            id: baseId + 2,
            title: 'জোহরের ওয়াক্ত শুরু',
            body: 'জোহরের নামাজের সময় হয়েছে (${city.name}: ${BanglaUtils.formatBanglaTime(dayPrayers.dhuhr)})',
            scheduledDate: dhuhrTime,
            channelId: settings.dhuhrTone.channelId,
          );
        }

        // 3. Asr
        if (settings.asrTone != NotificationAlarmTone.off) {
          final asrTime = dayPrayers.asr.subtract(
            Duration(minutes: settings.advanceMinutes),
          );
          await _notificationService.scheduleAlarm(
            id: baseId + 3,
            title: 'আসরের ওয়াক্ত শুরু',
            body: 'আসরের নামাজের সময় হয়েছে (${city.name}: ${BanglaUtils.formatBanglaTime(dayPrayers.asr)})',
            scheduledDate: asrTime,
            channelId: settings.asrTone.channelId,
          );
        }

        // 4. Maghrib
        if (settings.maghribTone != NotificationAlarmTone.off) {
          final maghribTime = dayPrayers.maghrib.subtract(
            Duration(minutes: settings.advanceMinutes),
          );
          await _notificationService.scheduleAlarm(
            id: baseId + 4,
            title: 'মাগরিবের ওয়াক্ত ও ইফতার',
            body: 'মাগরিবের নামাজের সময় হয়েছে (${city.name}: ${BanglaUtils.formatBanglaTime(dayPrayers.maghrib)})',
            scheduledDate: maghribTime,
            channelId: settings.maghribTone.channelId,
          );
        }

        // 5. Isha
        if (settings.ishaTone != NotificationAlarmTone.off) {
          final ishaTime = dayPrayers.isha.subtract(
            Duration(minutes: settings.advanceMinutes),
          );
          await _notificationService.scheduleAlarm(
            id: baseId + 5,
            title: 'ইশার ওয়াক্ত শুরু',
            body: 'ইশার নামাজের সময় হয়েছে (${city.name}: ${BanglaUtils.formatBanglaTime(dayPrayers.isha)})',
            scheduledDate: ishaTime,
            channelId: settings.ishaTone.channelId,
          );
        }

        // 6. Sunrise
        if (settings.sunriseReminder) {
          await _notificationService.scheduleAlarm(
            id: baseId + 6,
            title: 'সূর্যোদয় সম্পন্ন',
            body: 'সূর্যোদয়ের সময়: ${BanglaUtils.formatBanglaTime(dayPrayers.sunrise)}। ফজরের ওয়াক্ত সমাপ্ত।',
            scheduledDate: dayPrayers.sunrise,
            channelId: NotificationService.channelPrayerChime,
          );
        }

        // 7. Tahajjud (45 minutes before Fajr)
        if (settings.tahajjudReminder) {
          final tahajjudTime =
              dayPrayers.fajr.subtract(const Duration(minutes: 45));
          await _notificationService.scheduleAlarm(
            id: baseId + 7,
            title: 'তাহাজ্জুদ নামাজের স্মরণিকা',
            body: 'রাতের শেষ তৃতীয়াংশ। তাহাজ্জুদ ও দোয়ার সুবর্ণ সময়।',
            scheduledDate: tahajjudTime,
            channelId: NotificationService.channelPrayerChime,
          );
        }

        // 8. Salatud Duha / Chasht (25 minutes after Sunrise)
        if (settings.duhaReminder) {
          final duhaTime =
              dayPrayers.sunrise.add(const Duration(minutes: 25));
          await _notificationService.scheduleAlarm(
            id: baseId + 8,
            title: 'ইশরাক ও চাশতের ওয়াক্ত',
            body: 'সূর্যোদয়ের পর চাশত (সালাতুদ দুহা) আদায়ের উত্তম সময়।',
            scheduledDate: duhaTime,
            channelId: NotificationService.channelPrayerChime,
          );
        }

        // 9. Sehri Warning (15 minutes before Sehri end)
        if (settings.sehriWarning && dayPrayers.sehriEnd != null) {
          final warningTime =
              dayPrayers.sehriEnd!.subtract(const Duration(minutes: 15));
          await _notificationService.scheduleAlarm(
            id: baseId + 9,
            title: 'সাহরির শেষ সময় সতর্কবার্তা',
            body: 'সাহরির বাকি মাত্র ১৫ মিনিট! শেষ সময়: ${BanglaUtils.formatBanglaTime(dayPrayers.sehriEnd!)}',
            scheduledDate: warningTime,
            channelId: NotificationService.channelFasting,
          );
        }

        // 10. Iftar Reminder (10 minutes before Iftar)
        if (settings.iftarReminder && dayPrayers.iftar != null) {
          final warningTime =
              dayPrayers.iftar!.subtract(const Duration(minutes: 10));
          await _notificationService.scheduleAlarm(
            id: baseId + 10,
            title: 'ইফতারের প্রস্তুতি নিন',
            body: 'ইফতারের বাকি মাত্র ১০ মিনিট! ইফতারের সময়: ${BanglaUtils.formatBanglaTime(dayPrayers.iftar!)}',
            scheduledDate: warningTime,
            channelId: NotificationService.channelFasting,
          );
        }

        // 11. Daily Adhkar (Morning & Evening)
        if (settings.dailyAdhkarReminder) {
          final morningAdhkar =
              dayPrayers.sunrise.add(const Duration(minutes: 30));
          await _notificationService.scheduleAlarm(
            id: baseId + 11,
            title: 'সকালের মাসনুন জিকির',
            body: 'সকালের দোয়া ও জিকির পাঠ করে দিনটি বরকতময় করুন।',
            scheduledDate: morningAdhkar,
            channelId: NotificationService.channelAdhkar,
          );

          final eveningAdhkar =
              dayPrayers.maghrib.subtract(const Duration(minutes: 45));
          await _notificationService.scheduleAlarm(
            id: baseId + 12,
            title: 'সন্ধ্যার মাসনুন জিকির ও দরূদ',
            body: 'সন্ধ্যার হেফাজতের দোয়া ও ইস্তিগফার পাঠ করুন।',
            scheduledDate: eveningAdhkar,
            channelId: NotificationService.channelAdhkar,
          );
        }
      } catch (e) {
        debugPrint('Error scheduling alarms for day offset $dayOffset: $e');
      }
    }

    debugPrint('Rolling 48-hour alarms successfully calculated and scheduled.');
  }
}
