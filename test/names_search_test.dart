import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deener_alo/features/names/data/names_repository.dart';
import 'package:deener_alo/features/names/domain/allah_name_model.dart';
import 'package:deener_alo/features/names/presentation/names_provider.dart';
import 'package:deener_alo/features/names/presentation/names_screen.dart';

List<AllahName> _sample() => [
  for (var i = 1; i <= 14; i++)
    AllahName(
      id: i,
      nameArabic: i == 2
          ? 'الرَّحْمَنُ'
          : i == 12
          ? 'الْبَارِئُ'
          : i == 9
          ? 'الْجَبَّارُ'
          : 'الْمَلِكُ',
      transliteration: i == 2 ? 'Ar-Rahman' : 'Name $i',
      pronunciationBn: i == 2 ? 'আর-রহমান' : 'নাম',
      meaningEn: 'Meaning',
      meaningBn: 'একটি বেশ লম্বা বাংলা অর্থ যা দুই লাইনে ভাঙতে পারে',
      description: 'desc',
    ),
];

void main() {
  group('NamesRepository.searchNames normalization', () {
    final repo = NamesRepository();
    final names = _sample();

    test('Arabic query without harakat matches vocalized name', () {
      expect(repo.searchNames(names, 'الرحمن').map((n) => n.id), [2]);
      expect(repo.searchNames(names, 'البارئ').map((n) => n.id), [12]);
    });

    test('Bengali-digit number search matches id', () {
      expect(repo.searchNames(names, '১২').map((n) => n.id), [12]);
      expect(repo.searchNames(names, '12').map((n) => n.id), [12]);
      expect(repo.searchNames(names, '২').map((n) => n.id), [2]);
    });
  });

  group('namesSearchQueryProvider', () {
    test('is autoDispose: query resets when no longer listened', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sub = container.listen(namesSearchQueryProvider, (_, __) {});
      container.read(namesSearchQueryProvider.notifier).state = 'রহমান';
      expect(container.read(namesSearchQueryProvider), 'রহমান');

      sub.close();
      await container.pump();
      expect(container.read(namesSearchQueryProvider), '');
    });
  });

  testWidgets('names grid does not overflow at text scale 1.3 on 320dp', (
    tester,
  ) async {
    const size = Size(320, 640);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final sample = _sample();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [allNamesProvider.overrideWith((ref) async => sample)],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(1.3),
            ),
            child: NamesScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('আর-রহমান'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
