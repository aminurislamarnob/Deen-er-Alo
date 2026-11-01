import 'package:deener_alo/features/calendar/presentation/calendar_providers.dart';
import 'package:deener_alo/features/calendar/presentation/calendar_screen.dart';
import 'package:deener_alo/features/prayer_times/domain/prayer_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'CalendarScreen renders at text scale 1.3 and selection follows month',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(360, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer(
        overrides: [
          calendarDayPrayersProvider.overrideWith(
            (ref) async => null as DayPrayerTimes?,
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: const CalendarScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('প্রধান দিবস'), findsOneWidget); // legend

      final now = DateTime.now();
      expect(
        container.read(selectedCalendarDateProvider),
        DateTime(now.year, now.month, now.day),
      );

      await tester.tap(
        find.widgetWithIcon(IconButton, LucideIcons.chevronRight),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(selectedCalendarDateProvider),
        DateTime(now.year, now.month + 1, 1),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.widgetWithIcon(IconButton, LucideIcons.chevronLeft),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(selectedCalendarDateProvider),
        DateTime(now.year, now.month, now.day),
      );

      // Scroll through the events list (Gregorian dates shown) without errors.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Dispose before the binding checks for pending timers (midnight ticker).
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    },
  );
}
