import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DuaBookmarkNotifier extends StateNotifier<Set<int>> {
  static const String _keyBookmarks = 'bookmarked_dua_ids';

  DuaBookmarkNotifier() : super(<int>{}) {
    _loadBookmarks();
  }
  bool _hasLocalMutation = false;
  Future<void> _saveQueue = Future<void>.value();

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyBookmarks) ?? [];
      if (!_hasLocalMutation) {
        state = list.map(int.parse).toSet();
      }
    } catch (_) {}
  }

  void _saveBookmarks() {
    final snapshot = state.map((id) => id.toString()).toList();
    _saveQueue = _saveQueue.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_keyBookmarks, snapshot);
      } catch (_) {}
    });
  }

  void toggleBookmark(int duaId) {
    _hasLocalMutation = true;
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
