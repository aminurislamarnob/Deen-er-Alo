import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deener_alo/features/dua/domain/dua_search.dart';
import 'package:deener_alo/features/dua/domain/search_normalizer.dart';
import 'package:deener_alo/features/dua/presentation/dua_bookmark_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SearchNormalizer', () {
    test('strips harakat, superscript alef and tatweel', () {
      expect(SearchNormalizer.normalizeArabic('اَللّٰهُمَّ'), 'اللهم');
      expect(SearchNormalizer.normalizeArabic('الرَّحْمَـٰنُ'), 'الرحمن');
    });

    test('unifies alef variants', () {
      expect(SearchNormalizer.normalizeArabic('أإآٱ'), 'اااا');
      expect(SearchNormalizer.normalize('أَكْبَرُ'), 'اكبر');
    });

    test('htmlToPlainText removes tags and decodes entities', () {
      expect(
        SearchNormalizer.htmlToPlainText(
          '<p class="sanad">A &amp; B</p><p>দু&#039;আ<br/>x</p>',
        ),
        "A & B\n\nদু'আ\nx",
      );
    });

    test('bengaliDigitsToAscii', () {
      expect(SearchNormalizer.bengaliDigitsToAscii('১২'), '12');
      expect(SearchNormalizer.bengaliDigitsToAscii('৯৯ ab'), '99 ab');
    });
  });

  group('DuaSearchIndex', () {
    final items = <Map<String, dynamic>>[
      {
        'id': 1,
        'title': 'আজানের দুআ',
        'subtitle': '',
        'content':
            '<p class="hadith">اَللّٰهُمَّ رَبَّ هٰذِهِ الدَّعْوَةِ التَّامَّةِ</p>',
      },
      {
        'id': 2,
        'title': 'Morning',
        'subtitle': 'Sabah',
        'content':
            '<p class="sanad">أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ</p>',
      },
    ];
    final index = DuaSearchIndex(items);

    test('HTML markup is not searchable', () {
      expect(index.search('class'), isEmpty);
      expect(index.search('hadith'), isEmpty);
      expect(index.search('<p'), isEmpty);
    });

    test('Arabic search ignores harakat and alef variants', () {
      expect(index.search('الدعوة').map((d) => d['id']), [1]);
      expect(index.search('اللهم').map((d) => d['id']), [1]);
      expect(index.search('اصبحنا').map((d) => d['id']), [2]);
    });

    test('case-insensitive title/subtitle matching and empty query', () {
      expect(index.search('MORNING').map((d) => d['id']), [2]);
      expect(index.search('sabah').map((d) => d['id']), [2]);
      expect(index.search('আজানের').map((d) => d['id']), [1]);
      expect(index.search('  ').length, 2);
    });

    test('real dua.json: "class" no longer matches every entry', () {
      final data =
          json.decode(File('assets/data/dua.json').readAsStringSync())
              as List<dynamic>;
      final all = <Map<String, dynamic>>[
        for (final cat in data)
          for (final item in (cat['contentList'] as List<dynamic>))
            item as Map<String, dynamic>,
      ];
      final realIndex = DuaSearchIndex(all);
      expect(realIndex.search('class'), isEmpty);
      expect(realIndex.search('الدعوة'), isNotEmpty);
    });
  });

  group('DuaBookmarkNotifier load race', () {
    test('toggle before load merges with stored bookmarks', () async {
      SharedPreferences.setMockInitialValues({
        DuaBookmarkNotifier.keyBookmarks: ['1', '2'],
      });
      final n = DuaBookmarkNotifier();
      n.toggleBookmark(3); // before load completes
      expect(n.isLoaded, isFalse);
      expect(n.isBookmarked(3), isTrue);

      await n.ready;
      expect(n.state, {1, 2, 3});

      await n.pendingWrites;
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(DuaBookmarkNotifier.keyBookmarks)!.toSet(), {
        '1',
        '2',
        '3',
      });
    });

    test(
      'un-bookmarking a stored id before load removes only that id',
      () async {
        SharedPreferences.setMockInitialValues({
          DuaBookmarkNotifier.keyBookmarks: ['1', '2'],
        });
        final n = DuaBookmarkNotifier();
        n.toggleBookmark(2); // user removes a stored bookmark pre-load
        await n.ready;
        expect(n.state, {1});
        await n.pendingWrites;
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getStringList(DuaBookmarkNotifier.keyBookmarks), ['1']);
      },
    );

    test('toggles after load persist', () async {
      SharedPreferences.setMockInitialValues({
        DuaBookmarkNotifier.keyBookmarks: ['5'],
      });
      final n = DuaBookmarkNotifier();
      await n.ready;
      n.toggleBookmark(6);
      await n.pendingWrites;
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(DuaBookmarkNotifier.keyBookmarks)!.toSet(), {
        '5',
        '6',
      });
    });
  });
}
