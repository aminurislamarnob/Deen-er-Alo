import 'package:flutter_test/flutter_test.dart';
import 'package:deener_alo/features/prayer_times/data/ifa_timetable_service.dart';
import 'package:deener_alo/features/prayer_times/data/prayer_engine.dart';
import 'package:deener_alo/features/prayer_times/domain/city_model.dart';
import 'package:deener_alo/features/prayer_times/domain/prayer_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrayerEngine Tests', () {
    final engine = PrayerEngine();
    final dhaka = CityModel.dhakaDefault();
    final testDate = DateTime(2026, 11, 1);

    test('calculates all 5 daily prayers in chronological order', () async {
      final dayPrayers = await engine.calculateDayPrayers(
        city: dhaka,
        date: testDate,
      );

      expect(dayPrayers.cityName, equals('Dhaka'));
      expect(dayPrayers.fajr.isBefore(dayPrayers.sunrise), isTrue);
      expect(dayPrayers.sunrise.isBefore(dayPrayers.dhuhr), isTrue);
      expect(dayPrayers.dhuhr.isBefore(dayPrayers.asr), isTrue);
      expect(dayPrayers.asr.isBefore(dayPrayers.maghrib), isTrue);
      expect(dayPrayers.maghrib.isBefore(dayPrayers.isha), isTrue);

      expect(dayPrayers.scheduleItems.length, equals(5));
      expect(dayPrayers.scheduleItems[0].type, equals(PrayerType.fajr));
      expect(dayPrayers.scheduleItems[1].type, equals(PrayerType.dhuhr));
      expect(dayPrayers.scheduleItems[2].type, equals(PrayerType.asr));
      expect(dayPrayers.scheduleItems[3].type, equals(PrayerType.maghrib));
      expect(dayPrayers.scheduleItems[4].type, equals(PrayerType.isha));
    });

    test('calculates countdown accurately for a given time', () async {
      final dayPrayers = await engine.calculateDayPrayers(
        city: dhaka,
        date: testDate,
      );

      final midMorning = DateTime(2026, 11, 1, 10, 0);
      final countdown = engine.calculateCountdown(
        dayPrayers: dayPrayers,
        now: midMorning,
      );

      expect(countdown.nextPrayer, equals(PrayerType.dhuhr));
      expect(countdown.prayerName, equals('Dhuhr'));
      expect(countdown.remaining.inMinutes, greaterThan(0));
      expect(countdown.progress, inInclusiveRange(0.0, 1.0));
    });

    test('calculates countdown for afternoon between Dhuhr and Asr', () async {
      final dayPrayers = await engine.calculateDayPrayers(
        city: dhaka,
        date: testDate,
      );

      final afternoon = DateTime(2026, 11, 1, 14, 0);
      final countdown = engine.calculateCountdown(
        dayPrayers: dayPrayers,
        now: afternoon,
      );

      expect(countdown.nextPrayer, equals(PrayerType.asr));
      expect(countdown.prayerName, equals('Asr'));
      expect(countdown.remaining.inMinutes, greaterThan(0));
      expect(countdown.progress, inInclusiveRange(0.0, 1.0));
    });

    test('marks isCurrent prayer properly when active time matches', () async {
      final dhuhrTime = DateTime(2026, 11, 1, 12, 30);
      final dayPrayers = await engine.calculateDayPrayers(
        city: dhaka,
        date: testDate,
        now: dhuhrTime,
      );

      final dhuhrItem = dayPrayers.scheduleItems
          .firstWhere((item) => item.type == PrayerType.dhuhr);
      expect(dhuhrItem.isCurrent, isTrue);

      final fajrItem = dayPrayers.scheduleItems
          .firstWhere((item) => item.type == PrayerType.fajr);
      expect(fajrItem.isCurrent, isFalse);
    });

    test('calculates exactly 3 prohibited prayer time intervals', () async {
      final dayPrayers = await engine.calculateDayPrayers(
        city: dhaka,
        date: testDate,
      );

      final prohibited = engine.getProhibitedTimes(dayPrayers);
      expect(prohibited.length, equals(3));
      expect(prohibited[0].title, contains('Sunrise'));
      expect(prohibited[1].title, contains('Zenith'));
      expect(prohibited[2].title, contains('Sunset'));

      final sunrisePlus5 = dayPrayers.sunrise.add(const Duration(minutes: 5));
      final currentProhibited =
          engine.getCurrentProhibitedTime(dayPrayers, sunrisePlus5);
      expect(currentProhibited, isNotNull);
      expect(currentProhibited!.bengaliTitle, contains('সূর্যোদয়'));

      final normalMorning = DateTime(2026, 11, 1, 10, 0);
      final safe = engine.getCurrentProhibitedTime(dayPrayers, normalMorning);
      expect(safe, isNull);
    });

    test('IFATimetableService loads and returns valid schedule for Dhaka', () async {
      final ifaService = IFATimetableService();
      final schedule = await ifaService.getSchedule(
        districtId: 8486, // Dhaka
        date: DateTime(2026, 11, 1),
      );

      expect(schedule, isNotNull);
      expect(schedule!.sehriEnd.hour, equals(4));
      expect(schedule.sehriEnd.minute, equals(43));
      expect(schedule.fajrStart.hour, equals(4));
      expect(schedule.fajrStart.minute, equals(46));
      expect(schedule.iftarTime.hour, equals(17));
      expect(schedule.iftarTime.minute, equals(23));
    });
  });
}
