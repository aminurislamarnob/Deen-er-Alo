import 'package:flutter_test/flutter_test.dart';
import 'package:deener_alo/features/prayer_times/data/prayer_engine.dart';
import 'package:deener_alo/features/prayer_times/domain/city_model.dart';
import 'package:deener_alo/features/prayer_times/domain/prayer_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrayerEngine Tests', () {
    final engine = PrayerEngine();
    final dhaka = CityModel.dhakaDefault();
    final testDate = DateTime(2026, 11, 1); // Nov 1, 2026

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

      // Suppose time is 10:00 AM (between Fajr and Dhuhr)
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

      // Suppose time is 14:00 (2:00 PM - between Dhuhr and Asr)
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
  });
}
