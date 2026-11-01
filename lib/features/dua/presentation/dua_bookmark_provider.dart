import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DuaBookmarkNotifier extends StateNotifier<Set<int>> {
  static const String _keyBookmarks = 'bookmarked_dua_ids';

  DuaBookmarkNotifier() : super(<int>{}) {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyBookmarks) ?? [];
      state = list.map(int.parse).toSet();
    } catch (_) {}
  }

  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _keyBookmarks,
        state.map((id) => id.toString()).toList(),
      );
    } catch (_) {}
  }

  void toggleBookmark(int duaId) {
    if (state.contains(duaId)) {
      state = {...state}..remove(duaId);
    } else {
      state = {...state, duaId};
    }
    _saveBookmarks();
  }

  bool isBookmarked(int duaId) => state.contains(duaId);
}

final duaBookmarkProvider =
    StateNotifierProvider<DuaBookmarkNotifier, Set<int>>((ref) {
      return DuaBookmarkNotifier();
    });
