import 'dart:convert';

import 'package:deener_alo/features/calendar/domain/hijri_utils.dart';
import 'package:deener_alo/features/prayer_times/domain/prayer_model.dart';
import 'package:deener_alo/features/tracker/data/habit_repository.dart';
import 'package:deener_alo/features/tracker/domain/habit_models.dart';
import 'package:deener_alo/features/tracker/presentation/habit_tracker_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _key(DateTime d) => 'deener_alo_habit_${HabitRepository.dateKey(d)}';

String _record(DateTime d, List<PrayerStatus> statuses) {
  final rec = DailyHabitRecord.empty(HabitRepository.dateKey(d)).copyWith(
    prayers: {
      for (int i = 0; i < fardPrayerTypes.length; i++)
        fardPrayerTypes[i]: statuses[i],
    },
  );
  return json.encode(rec.toJson());
}

const _allPrayed = [
  PrayerStatus.jamaat,
  PrayerStatus.alone,
  PrayerStatus.qaza, // made up still counts
  PrayerStatus.jamaat,
  PrayerStatus.alone,
];

const _fourPrayed = [
  PrayerStatus.jamaat,
  PrayerStatus.alone,
  PrayerStatus.jamaat,
  PrayerStatus.jamaat,
  PrayerStatus.none,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime(2026, 11, 1);
  final repo = HabitRepository();

  group('Streak rules', () {
    test(
      'counts consecutive complete days; incomplete today does not break',
      () async {
        SharedPreferences.setMockInitialValues({
          _key(today): _record(today, _fourPrayed), // today in progress
          _key(addDays(today, -1)): _record(addDays(today, -1), _allPrayed),
          _key(addDays(today, -2)): _record(addDays(today, -2), _allPrayed),
          _key(addDays(today, -3)): _record(addDays(today, -3), _allPrayed),
          _key(addDays(today, -4)): _record(addDays(today, -4), _fourPrayed),
          _key(addDays(today, -5)): _record(addDays(today, -5), _allPrayed),
        });
        final s = await repo.getStreakSummary(now: today);
        expect(s.streakDays, 3);
      },
    );

    test('complete today is included in the streak', () async {
      SharedPreferences.setMockInitialValues({
        _key(today): _record(today, _allPrayed),
        _key(addDays(today, -1)): _record(addDays(today, -1), _allPrayed),
      });
      final s = await repo.getStreakSummary(now: today);
      expect(s.streakDays, 2);
    });

    test('a day with only 4 of 5 prayers breaks the streak', () async {
      SharedPreferences.setMockInitialValues({
        _key(addDays(today, -1)): _record(addDays(today, -1), _fourPrayed),
        _key(addDays(today, -2)): _record(addDays(today, -2), _allPrayed),
      });
      final s = await repo.getStreakSummary(now: today);
      expect(s.streakDays, 0);
    });

    test('missed status does not count as prayed', () async {
      SharedPreferences.setMockInitialValues({
        _key(addDays(today, -1)): _record(addDays(today, -1), [
          PrayerStatus.jamaat,
          PrayerStatus.jamaat,
          PrayerStatus.jamaat,
          PrayerStatus.jamaat,
          PrayerStatus.notOffered,
        ]),
      });
      final s = await repo.getStreakSummary(now: today);
      expect(s.streakDays, 0);
    });

    test(
      'corrupted record for today is skipped, not zeroing the streak',
      () async {
        SharedPreferences.setMockInitialValues({
          _key(today): '{not valid json',
          _key(addDays(today, -1)): _record(addDays(today, -1), _allPrayed),
          _key(addDays(today, -2)): _record(addDays(today, -2), _allPrayed),
        });
        final s = await repo.getStreakSummary(now: today);
        expect(s.streakDays, 2);
      },
    );

    test('streak is not capped at 60 days', () async {
      final values = <String, Object>{};
      for (int i = 1; i <= 100; i++) {
        final d = addDays(today, -i);
        values[_key(d)] = _record(d, _allPrayed);
      }
      SharedPreferences.setMockInitialValues(values);
      final s = await repo.getStreakSummary(now: today);
      expect(s.streakDays, 100);
    });

    test('streak walk crosses month and DST-free date arithmetic', () async {
      final march1 = DateTime(2026, 3, 1);
      SharedPreferences.setMockInitialValues({
        _key(DateTime(2026, 2, 28)): _record(DateTime(2026, 2, 28), _allPrayed),
        _key(DateTime(2026, 2, 27)): _record(DateTime(2026, 2, 27), _allPrayed),
      });
      final s = await repo.getStreakSummary(now: march1);
      expect(s.streakDays, 2);
    });

    test('legacy v1 records treat notOffered as "not logged"', () {
      final rec = DailyHabitRecord.fromJson({
        'dateStr': '2026-10-01',
        'prayers': {'fajr': 'notOffered', 'dhuhr': 'alone'},
      });
      expect(rec.prayers[PrayerType.fajr], PrayerStatus.none);
      expect(rec.prayers[PrayerType.dhuhr], PrayerStatus.alone);
      final v2 = DailyHabitRecord.fromJson(
        rec
            .copyWith(
              prayers: {
                ...rec.prayers,
                PrayerType.fajr: PrayerStatus.notOffered,
              },
            )
            .toJson(),
      );
      expect(v2.prayers[PrayerType.fajr], PrayerStatus.notOffered);
    });
  });

  group('Qaza delta', () {
    test('pure transitions', () {
      expect(qazaDeltaFor(PrayerStatus.none, PrayerStatus.notOffered), 1);
      expect(qazaDeltaFor(PrayerStatus.notOffered, PrayerStatus.qaza), -1);
      expect(qazaDeltaFor(PrayerStatus.qaza, PrayerStatus.notOffered), 1);
      expect(qazaDeltaFor(PrayerStatus.notOffered, PrayerStatus.alone), -1);
      expect(qazaDeltaFor(PrayerStatus.notOffered, PrayerStatus.none), -1);
      expect(qazaDeltaFor(PrayerStatus.none, PrayerStatus.qaza), 0);
      expect(qazaDeltaFor(PrayerStatus.alone, PrayerStatus.jamaat), 0);
      expect(qazaDeltaFor(PrayerStatus.notOffered, PrayerStatus.notOffered), 0);
    });

    test(
      'none→missed→qaza→missed→solo via notifier never double counts',
      () async {
        SharedPreferences.setMockInitialValues({'deener_alo_qaza_balance': 10});
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final day = dateOnly(DateTime.now());
        final provider = habitRecordProvider(day);
        container.listen(provider, (_, __) {});
        final notifier = container.read(provider.notifier);
        final qaza = container.read(qazaCounterProvider.notifier);
        await qaza.ready;

        Future<int> step(PrayerStatus s) async {
          await notifier.setPrayerStatus(PrayerType.fajr, s);
          final prefs = await SharedPreferences.getInstance();
          expect(
            prefs.getInt('deener_alo_qaza_balance'),
            container.read(qazaCounterProvider),
          );
          return container.read(qazaCounterProvider);
        }

        expect(await step(PrayerStatus.notOffered), 11);
        expect(await step(PrayerStatus.notOffered), 11); // same status: no-op
        expect(await step(PrayerStatus.qaza), 10);
        expect(await step(PrayerStatus.notOffered), 11);
        expect(await step(PrayerStatus.alone), 10);
        expect(await step(PrayerStatus.none), 10);
      },
    );

    test(
      'tap before load waits for saved balance instead of overwriting it',
      () async {
        SharedPreferences.setMockInitialValues({'deener_alo_qaza_balance': 42});
        final container = ProviderContainer();
        addTearDown(container.dispose);
        // Increment immediately, before the async load has completed.
        await container.read(qazaCounterProvider.notifier).increment();
        expect(container.read(qazaCounterProvider), 43);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('deener_alo_qaza_balance'), 43);
      },
    );

    test('backlog calculator', () {
      expect(qazaBacklogPrayers(years: 1), 365 * 5);
      expect(qazaBacklogPrayers(months: 2, days: 3), 63 * 5);
      expect(qazaBacklogPrayers(), 0);
    });

    test('addBacklog adds to the balance', () async {
      SharedPreferences.setMockInitialValues({'deener_alo_qaza_balance': 5});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(qazaCounterProvider.notifier)
          .addBacklog(qazaBacklogPrayers(days: 2));
      expect(container.read(qazaCounterProvider), 15);
    });
  });
}
