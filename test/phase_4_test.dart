import 'package:flutter_test/flutter_test.dart';
import 'package:deener_alo/core/utils/bangla_numbers.dart';
import 'package:deener_alo/features/calendar/data/islamic_events_repository.dart';
import 'package:deener_alo/features/calendar/presentation/calendar_providers.dart';
import 'package:deener_alo/features/prayer_times/domain/prayer_model.dart';
import 'package:deener_alo/features/settings/domain/notification_settings.dart';
import 'package:deener_alo/features/tracker/domain/habit_models.dart';

void main() {
  group('Phase 4: Notification Settings Tests', () {
    test('Default NotificationSettings are enabled with adhan tones', () {
      const settings = NotificationSettings();
      expect(settings.masterEnabled, isTrue);
      expect(settings.fajrTone, NotificationAlarmTone.adhan);
      expect(settings.dhuhrTone, NotificationAlarmTone.adhan);
      expect(settings.asrTone, NotificationAlarmTone.adhan);
      expect(settings.maghribTone, NotificationAlarmTone.adhan);
      expect(settings.ishaTone, NotificationAlarmTone.adhan);
      expect(settings.sehriWarning, isTrue);
      expect(settings.iftarReminder, isTrue);
      expect(settings.advanceMinutes, 0);
    });

    test('NotificationSettings serializes and deserializes properly', () {
      const settings = NotificationSettings(
        masterEnabled: false,
        fajrTone: NotificationAlarmTone.chime,
        advanceMinutes: 10,
        tahajjudReminder: true,
      );

      final json = settings.toJson();
      final restored = NotificationSettings.fromJson(json);

      expect(restored.masterEnabled, isFalse);
      expect(restored.fajrTone, NotificationAlarmTone.chime);
      expect(restored.advanceMinutes, 10);
      expect(restored.tahajjudReminder, isTrue);
    });
  });

  group('Phase 4: Habit & Prayer Tracker Tests', () {
    test('DailyHabitRecord initializes empty and calculates completed prayer count', () {
      final rec = DailyHabitRecord.empty('2026-11-01');
      expect(rec.dateStr, '2026-11-01');
      expect(rec.completedPrayerCount, 0);
      expect(rec.fasting, FastingStatus.notFasting);

      final updated = rec.copyWith(
        prayers: {
          PrayerType.fajr: PrayerStatus.jamaat,
          PrayerType.dhuhr: PrayerStatus.alone,
          PrayerType.asr: PrayerStatus.qaza,
          PrayerType.maghrib: PrayerStatus.notOffered,
          PrayerType.isha: PrayerStatus.notOffered,
        },
        fasting: FastingStatus.ramadanFarz,
        readQuran: true,
      );

      expect(updated.completedPrayerCount, 2); // Jamaat + Alone
      expect(updated.fasting, FastingStatus.ramadanFarz);
      expect(updated.readQuran, isTrue);

      final json = updated.toJson();
      final restored = DailyHabitRecord.fromJson(json);

      expect(restored.dateStr, '2026-11-01');
      expect(restored.completedPrayerCount, 2);
      expect(restored.prayers[PrayerType.fajr], PrayerStatus.jamaat);
      expect(restored.prayers[PrayerType.asr], PrayerStatus.qaza);
      expect(restored.fasting, FastingStatus.ramadanFarz);
    });
  });

  group('Phase 4: Islamic Hijri Calendar & Events Tests', () {
    final repo = IslamicEventsRepository();

    test('All major Islamic occasions are listed in repository', () {
      final all = repo.getAllEvents();
      expect(all.isNotEmpty, isTrue);

      // Verify Eid-ul-Fitr (1st Shawwal - month 10, day 1)
      final eidFitr = all.firstWhere(
        (e) => e.hijriMonth == 10 && e.hijriDay == 1,
      );
      expect(eidFitr.titleBn.contains('ঈদুল ফিতর'), isTrue);
      expect(eidFitr.isMajor, isTrue);

      // Verify Day of Ashura (10th Muharram - month 1, day 10)
      final ashura = all.firstWhere(
        (e) => e.hijriMonth == 1 && e.hijriDay == 10,
      );
      expect(ashura.titleBn.contains('আশুরা'), isTrue);
      expect(ashura.isFastingRecommended, isTrue);

      // Verify Day of Arafah (9th Dhul Hijjah - month 12, day 9)
      final arafah = all.firstWhere(
        (e) => e.hijriMonth == 12 && e.hijriDay == 9,
      );
      expect(arafah.titleBn.contains('আরাফাহ'), isTrue);
    });

    test('Ayyam al-Beed fasting is automatically recognized on 13, 14, 15', () {
      // Month 2 (Safar), Day 13
      final events = repo.getEventsForHijriDate(2, 13);
      expect(events.isNotEmpty, isTrue);
      expect(events.any((e) => e.titleBn.contains('আইয়ামে বিজ')), isTrue);
      expect(events.first.isFastingRecommended, isTrue);
    });

    test('Moon-sighting offset adjusts Hijri date calculation accurately', () {
      final testDate = DateTime(2026, 3, 20); // Gregorian base
      final hijriNormal = getAdjustedHijriDate(testDate, 0);
      final hijriPlusOne = getAdjustedHijriDate(testDate, 1);
      final hijriMinusOne = getAdjustedHijriDate(testDate, -1);

      expect(hijriNormal.hDay, isPositive);
      expect(hijriPlusOne.hDay, isNot(equals(hijriMinusOne.hDay)));
    });
  });

  group('Phase 4: Bangla Utility Formatter Tests', () {
    test('formatBanglaTime converts PM and AM with Bengali digits', () {
      final morning = DateTime(2026, 11, 1, 5, 15);
      final evening = DateTime(2026, 11, 1, 17, 30);

      expect(BanglaUtils.formatBanglaTime(morning), '০৫:১৫ AM');
      expect(BanglaUtils.formatBanglaTime(evening), '০৫:৩০ PM');
    });
  });
}
