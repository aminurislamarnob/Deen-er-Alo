import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deener_alo/app/theme/app_fonts.dart';
import 'package:deener_alo/app/theme/app_theme.dart';
import 'package:deener_alo/core/widgets/arabic_text.dart';
import 'package:deener_alo/features/dua/domain/dua_content_parser.dart';
import 'package:deener_alo/features/dua/domain/search_normalizer.dart';

final _arabicLetter = RegExp(r'[؀-ۿݐ-ݿ]');
final _bengaliLetter = RegExp(r'[ঀ-৿]');

int _arabicCount(String s) => _arabicLetter.allMatches(s).length;

void main() {
  group('Bundled fonts', () {
    test('every font declared in pubspec exists and is a TrueType file', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final assets = RegExp(
        r'asset: (assets/fonts/\S+\.ttf)',
      ).allMatches(pubspec).map((m) => m.group(1)!).toList();
      expect(assets, hasLength(12));
      for (final path in assets) {
        final bytes = File(path).readAsBytesSync();
        // TrueType magic number 0x00010000.
        expect(bytes.sublist(0, 4), [0, 1, 0, 0], reason: path);
      }
      for (final family in [AppFonts.ui, AppFonts.bengali, AppFonts.arabic]) {
        expect(pubspec, contains('family: $family'));
      }
    });

    test('OFL licence shipped for each family', () {
      for (final name in ['PlusJakartaSans', 'NotoSansBengali', 'Amiri']) {
        final text = File(
          'assets/fonts/licenses/$name-OFL.txt',
        ).readAsStringSync();
        expect(text, contains('SIL OPEN FONT LICENSE'), reason: name);
      }
    });

    test('no runtime font fetching remains', () {
      expect(
        File('pubspec.yaml').readAsStringSync(),
        isNot(contains('google_fonts')),
      );
      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.readAsStringSync().contains('google_fonts'))
          .map((f) => f.path);
      expect(offenders, isEmpty);
    });

    test('themes use the bundled UI font with Bengali/Arabic fallback', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        for (final style in [
          theme.textTheme.bodyMedium!,
          theme.textTheme.titleLarge!,
          theme.appBarTheme.titleTextStyle!,
        ]) {
          expect(style.fontFamily, AppFonts.ui);
          expect(style.fontFamilyFallback, containsAll(AppFonts.fallback));
        }
      }
    });

    testWidgets('ArabicText renders RTL in the Arabic font', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ArabicText('سُبْحَانَ اللَّهِ')),
        ),
      );
      final text = tester.widget<Text>(find.text('سُبْحَانَ اللَّهِ'));
      expect(text.textDirection, TextDirection.rtl);
      expect(text.style!.fontFamily, AppFonts.arabic);
      expect(text.style!.height, greaterThanOrEqualTo(1.6));
    });
  });

  group('DuaContentParser on the real dua.json', () {
    late List<Map<String, dynamic>> duas;

    setUpAll(() {
      final data =
          json.decode(File('assets/data/dua.json').readAsStringSync()) as List;
      duas = [
        for (final category in data)
          for (final item in (category['contentList'] as List))
            item as Map<String, dynamic>,
      ];
    });

    test('all 130 duas parse into blocks', () {
      expect(duas, hasLength(130));
      for (final dua in duas) {
        expect(
          DuaContentParser.parse(dua['content'] as String),
          isNotEmpty,
          reason: 'id ${dua['id']}',
        );
      }
    });

    test('no Arabic letter is lost, and Arabic blocks are pure Arabic', () {
      var arabicBlocks = 0;
      for (final dua in duas) {
        final html = dua['content'] as String;
        final blocks = DuaContentParser.parse(html);
        final joined = blocks.map((b) => b.text).join('\n');
        expect(
          _arabicCount(joined),
          _arabicCount(SearchNormalizer.htmlToPlainText(html)),
          reason: 'id ${dua['id']}',
        );
        for (final b in blocks.where((b) => b.kind == DuaBlockKind.arabic)) {
          arabicBlocks++;
          expect(_bengaliLetter.hasMatch(b.text), isFalse);
        }
      }
      // 53 quran + 170 Arabic hadith + 1 other_arabic paragraphs.
      expect(arabicBlocks, greaterThanOrEqualTo(220));
    });

    test('classifies headings, narrator, reference and body', () {
      final blocks = DuaContentParser.parse(
        '<h3>শিরোনাম</h3>'
        '<p class="sanad">আবু হুরায়রা (রাঃ) থেকে বর্ণিত</p>'
        '<p class="hadith">اَللّٰهُمَّ اغْفِرْ لِيْ</p>'
        '<p class="hadith">বাংলা অনুবাদ</p>'
        '<p></p>'
        '<p class="reference">বুখারী ১২৩</p>',
      );
      expect(blocks.map((b) => b.kind), [
        DuaBlockKind.heading,
        DuaBlockKind.narrator,
        DuaBlockKind.arabic,
        DuaBlockKind.body, // class says hadith, but the text is Bengali
        DuaBlockKind.reference,
      ]);
    });

    test('text outside block tags is kept', () {
      final blocks = DuaContentParser.parse('আগে<p>মাঝে</p>পরে');
      expect(blocks.map((b) => b.text), ['আগে', 'মাঝে', 'পরে']);
    });
  });

  test('no letterSpacing on Arabic text (it breaks letter joining)', () {
    // Any Dart file that styles Arabic must not use letterSpacing nearby.
    for (final f
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!_arabicLetter.hasMatch(lines[i]) &&
            !lines[i].contains('nameArabic') &&
            !lines[i].contains('arabicText')) {
          continue;
        }
        final window = lines.sublist(i, (i + 12).clamp(0, lines.length));
        expect(
          window.any(
            (l) =>
                l.contains('letterSpacing') && !l.trimLeft().startsWith('//'),
          ),
          isFalse,
          reason: '${f.path}:${i + 1}',
        );
      }
    }
  });
}
