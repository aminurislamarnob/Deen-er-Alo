import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deener_alo/features/tasbeeh/presentation/tasbeeh_screen.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    required Size size,
    double textScale = 1.0,
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: const TasbeehScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> unmount(WidgetTester tester) async {
    // Dispose the ProviderScope so the debounce timer is cancelled/flushed.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('no overflow on a small screen at text scale 1.3', (
    tester,
  ) async {
    await pumpScreen(tester, size: const Size(320, 568), textScale: 1.3);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('counter exposes button semantics with count/target', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, size: const Size(400, 800));

    expect(
      find.bySemanticsLabel(RegExp(r'^তাসবীহ গণনা, ০/৩৩')),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel(RegExp(r'^তাসবীহ গণনা')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.bySemanticsLabel(RegExp(r'^তাসবীহ গণনা, ১/৩৩')),
      findsOneWidget,
    );

    // Target pills meet the 48dp minimum tap target.
    final pill = find.bySemanticsLabel('লক্ষ্য ৯৯');
    expect(pill, findsOneWidget);
    final pillSize = tester.getSize(pill);
    expect(pillSize.height, greaterThanOrEqualTo(48));
    expect(pillSize.width, greaterThanOrEqualTo(48));

    handle.dispose();
    await unmount(tester);
  });
}
