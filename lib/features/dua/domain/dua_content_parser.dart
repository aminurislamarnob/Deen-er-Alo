import 'search_normalizer.dart';

/// Kind of a rendered block inside a dua's content.
enum DuaBlockKind {
  /// Sub-heading inside a dua (`<h2>`–`<h4>`).
  heading,

  /// Arabic text: Quran, hadith or other Arabic supplication.
  arabic,

  /// Narrator chain (`class="sanad"`).
  narrator,

  /// Ordinary Bengali text: translation, transliteration, explanation.
  body,

  /// Source reference (`class="reference"`).
  reference,
}

class DuaBlock {
  final DuaBlockKind kind;
  final String text;

  const DuaBlock(this.kind, this.text);

  @override
  String toString() => 'DuaBlock(${kind.name}, $text)';
}

/// Splits a dua's HTML (from `assets/data/dua.json`) into typed blocks so the
/// UI can render Arabic right-to-left in the Arabic font, and style headings,
/// narrators and references distinctly.
///
/// Paragraph classes are only hints: a paragraph is treated as Arabic when it
/// contains Arabic letters and no Bengali letters (one `class="hadith"`
/// paragraph in the data is actually Bengali).
class DuaContentParser {
  DuaContentParser._();

  static final RegExp _block = RegExp(
    r'<(p|h2|h3|h4)(?:\s+class="([^"]*)")?[^>]*>(.*?)</\1\s*>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _arabicLetter = RegExp(r'[؀-ۿݐ-ݿ]');
  static final RegExp _bengaliLetter = RegExp(r'[ঀ-৿]');

  static bool _isArabicOnly(String text) =>
      _arabicLetter.hasMatch(text) && !_bengaliLetter.hasMatch(text);

  static List<DuaBlock> parse(String html) {
    final blocks = <DuaBlock>[];
    var cursor = 0;

    void addLoose(String fragment) {
      final text = SearchNormalizer.htmlToPlainText(fragment);
      if (text.isNotEmpty) blocks.add(_classify(null, null, text));
    }

    for (final m in _block.allMatches(html)) {
      // Any text between recognised blocks is kept, never dropped.
      if (m.start > cursor) addLoose(html.substring(cursor, m.start));
      cursor = m.end;

      final text = SearchNormalizer.htmlToPlainText(m.group(3) ?? '');
      if (text.isEmpty) continue;
      blocks.add(_classify(m.group(1)!.toLowerCase(), m.group(2), text));
    }
    if (cursor < html.length) addLoose(html.substring(cursor));
    return blocks;
  }

  static DuaBlock _classify(String? tag, String? cssClass, String text) {
    if (tag != null && tag.startsWith('h')) {
      return DuaBlock(DuaBlockKind.heading, text);
    }
    switch (cssClass) {
      case 'reference':
        return DuaBlock(DuaBlockKind.reference, text);
      case 'sanad':
        return DuaBlock(DuaBlockKind.narrator, text);
    }
    if (_isArabicOnly(text)) return DuaBlock(DuaBlockKind.arabic, text);
    return DuaBlock(DuaBlockKind.body, text);
  }
}
