import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/hijri_utils.dart';

/// Today's local date (time stripped). Updates itself right after midnight so
/// anything watching it (e.g. [hijriTodayProvider]) rolls over to the new day.
class CurrentDayNotifier extends StateNotifier<DateTime> {
  Timer? _timer;

  CurrentDayNotifier() : super(dateOnly(DateTime.now())) {
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    final nextMidnight = addDays(dateOnly(now), 1);
    _timer = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 1),
      () {
        if (!mounted) return;
        refresh();
        _schedule();
      },
    );
  }

  /// Re-reads the clock (e.g. call when the app resumes from background).
  void refresh() {
    final today = dateOnly(DateTime.now());
    if (!isSameDay(today, state)) state = today;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final currentDayProvider = StateNotifierProvider<CurrentDayNotifier, DateTime>((
  ref,
) {
  return CurrentDayNotifier();
});

/// Persisted moon-sighting adjustment in days (-2..+2).
class MoonOffsetNotifier extends StateNotifier<int> {
  static const _key = 'deener_alo_moon_offset_v1';

  final Completer<void> _loaded = Completer<void>();

  MoonOffsetNotifier() : super(0) {
    _load();
  }

  /// Completes once the saved offset has been loaded.
  Future<void> get ready => _loaded.future;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_key) ?? 0;
      if (mounted) state = saved;
    } catch (_) {
      // Keep the default of 0.
    } finally {
      if (!_loaded.isCompleted) _loaded.complete();
    }
  }

  Future<void> setOffset(int offset) async {
    await ready;
    if (!mounted) return;
    state = offset;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, offset);
  }
}

final moonOffsetProvider = StateNotifierProvider<MoonOffsetNotifier, int>((
  ref,
) {
  return MoonOffsetNotifier();
});

/// Today's Hijri date with the saved moon-sighting offset applied.
/// Recomputes when the offset changes and when the day rolls over.
final hijriTodayProvider = Provider<HijriCalendar>((ref) {
  final today = ref.watch(currentDayProvider);
  final offset = ref.watch(moonOffsetProvider);
  return hijriForDate(today, offset);
});
