// These tests must pass regardless of the machine's time zone. CI runs them
// under several TZ values (see test/run_multi_tz.sh).
import 'package:flutter_test/flutter_test.dart';
import 'package:deener_alo/core/services/prayer_alarm_scheduler.dart';
import 'package:deener_alo/core/services/widget_sync_service.dart';
import 'package:deener_alo/core/utils/city_clock.dart';
import 'package:deener_alo/features/prayer_times/data/city_repository.dart';
import 'package:deener_alo/features/prayer_times/data/prayer_engine.dart';
import 'package:deener_alo/features/prayer_times/domain/city_model.dart';
import 'package:deener_alo/features/prayer_times/domain/prayer_model.dart';
import 'package:deener_alo/features/settings/domain/notification_settings.dart';

const london = CityModel(
  id: 1,
  name: 'London',
  countryName: 'United Kingdom',
  countryEmoji: '🇬🇧',
  latitude: 51.5074,
  longitude: -0.1278,
  timeZone: 'Europe/London',
);

const newYork = CityModel(
  id: 2,
  name: 'New York',
  countryName: 'United States',
  countryEmoji: '🇺🇸',
  latitude: 40.7128,
  longitude: -74.0060,
  timeZone: 'America/New_York',
);

void expectChronological(DayPrayerTimes d) {
  expect(d.fajr.isBefore(d.sunrise), isTrue, reason: 'fajr < sunrise');
  expect(d.sunrise.isBefore(d.dhuhr), isTrue, reason: 'sunrise < dhuhr');
  expect(d.dhuhr.isBefore(d.asr), isTrue, reason: 'dhuhr < asr');
  expect(d.asr.isBefore(d.maghrib), isTrue, reason: 'asr < maghrib');
  expect(d.maghrib.isBefore(d.isha), isTrue, reason: 'maghrib < isha');
  expect(d.sehriEnd!.isBefore(d.fajr) || d.sehriEnd == d.fajr, isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CityClock.ensureInitialized();
  final engine = PrayerEngine();

  group('CityClock', () {
    test('toWall/toInstant round-trip across zones and DST', () {
      for (final zone in ['Asia/Dhaka', 'Europe/London', 'America/New_York']) {
        for (final instant in [
          DateTime.utc(2026, 1, 15, 3, 30),
          DateTime.utc(2026, 3, 29, 1, 30), // London DST start day
          DateTime.utc(2026, 7, 1, 12),
          DateTime.utc(2026, 11, 1, 8, 30), // New York DST end day (after the repeated hour)
        ]) {
          final wall = CityClock.toWall(instant, zone);
          expect(wall.isUtc, isFalse);
          expect(CityClock.toInstant(wall, zone), instant, reason: zone);
        }
      }
    });

    test('Dhaka is UTC+6 with no DST', () {
      final wall = CityClock.toWall(DateTime.utc(2026, 6, 1, 0, 0), 'Asia/Dhaka');
      expect(wall, DateTime(2026, 6, 1, 6, 0));
    });
  });

  group('Prayer times on the city wall clock (device TZ independent)', () {
    test('Dhaka (IFA override) is chronological and plausible', () async {
      final d = await engine.calculateDayPrayers(
        city: CityModel.dhakaDefault(),
        date: DateTime(2026, 11, 1),
      );
      expectChronological(d);
      expect(d.fajr.hour, inInclusiveRange(4, 5));
      expect(d.dhuhr.hour, inInclusiveRange(11, 12));
      expect(d.maghrib.hour, 17);
      expect(d.isha.hour, inInclusiveRange(18, 19));
      // Isha ends at the next day's Fajr.
      final ishaEnd =
          d.scheduleItems.firstWhere((i) => i.type == PrayerType.isha).endTime;
      expect(ishaEnd.day, 2);
      expect(ishaEnd.hour, inInclusiveRange(4, 5));
    });

    test('London and New York use their own clocks', () async {
      final l = await engine.calculateDayPrayers(
        city: london,
        date: DateTime(2026, 11, 1),
      );
      expectChronological(l);
      expect(l.dhuhr.hour, anyOf(11, 12)); // ~11:44 GMT
      expect(l.maghrib.hour, 16); // ~16:35 GMT

      final ny = await engine.calculateDayPrayers(
        city: newYork,
        date: DateTime(2026, 7, 1),
      );
      expectChronological(ny);
      expect(ny.dhuhr.hour, anyOf(12, 13)); // ~13:02 EDT
      expect(ny.maghrib.hour, 20); // ~20:31 EDT
    });

    test('all IFA districts stay chronological all year', () async {
      // Spot-check a district on every month boundary (where the data has
      // known jumps); the engine must never produce an out-of-order day.
      for (var m = 1; m <= 12; m++) {
        for (final day in [1, 28]) {
          final d = await engine.calculateDayPrayers(
            city: CityModel.dhakaDefault(),
            date: DateTime(2026, m, day),
          );
          expectChronological(d);
        }
      }
    });
  });

  group('Countdown & current waqt', () {
    late DayPrayerTimes day;
    setUpAll(() async {
      day = await engine.calculateDayPrayers(
        city: CityModel.dhakaDefault(),
        date: DateTime(2026, 11, 1),
      );
    });

    test('after Isha targets tomorrow\'s real Fajr (not 0 / 100%)', () {
      final now = day.isha.add(const Duration(hours: 1));
      final c = engine.calculateCountdown(dayPrayers: day, now: now);
      expect(c.nextPrayer, PrayerType.fajr);
      expect(c.targetTime.isAfter(now), isTrue);
      expect(c.targetTime.day, 2);
      expect(c.remaining, greaterThan(const Duration(hours: 5)));
      expect(c.progress, inExclusiveRange(0.0, 1.0));
    });

    test('before Fajr: progress measured from previous Isha', () {
      final now = day.fajr.subtract(const Duration(hours: 1));
      final c = engine.calculateCountdown(dayPrayers: day, now: now);
      expect(c.nextPrayer, PrayerType.fajr);
      expect(c.progress, greaterThan(0.8));
    });

    test('during Fajr counts down to sunrise', () {
      final now = day.fajr.add(const Duration(minutes: 5));
      final c = engine.calculateCountdown(dayPrayers: day, now: now);
      expect(c.nextPrayer, PrayerType.sunrise);
      expect(c.targetTime, day.sunrise);
    });

    test('markCurrent follows the clock, Isha current after midnight', () {
      PrayerType? current(DateTime now) => engine
          .markCurrent(day, now)
          .scheduleItems
          .where((i) => i.isCurrent)
          .map((i) => i.type)
          .firstOrNull;

      expect(current(DateTime(2026, 11, 1, 1, 0)), PrayerType.isha);
      expect(current(day.fajr.add(const Duration(minutes: 1))), PrayerType.fajr);
      expect(current(day.sunrise.add(const Duration(minutes: 30))), isNull);
      expect(current(day.asr.add(const Duration(minutes: 1))), PrayerType.asr);
      // A different day's schedule is never "current".
      expect(current(DateTime(2026, 11, 2, 13)), isNull);
    });
  });

  group('Alarm planning', () {
    late List<DayPrayerTimes> days;
    final now = CityClock.toInstant(DateTime(2026, 11, 1, 12, 0), 'Asia/Dhaka');

    setUpAll(() async {
      days = [
        for (var i = 0; i < 8; i++)
          await engine.calculateDayPrayers(
            city: CityModel.dhakaDefault(),
            date: DateTime(2026, 11, 1 + i),
          ),
      ];
    });

    List<PlannedAlarm> plan(NotificationSettings s, {bool fasting = false}) =>
        PrayerAlarmScheduler.planAlarms(
          city: CityModel.dhakaDefault(),
          settings: s,
          days: days,
          isFastingDay: (_) => fasting,
          now: now,
        );

    test('only future alarms within the horizon, unique ids, sorted', () {
      final alarms = plan(const NotificationSettings());
      expect(alarms, isNotEmpty);
      final limit = now.add(const Duration(days: PrayerAlarmScheduler.horizonDays));
      for (final a in alarms) {
        expect(a.fireAt.isAfter(now), isTrue);
        expect(a.fireAt.isAfter(limit), isFalse);
      }
      expect(alarms.map((a) => a.id).toSet().length, alarms.length);
      for (var i = 1; i < alarms.length; i++) {
        expect(alarms[i].fireAt.isBefore(alarms[i - 1].fireAt), isFalse);
      }
      // Today's Fajr/Dhuhr (before noon) were skipped; Asr kept.
      expect(alarms.any((a) => a.id == 1 || a.id == 2), isFalse);
      expect(alarms.any((a) => a.id == 3), isTrue);
    });

    test('fires at the real instant of the Dhaka wall time', () {
      final asr = plan(const NotificationSettings()).firstWhere((a) => a.id == 3);
      expect(asr.fireAt, CityClock.toInstant(days[0].asr, 'Asia/Dhaka'));
    });

    test('Sehri/Iftar reminders only on fasting days', () {
      bool hasFasting(List<PlannedAlarm> a) =>
          a.any((x) => x.id % 100 == 9 || x.id % 100 == 10);
      expect(hasFasting(plan(const NotificationSettings())), isFalse);
      expect(hasFasting(plan(const NotificationSettings(), fasting: true)), isTrue);
    });

    test('a tone set to off is not scheduled; master off schedules nothing', () {
      final s = const NotificationSettings()
          .copyWith(asrTone: NotificationAlarmTone.off);
      expect(plan(s).any((a) => a.id % 100 == 3), isFalse);
      expect(plan(s.copyWith(masterEnabled: false)), isEmpty);
    });

    test('advance offset fires early with honest wording', () {
      final s = const NotificationSettings().copyWith(advanceMinutes: 10);
      final asr = plan(s).firstWhere((a) => a.id == 3);
      expect(
        asr.fireAt,
        CityClock.toInstant(days[0].asr, 'Asia/Dhaka')
            .subtract(const Duration(minutes: 10)),
      );
      expect(asr.title, contains('আসন্ন'));
      expect(asr.body, contains('মিনিট পর'));
    });

    test('Maghrib says "ইফতার" only on fasting days', () {
      final normal =
          plan(const NotificationSettings()).firstWhere((a) => a.id == 4);
      final fasting = plan(const NotificationSettings(), fasting: true)
          .firstWhere((a) => a.id == 4);
      expect(normal.title, isNot(contains('ইফতার')));
      expect(fasting.title, contains('ইফতার'));
    });
  });

  group('Widget payload', () {
    test('contiguous days with 5 fard prayers as epoch instants', () async {
      final days = [
        for (var i = 0; i < 3; i++)
          await engine.calculateDayPrayers(
            city: CityModel.dhakaDefault(),
            date: DateTime(2026, 11, 1 + i),
          ),
      ];
      final payload = WidgetSyncService.buildPayload(
        city: CityModel.dhakaDefault(),
        days: days,
        hijriLabel: (_) => 'hijri',
      );
      final out = payload['days'] as List;
      expect(out, hasLength(3));
      for (var i = 0; i < out.length; i++) {
        final d = out[i] as Map;
        expect((d['prayers'] as List), hasLength(5));
        if (i > 0) expect(d['start'], (out[i - 1] as Map)['end']);
      }
      final first = out.first as Map;
      // Day starts at Dhaka midnight = 18:00 UTC the previous day.
      expect(
        DateTime.fromMillisecondsSinceEpoch(first['start'] as int, isUtc: true),
        DateTime.utc(2026, 10, 31, 18),
      );
    });
  });

  group('City time zone selection', () {
    test('multi-zone countries pick the zone nearest the solar offset', () {
      final zones = [
        {'znm': 'America/New_York', 'gmtOffset': -18000},
        {'znm': 'America/Chicago', 'gmtOffset': -21600},
        {'znm': 'America/Los_Angeles', 'gmtOffset': -28800},
      ];
      expect(pickZoneForCity(zones, -74.0), 'America/New_York');
      expect(pickZoneForCity(zones, -118.2), 'America/Los_Angeles');
      expect(pickZoneForCity(zones, -87.6), 'America/Chicago');
      expect(pickZoneForCity([{'znm': 'Asia/Dhaka', 'gmtOffset': 21600}], 0),
          'Asia/Dhaka');
    });

    test('legacy saved city without zone defaults sensibly', () {
      final bd = CityModel.fromJson({
        'id': 8486,
        'name': 'Dhaka',
        'countryName': 'Bangladesh',
        'latitude': 23.7,
        'longitude': 90.4,
      });
      expect(bd.effectiveTimeZone, 'Asia/Dhaka');
    });
  });
}
