import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deener_alo/features/prayer_times/data/ifa_timetable_service.dart';
import 'package:deener_alo/features/prayer_times/data/prayer_engine.dart';
import 'package:deener_alo/features/prayer_times/domain/city_model.dart';
import 'package:deener_alo/features/prayer_times/domain/prayer_source.dart';
import 'package:deener_alo/features/settings/domain/notification_settings.dart';
import 'package:deener_alo/core/services/prayer_alarm_scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IFB Timetable Rebuild & Prayer Source Tests', () {
    late IFBTimetableService ifbService;
    late PrayerEngine engine;
    final dhaka = CityModel.dhakaDefault();

    setUpAll(() {
      ifbService = IFBTimetableService();
      engine = PrayerEngine(ifaService: ifbService);
    });

    test('1. Generated table reproduces all 72 published IFB Dhaka values (with 3 corrections)', () async {
      final csvFile = File('data/ifb/ifb_dhaka.csv');
      final lines = csvFile.readAsLinesSync();
      var headerIndex = 0;
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('month') && lines[i].contains('day')) {
          headerIndex = i;
          break;
        }
      }

      final header = lines[headerIndex].replaceAll('\uFEFF', '').split(',');
      for (var i = headerIndex + 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(',');
        final row = <String, String>{};
        for (var h = 0; h < header.length; h++) {
          row[header[h]] = parts[h];
        }

        final m = int.parse(row['month']!);
        var d = int.parse(row['day']!);
        if (m == 2 && d == 30) d = 28;

        var expectedSehri = row['sehri']!;
        var expectedFajr = row['fajr']!;
        var expectedIftar = row['maghrib_iftar']!;

        // Apply the 3 documented corrections
        if (m == 6 && d == 24) expectedIftar = '6:53';
        if (m == 6 && d == 30) expectedSehri = '3:42';
        if (m == 11 && d == 24) expectedFajr = '5:02';

        final schedule = await ifbService.getSchedule(
          districtId: 8486,
          date: DateTime(2028, m, d),
        );
        expect(schedule, isNotNull, reason: 'Failed for Dhaka at $m/$d');

        final sParts = expectedSehri.split(':');
        final expSh = int.parse(sParts[0]);
        final expSm = int.parse(sParts[1]);
        expect(schedule!.sehriEnd.hour, equals(expSh), reason: 'Sehri hour mismatch at $m/$d');
        expect(schedule.sehriEnd.minute, equals(expSm), reason: 'Sehri min mismatch at $m/$d');

        final fParts = expectedFajr.split(':');
        final expFh = int.parse(fParts[0]);
        final expFm = int.parse(fParts[1]);
        expect(schedule.fajrStart.hour, equals(expFh), reason: 'Fajr hour mismatch at $m/$d');
        expect(schedule.fajrStart.minute, equals(expFm), reason: 'Fajr min mismatch at $m/$d');

        final iParts = expectedIftar.split(':');
        final expIh = int.parse(iParts[0]) + 12; // PM
        final expIm = int.parse(iParts[1]);
        expect(schedule.iftarTime.hour, equals(expIh), reason: 'Iftar hour mismatch at $m/$d');
        expect(schedule.iftarTime.minute, equals(expIm), reason: 'Iftar min mismatch at $m/$d');
      }
    });

    test('2. All 64 districts × 366 days exist and Feb 29 2028 returns a valid schedule', () async {
      final jsonStr = await rootBundle.loadString('assets/data/countries+cities.json');
      final countries = json.decode(jsonStr) as List<dynamic>;
      final bd = countries.firstWhere((c) => c['nm'] == 'Bangladesh');
      final cities = bd['cities'] as List<dynamic>;
      expect(cities.length, equals(64));

      final leapFeb29 = DateTime(2028, 2, 29);
      for (final city in cities) {
        final id = city['id'] as int;
        final sched = await ifbService.getSchedule(districtId: id, date: leapFeb29);
        expect(sched, isNotNull, reason: 'District $id (${city['nm']}) missing on Feb 29');
        expect(sched!.sehriEnd.hour, isIn([4, 5]));
        expect(sched.iftarTime.hour, isIn([17, 18]));
        expect(sched.fajrStart.difference(sched.sehriEnd).inMinutes, equals(6));
      }
    });

    test('3. Per day: Sehri < Fajr < sunrise < Dhuhr < Asr < Maghrib < Isha and Fajr - Sehri == 6 for Dhaka', () async {
      final schedule = await engine.calculateDayPrayers(
        city: dhaka,
        date: DateTime(2028, 6, 15),
        source: PrayerCalculationSource.ifb,
      );

      expect(schedule.sehriEnd!.isBefore(schedule.fajr), isTrue);
      expect(schedule.fajr.isBefore(schedule.sunrise), isTrue);
      expect(schedule.sunrise.isBefore(schedule.dhuhr), isTrue);
      expect(schedule.dhuhr.isBefore(schedule.asr), isTrue);
      expect(schedule.asr.isBefore(schedule.maghrib), isTrue);
      expect(schedule.maghrib.isBefore(schedule.isha), isTrue);
      expect(schedule.fajr.difference(schedule.sehriEnd!).inMinutes, equals(6));
    });

    test('4. Day-to-day change is <= 2 minutes (no step jumps)', () async {
      final jsonStr = await rootBundle.loadString('assets/data/ifb_times.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final districts = data['districts'] as Map<String, dynamic>;

      int parseMinutes(String s) {
        final parts = s.split(':');
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }

      for (final distEntry in districts.entries) {
        final dMap = distEntry.value as Map<String, dynamic>;
        final sehri = (dMap['sehri'] as List<dynamic>).cast<String>();
        final iftar = (dMap['iftar'] as List<dynamic>).cast<String>();

        for (var i = 0; i < 365; i++) {
          final sDiff = (parseMinutes(sehri[i + 1]) - parseMinutes(sehri[i])).abs();
          final iDiff = (parseMinutes(iftar[i + 1]) - parseMinutes(iftar[i])).abs();
          expect(sDiff, lessThanOrEqualTo(2), reason: 'District ${distEntry.key} Sehri step > 2m at day $i');
          expect(iDiff, lessThanOrEqualTo(2), reason: 'District ${distEntry.key} Iftar step > 2m at day $i');
        }
      }
    });

    test('5. Moulvibazar (-6) vs Meherpur (+7) regression guard for swapped data', () async {
      final date = DateTime(2028, 1, 1);
      final dhakaSched = await ifbService.getSchedule(districtId: 8486, date: date);
      final moulviSched = await ifbService.getSchedule(districtId: 8533, date: date); // Moulvibazar
      final meherSched = await ifbService.getSchedule(districtId: 8536, date: date);  // Meherpur

      expect(dhakaSched, isNotNull);
      expect(moulviSched, isNotNull);
      expect(meherSched, isNotNull);

      // Moulvibazar is 6 minutes earlier than Dhaka
      expect(dhakaSched!.sehriEnd.difference(moulviSched!.sehriEnd).inMinutes, equals(6));
      expect(dhakaSched.iftarTime.difference(moulviSched.iftarTime).inMinutes, equals(6));

      // Meherpur is 7 minutes later than Dhaka
      expect(meherSched!.sehriEnd.difference(dhakaSched.sehriEnd).inMinutes, equals(7));
      expect(meherSched.iftarTime.difference(dhakaSched.iftarTime).inMinutes, equals(7));
    });

    test('6. IFB mode vs Karachi mode differ as expected and alarms can be planned', () async {
      final testDate = DateTime(2026, 11, 1);

      final ifbPrayers = await engine.calculateDayPrayers(
        city: dhaka,
        date: testDate,
        source: PrayerCalculationSource.ifb,
      );

      final karachiPrayers = await engine.calculateDayPrayers(
        city: dhaka,
        date: testDate,
        source: PrayerCalculationSource.karachi,
      );

      // Both are valid and close (within 4 minutes)
      expect(ifbPrayers.cityName, equals('Dhaka'));
      expect(karachiPrayers.cityName, equals('Dhaka'));
      final fajrDiff = (ifbPrayers.fajr.difference(karachiPrayers.fajr).inMinutes).abs();
      final iftarDiff = (ifbPrayers.iftar!.difference(karachiPrayers.iftar!).inMinutes).abs();
      expect(fajrDiff, lessThanOrEqualTo(4));
      expect(iftarDiff, lessThanOrEqualTo(4));

      // Scheduler planning succeeds in both modes
      final settings = const NotificationSettings(masterEnabled: true);
      final ifbAlarms = PrayerAlarmScheduler.planAlarms(
        city: dhaka,
        settings: settings,
        days: [ifbPrayers],
        now: DateTime.utc(2026, 11, 1, 3, 0),
      );
      final karachiAlarms = PrayerAlarmScheduler.planAlarms(
        city: dhaka,
        settings: settings,
        days: [karachiPrayers],
        now: DateTime.utc(2026, 11, 1, 3, 0),
      );
      expect(ifbAlarms, isNotEmpty);
      expect(karachiAlarms, isNotEmpty);
    });

    test('7. Prohibited time windows follow IFB rules (24m / 6m / 24m)', () async {
      final prayers = await engine.calculateDayPrayers(
        city: dhaka,
        date: DateTime(2026, 11, 1),
        source: PrayerCalculationSource.ifb,
      );

      final ranges = engine.getProhibitedTimes(prayers);
      expect(ranges.length, equals(3));

      // 1. Sunrise -> +24 min
      expect(ranges[0].startTime, equals(prayers.sunrise));
      expect(ranges[0].endTime, equals(prayers.sunrise.add(const Duration(minutes: 24))));
      expect(ranges[0].endTime.difference(ranges[0].startTime).inMinutes, equals(24));
      expect(ranges[0].reason, contains('২৪ মিনিট'));

      // 2. Dhuhr - 6 min -> Dhuhr (6 min duration)
      expect(ranges[1].startTime, equals(prayers.dhuhr.subtract(const Duration(minutes: 6))));
      expect(ranges[1].endTime, equals(prayers.dhuhr));
      expect(ranges[1].endTime.difference(ranges[1].startTime).inMinutes, equals(6));
      expect(ranges[1].reason, contains('৬ মিনিট'));

      // 3. Sunset - 24 min -> Maghrib
      expect(ranges[2].startTime, equals(prayers.maghrib.subtract(const Duration(minutes: 24))));
      expect(ranges[2].endTime, equals(prayers.maghrib));
      expect(ranges[2].endTime.difference(ranges[2].startTime).inMinutes, equals(24));
      expect(ranges[2].reason, contains('২৪ মিনিট'));
    });
  });
}
