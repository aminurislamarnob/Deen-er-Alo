import 'package:deener_alo/features/calendar/data/islamic_events_repository.dart';
import 'package:deener_alo/features/calendar/domain/hijri_utils.dart';
import 'package:deener_alo/features/calendar/presentation/calendar_screen.dart';
import 'package:deener_alo/features/calendar/presentation/hijri_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('hijriForDate', () {
    test('+1 offset shifts exactly one day vs 0', () {
      for (final d in [
        DateTime(2026, 3, 20),
        DateTime(2026, 11, 1),
        DateTime(2025, 12, 31),
      ]) {
        final base = hijriForDate(d, 0);
        final plus = hijriForDate(d, 1);
        final next = hijriForDate(addDays(d, 1), 0);
        expect(
          [plus.hYear, plus.hMonth, plus.hDay],
          [next.hYear, next.hMonth, next.hDay],
        );
        final gBase = base.hijriToGregorian(base.hYear, base.hMonth, base.hDay);
        final gPlus = plus.hijriToGregorian(plus.hYear, plus.hMonth, plus.hDay);
        expect(
          DateTime.utc(
            gPlus.year,
            gPlus.month,
            gPlus.day,
          ).difference(DateTime.utc(gBase.year, gBase.month, gBase.day)).inDays,
          1,
        );
      }
    });

    test('gregorianForHijri is the inverse of hijriForDate', () {
      for (final offset in [-2, -1, 0, 1, 2]) {
        final g = gregorianForHijri(1448, 9, 1, offset);
        final h = hijriForDate(g, offset);
        expect([h.hYear, h.hMonth, h.hDay], [1448, 9, 1]);
      }
    });
  });

  group('Akhiri Chahar Shomba (last Wednesday of Safar)', () {
    test('known date: 1447 AH → 20 Aug 2025', () {
      expect(lastWednesdayOfSafar(1447, 0), DateTime(2025, 8, 20));
    });

    for (final year in [1446, 1447, 1448, 1449, 1450]) {
      for (final offset in [-1, 0, 1]) {
        test('$year AH offset $offset is the last Wednesday in Safar', () {
          final d = lastWednesdayOfSafar(year, offset);
          expect(d.weekday, DateTime.wednesday);
          expect(hijriForDate(d, offset).hMonth, 2);
          expect(hijriForDate(addDays(d, 7), offset).hMonth, isNot(2));
          expect(isAkhiriChaharShomba(d, offset), isTrue);
          expect(isAkhiriChaharShomba(addDays(d, -7), offset), isFalse);
        });
      }
    }

    test('event lookup uses the computed date, not a fixed 28 Safar', () {
      final repo = IslamicEventsRepository();
      final d = lastWednesdayOfSafar(1448, 0);
      expect(
        repo
            .getEventsForDate(d, 0)
            .any(
              (e) =>
                  e.titleBn ==
                  IslamicEventsRepository.akhiriChaharShombaTitleBn,
            ),
        isTrue,
      );
      expect(
        repo
            .getEventsForHijriDate(2, 28)
            .any(
              (e) =>
                  e.titleBn ==
                  IslamicEventsRepository.akhiriChaharShombaTitleBn,
            ),
        isFalse,
      );
    });
  });

  group('Events', () {
    final repo = IslamicEventsRepository();
    test('Tashreeq covers 11, 12 and 13 Dhul Hijjah', () {
      for (final day in [11, 12, 13]) {
        expect(
          repo
              .getEventsForHijriDate(12, day)
              .any((e) => e.titleBn.contains('তাশরীক')),
          isTrue,
          reason: 'day $day',
        );
      }
      // No Ayyam al-Beed fast on 13 Dhul Hijjah.
      expect(
        repo.getEventsForHijriDate(12, 13).any((e) => e.isAyyamBeed),
        isFalse,
      );
      expect(
        repo.getEventsForHijriDate(2, 14).any((e) => e.isAyyamBeed),
        isTrue,
      );
    });
  });

  group('Header range', () {
    test('shows both Hijri months when the Gregorian month spans two', () {
      final label = CalendarScreen.hijriRangeLabel(DateTime(2026, 11, 1), 0);
      final first = hijriForDate(DateTime(2026, 11, 1), 0);
      final last = hijriForDate(DateTime(2026, 11, 30), 0);
      expect(first.hMonth, isNot(last.hMonth));
      expect(label.contains('–'), isTrue);
    });
  });

  group('hijriTodayProvider', () {
    test('applies and follows the saved moon offset', () async {
      SharedPreferences.setMockInitialValues({'deener_alo_moon_offset_v1': 1});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(hijriTodayProvider, (_, __) {});
      await container.read(moonOffsetProvider.notifier).ready;
      final today = dateOnly(DateTime.now());
      final expected = hijriForDate(today, 1);
      final actual = container.read(hijriTodayProvider);
      expect(
        [actual.hYear, actual.hMonth, actual.hDay],
        [expected.hYear, expected.hMonth, expected.hDay],
      );

      await container.read(moonOffsetProvider.notifier).setOffset(-1);
      final after = container.read(hijriTodayProvider);
      final exp2 = hijriForDate(today, -1);
      expect(
        [after.hYear, after.hMonth, after.hDay],
        [exp2.hYear, exp2.hMonth, exp2.hDay],
      );
    });

    test(
      'setOffset before load does not get overwritten by the load',
      () async {
        SharedPreferences.setMockInitialValues({
          'deener_alo_moon_offset_v1': 2,
        });
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(moonOffsetProvider.notifier).setOffset(-1);
        expect(container.read(moonOffsetProvider), -1);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('deener_alo_moon_offset_v1'), -1);
      },
    );
  });
}
