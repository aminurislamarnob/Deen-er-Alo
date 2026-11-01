import 'search_normalizer.dart';

/// Pre-normalized search index over dua entries so searching doesn't run on
/// raw HTML (e.g. a query of "class" must not match `<p class="...">`).
class DuaSearchIndex {
  final List<Map<String, dynamic>> _items;
  final List<String> _haystacks;

  DuaSearchIndex(List<Map<String, dynamic>> items)
    : _items = List.unmodifiable(items),
      _haystacks = items.map(_haystackFor).toList(growable: false);

  static String _haystackFor(Map<String, dynamic> dua) {
    final title = dua['title'] as String? ?? '';
    final subtitle = dua['subtitle'] as String? ?? '';
    final content = SearchNormalizer.htmlToPlainText(
      dua['content'] as String? ?? '',
    );
    return SearchNormalizer.normalize('$title\n$subtitle\n$content');
  }

  List<Map<String, dynamic>> search(String query) {
    final q = SearchNormalizer.normalize(query);
    if (q.isEmpty) return _items;
    return [
      for (var i = 0; i < _items.length; i++)
        if (_haystacks[i].contains(q)) _items[i],
    ];
  }
}
