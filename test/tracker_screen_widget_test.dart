import 'package:deener_alo/features/tracker/presentation/tracker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'TrackerScreen renders at text scale 1.3; next-day disabled on today',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(360, 2600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: const TrackerScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ফজর (Fajr)'), findsOneWidget);
      expect(find.text('আজ'), findsOneWidget);
      expect(tester.takeException(), isNull);

      IconButton nextButton() => tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, LucideIcons.chevronRight),
      );
      expect(nextButton().onPressed, isNull);

      await tester.tap(
        find.widgetWithIcon(IconButton, LucideIcons.chevronLeft),
      );
      await tester.pumpAndSettle();
      expect(find.text('আজ'), findsNothing);
      expect(nextButton().onPressed, isNotNull);

      await tester.tap(
        find.widgetWithIcon(IconButton, LucideIcons.chevronRight),
      );
      await tester.pumpAndSettle();
      expect(find.text('আজ'), findsOneWidget);
      expect(nextButton().onPressed, isNull);

      // Backlog calculator opens.
      await tester.scrollUntilVisible(
        find.byIcon(LucideIcons.calculator),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byIcon(LucideIcons.calculator));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(LucideIcons.calculator));
      await tester.pumpAndSettle();
      expect(find.byType(QazaBacklogSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
