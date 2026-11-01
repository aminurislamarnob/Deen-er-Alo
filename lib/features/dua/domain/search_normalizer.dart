/// Text helpers for search across Dua / Names content.
class SearchNormalizer {
  SearchNormalizer._();

  // Harakat / tashkeel (U+064B–U+065F), superscript alef (U+0670) and
  // tatweel (U+0640).
  static final RegExp _arabicDiacritics = RegExp(
    r'[\u064B-\u065F\u0670\u0640]',
  );
  // Alef variants: أ (U+0623), إ (U+0625), آ (U+0622), ٱ (U+0671).
  static final RegExp _alefVariants = RegExp(r'[\u0623\u0625\u0622\u0671]');
  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _htmlTag = RegExp(r'<[^>]*>');
  static final RegExp _lineBreakTag = RegExp(
    r'<br\s*/?>',
    caseSensitive: false,
  );
  static final RegExp _paragraphEnd = RegExp(r'</p>', caseSensitive: false);
  static final RegExp _manyNewlines = RegExp(r'\n{3,}');

  static const List<String> _bengaliDigits = [
    '০',
    '১',
    '২',
    '৩',
    '৪',
    '৫',
    '৬',
    '৭',
    '৮',
    '৯',
  ];

  /// Converts HTML content to readable plain text (tags removed, common
  /// entities decoded, paragraph breaks kept).
  static String htmlToPlainText(String html) {
    var text = html
        .replaceAll(_lineBreakTag, '\n')
        .replaceAll(_paragraphEnd, '\n\n')
        .replaceAll(_htmlTag, '')
        .replaceAll('&#039;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .trim();
    return text.replaceAll(_manyNewlines, '\n\n');
  }

  /// Strips Arabic diacritics/tatweel and unifies alef variants.
  static String normalizeArabic(String input) {
    return input
        .replaceAll(_arabicDiacritics, '')
        .replaceAll(_alefVariants, '\u0627');
  }

  /// Converts Bengali digits (০-৯) to ASCII digits.
  static String bengaliDigitsToAscii(String input) {
    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      final i = _bengaliDigits.indexOf(ch);
      buffer.write(i >= 0 ? '$i' : ch);
    }
    return buffer.toString();
  }

  /// Normalization applied to both the query and the searchable text:
  /// lower-case, Arabic-normalized and whitespace-collapsed.
  static String normalize(String input) {
    return normalizeArabic(
      input.toLowerCase(),
    ).replaceAll(_whitespace, ' ').trim();
  }

  /// Returns true when [normalizedQuery] (already passed through [normalize])
  /// occurs in any of [fields].
  static bool matchesAny(String normalizedQuery, Iterable<String> fields) {
    if (normalizedQuery.isEmpty) return true;
    for (final field in fields) {
      if (normalize(field).contains(normalizedQuery)) return true;
    }
    return false;
  }
}
