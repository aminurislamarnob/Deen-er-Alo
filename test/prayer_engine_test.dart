import 'dart:convert';
import 'package:flutter/services.dart';
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
      expect(schedule.fajrStart.minute, equals(49)); // Official IFB rule: Fajr = Sehri + 6
      expect(schedule.iftarTime.hour, equals(17));
      expect(schedule.iftarTime.minute, equals(23));
    });

    test('IFATimetableService handles Leap Year Feb 29 across all 64 Bangladesh districts', () async {
      final ifaService = IFATimetableService();
      final leapYearFeb29 = DateTime(2028, 2, 29);

      // Verify Dhaka
      final dhaka = await ifaService.getSchedule(
        districtId: 8486,
        date: leapYearFeb29,
      );
      expect(dhaka, isNotNull);
      expect(dhaka!.sehriEnd.hour, equals(5));
      expect(dhaka.sehriEnd.minute, equals(1));
      expect(dhaka.fajrStart.hour, equals(5));
      expect(dhaka.fajrStart.minute, equals(7)); // Official IFB: Fajr = Sehri + 6
      expect(dhaka.iftarTime.hour, equals(18));
      expect(dhaka.iftarTime.minute, equals(5));

      // Verify Naogaon (district 8545: official offset +8m)
      final naogaon = await ifaService.getSchedule(
        districtId: 8545,
        date: leapYearFeb29,
      );
      expect(naogaon, isNotNull);
      expect(naogaon!.sehriEnd.hour, equals(5));
      expect(naogaon.sehriEnd.minute, equals(9)); // 5:01 + 8m = 5:09
      expect(naogaon.fajrStart.hour, equals(5));
      expect(naogaon.fajrStart.minute, equals(15)); // 5:07 + 8m = 5:15
      expect(naogaon.iftarTime.hour, equals(18));
      expect(naogaon.iftarTime.minute, equals(13)); // 18:05 + 8m = 18:13

      // Verify Narail (district 8546: official offset +3m)
      final narail = await ifaService.getSchedule(
        districtId: 8546,
        date: leapYearFeb29,
      );
      expect(narail, isNotNull);
      expect(narail!.sehriEnd.hour, equals(5));
      expect(narail.sehriEnd.minute, equals(4)); // 5:01 + 3m = 5:04
      expect(narail.fajrStart.hour, equals(5));
      expect(narail.fajrStart.minute, equals(10)); // 5:07 + 3m = 5:10
      expect(narail.iftarTime.hour, equals(18));
      expect(narail.iftarTime.minute, equals(8)); // 18:05 + 3m = 18:08

      // Verify Moulvibazar (district 8533: official offset -6m, regression guard for swap)
      final moulvibazar = await ifaService.getSchedule(
        districtId: 8533,
        date: leapYearFeb29,
      );
      expect(moulvibazar, isNotNull);
      expect(moulvibazar!.sehriEnd.hour, equals(4));
      expect(moulvibazar.sehriEnd.minute, equals(55)); // 5:01 - 6m = 4:55
      expect(moulvibazar.fajrStart.hour, equals(5));
      expect(moulvibazar.fajrStart.minute, equals(1));   // 5:07 - 6m = 5:01

      // Verify Meherpur (district 8536: official offset +7m, regression guard for swap)
      final meherpur = await ifaService.getSchedule(
        districtId: 8536,
        date: leapYearFeb29,
      );
      expect(meherpur, isNotNull);
      expect(meherpur!.sehriEnd.hour, equals(5));
      expect(meherpur.sehriEnd.minute, equals(8));  // 5:01 + 7m = 5:08
      expect(meherpur.fajrStart.hour, equals(5));
      expect(meherpur.fajrStart.minute, equals(14)); // 5:07 + 7m = 5:14

      // Verify all 64 districts have valid non-null schedules on Feb 29
      final jsonStr = await rootBundle.loadString('assets/data/countries+cities.json');
      final countries = json.decode(jsonStr) as List<dynamic>;
      final bd = countries.firstWhere((c) => c['nm'] == 'Bangladesh');
      final cities = bd['cities'] as List<dynamic>;
      expect(cities.length, equals(64));

      for (final city in cities) {
        final id = city['id'] as int;
        final schedule = await ifaService.getSchedule(
          districtId: id,
          date: leapYearFeb29,
        );
        expect(schedule, isNotNull, reason: 'District $id (${city['nm']}) failed on Feb 29');
        expect(schedule!.sehriEnd.hour, greaterThanOrEqualTo(4));
        expect(schedule.iftarTime.hour, greaterThanOrEqualTo(17));
        expect(
          schedule.fajrStart.difference(schedule.sehriEnd).inMinutes,
          equals(6),
          reason: 'Fajr must equal Sehri + 6 in district $id (${city['nm']})',
        );
      }
    });
  });
}
