import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deener_alo/features/home/presentation/ramadan_checklist_screen.dart';
import 'package:deener_alo/features/prayer_times/presentation/prayer_providers.dart';

void main() {
  testWidgets('RamadanChecklistScreen renders properly', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));

    await tester.pumpWidget(
      ProviderScope(
        // Pin the clock: deterministic, and no periodic timer left pending.
        overrides: [
          clockStreamProvider.overrideWith(
            (ref) => Stream.value(DateTime(2026, 11, 1, 10)),
          ),
        ],
        child: const MaterialApp(home: RamadanChecklistScreen()),
      ),
    );

    await tester.pump();

    // Verify key titles and CTA button from the mockup
    expect(find.text('Ramadan Activity'), findsOneWidget);
    expect(find.text('رَمَضَان كَرِيم'), findsOneWidget);
    expect(find.text('Explore Now'), findsOneWidget);
  });
}
