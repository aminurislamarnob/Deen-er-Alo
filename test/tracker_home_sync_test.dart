import 'dart:convert';

import 'package:deener_alo/features/calendar/domain/hijri_utils.dart';
import 'package:deener_alo/features/home/presentation/fasting_provider.dart';
import 'package:deener_alo/features/home/presentation/prayer_tracker_provider.dart';
import 'package:deener_alo/features/prayer_times/domain/prayer_model.dart';
import 'package:deener_alo/features/tracker/data/habit_repository.dart';
import 'package:deener_alo/features/tracker/domain/habit_models.dart';
import 'package:deener_alo/features/tracker/presentation/habit_tracker_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime today;
  late String habitKey;

  setUp(() {
    today = dateOnly(DateTime.now());
    habitKey = 'deener_alo_habit_${HabitRepository.dateKey(today)}';
  });

  Future<DailyHabitRecord> stored() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(habitKey);
    return DailyHabitRecord.fromJson(json.decode(raw!) as Map<String, dynamic>);
  }

  Future<ProviderContainer> start() async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(prayerTrackerProvider, (_, __) {});
    container.listen(fastingProvider, (_, __) {});
    await container.read(habitRecordProvider(today).notifier).ready;
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  test(
    'home toggle writes "alone" to the habit record and back to none',
    () async {
      SharedPreferences.setMockInitialValues({});
      final c = await start();

      await c.read(prayerTrackerProvider.notifier).togglePrayer(PrayerType.asr);
      expect(c.read(prayerTrackerProvider)[PrayerType.asr], isTrue);
      expect((await stored()).prayers[PrayerType.asr], PrayerStatus.alone);
      expect(
        c.read(habitRecordProvider(today)).value!.prayers[PrayerType.asr],
        PrayerStatus.alone,
      );

      await c.read(prayerTrackerProvider.notifier).togglePrayer(PrayerType.asr);
      expect(c.read(prayerTrackerProvider)[PrayerType.asr], isFalse);
      expect((await stored()).prayers[PrayerType.asr], PrayerStatus.none);
    },
  );

  test('tracker changes are reflected on the home tracker', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await start();
    final record = c.read(habitRecordProvider(today).notifier);

    await record.setPrayerStatus(PrayerType.fajr, PrayerStatus.jamaat);
    await record.setPrayerStatus(PrayerType.isha, PrayerStatus.qaza);
    await record.setPrayerStatus(PrayerType.dhuhr, PrayerStatus.notOffered);
    final home = c.read(prayerTrackerProvider);
    expect(home[PrayerType.fajr], isTrue);
    expect(home[PrayerType.isha], isTrue); // made up counts as done
    expect(home[PrayerType.dhuhr], isFalse);

    // Toggling a "jama'at" prayer off on home clears it.
    await c.read(prayerTrackerProvider.notifier).togglePrayer(PrayerType.fajr);
    expect(record.state.value!.prayers[PrayerType.fajr], PrayerStatus.none);

    // Toggling a missed prayer on home makes it "alone" and reduces qaza.
    expect(c.read(qazaCounterProvider), 1);
    await c.read(prayerTrackerProvider.notifier).togglePrayer(PrayerType.dhuhr);
    expect(record.state.value!.prayers[PrayerType.dhuhr], PrayerStatus.alone);
    expect(c.read(qazaCounterProvider), 0);
  });

  test('legacy home keys for today are migrated once and removed', () async {
    final legacyFajr = HabitRepository.legacyPrayerKey(today, 'fajr');
    final legacyAsr = HabitRepository.legacyPrayerKey(today, 'asr');
    SharedPreferences.setMockInitialValues({
      legacyFajr: true,
      legacyAsr: false,
    });
    final c = await start();

    expect(c.read(prayerTrackerProvider)[PrayerType.fajr], isTrue);
    expect(c.read(prayerTrackerProvider)[PrayerType.asr], isFalse);
    expect((await stored()).prayers[PrayerType.fajr], PrayerStatus.alone);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(legacyFajr), isFalse);
    expect(prefs.containsKey(legacyAsr), isFalse);
  });

  test('home fasting toggle is backed by the habit record', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await start();
    expect(c.read(fastingProvider).isFastToday, isFalse);

    await c.read(fastingProvider.notifier).toggleTodayFast();
    expect(c.read(fastingProvider).isFastToday, isTrue);
    expect(c.read(fastingProvider).completedDays, 1);
    final fasting = (await stored()).fasting;
    expect(
      fasting == FastingStatus.nafl || fasting == FastingStatus.ramadanFarz,
      isTrue,
    );

    await c.read(fastingProvider.notifier).toggleTodayFast();
    expect(c.read(fastingProvider).isFastToday, isFalse);
    expect((await stored()).fasting, FastingStatus.notFasting);

    // Tracker → home.
    await c
        .read(habitRecordProvider(today).notifier)
        .setFastingStatus(FastingStatus.qaza);
    expect(c.read(fastingProvider).isFastToday, isTrue);
  });

  test('future days cannot be logged', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final tomorrow = addDays(today, 1);
    final p = habitRecordProvider(tomorrow);
    c.listen(p, (_, __) {});
    final n = c.read(p.notifier);
    await n.ready;
    await n.setPrayerStatus(PrayerType.fajr, PrayerStatus.jamaat);
    expect(c.read(p).value!.prayers[PrayerType.fajr], PrayerStatus.none);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.containsKey(
        'deener_alo_habit_${HabitRepository.dateKey(tomorrow)}',
      ),
      isFalse,
    );
  });
}
