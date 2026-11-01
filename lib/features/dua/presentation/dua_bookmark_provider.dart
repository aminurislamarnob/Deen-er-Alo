import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DuaBookmarkNotifier extends StateNotifier<Set<int>> {
  static const String keyBookmarks = 'bookmarked_dua_ids';

  DuaBookmarkNotifier() : super(<int>{}) {
    _loadBookmarks();
  }

  final Completer<void> _loadCompleter = Completer<void>();
  // Toggles made before the stored set was loaded; replayed onto it on load.
  final List<int> _pendingToggles = <int>[];
  Future<void> _saveQueue = Future<void>.value();

  /// Completes once stored bookmarks have been loaded (and merged).
  Future<void> get ready => _loadCompleter.future;

  bool get isLoaded => _loadCompleter.isCompleted;

  /// Completes when all writes queued so far have finished.
  @visibleForTesting
  Future<void> get pendingWrites => _saveQueue;

  Future<void> _loadBookmarks() async {
    var stored = <int>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(keyBookmarks) ?? const <String>[];
      stored = list.map(int.tryParse).whereType<int>().toSet();
    } catch (_) {}

    final merged = {...stored};
    for (final id in _pendingToggles) {
      if (!merged.remove(id)) merged.add(id);
    }
    final hadPending = _pendingToggles.isNotEmpty;
    _pendingToggles.clear();

    if (mounted) state = merged;
    _loadCompleter.complete();
    if (hadPending) _saveBookmarks(merged);
  }

  void _saveBookmarks(Set<int> ids) {
    final snapshot = ids.map((id) => id.toString()).toList();
    _saveQueue = _saveQueue.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(keyBookmarks, snapshot);
      } catch (_) {}
    });
  }

  void toggleBookmark(int duaId) {
    // Optimistic UI update in both cases.
    if (state.contains(duaId)) {
      state = {...state}..remove(duaId);
    } else {
      state = {...state, duaId};
    }

    if (!isLoaded) {
      // Don't persist yet: that would replace the saved set. Merge on load.
      _pendingToggles.add(duaId);
      return;
    }
    _saveBookmarks(state);
  }

  bool isBookmarked(int duaId) => state.contains(duaId);
}

final duaBookmarkProvider =
    StateNotifierProvider<DuaBookmarkNotifier, Set<int>>((ref) {
      return DuaBookmarkNotifier();
    });
