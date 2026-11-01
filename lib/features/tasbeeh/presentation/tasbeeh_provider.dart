import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/dhikr_item.dart';

class TasbeehState {
  final int currentCount;
  final int targetCount;
  final int completedCycles;
  final int totalLifetimeCount;
  final DhikrItem currentDhikr;
  final bool hapticEnabled;
  final bool soundEnabled;

  int get lifetimeCount => totalLifetimeCount;

  const TasbeehState({
    required this.currentCount,
    required this.targetCount,
    required this.completedCycles,
    required this.totalLifetimeCount,
    required this.currentDhikr,
    required this.hapticEnabled,
    required this.soundEnabled,
  });

  double get progress {
    if (targetCount <= 0) return 0.0;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }

  /// True when the current cycle has just been completed (e.g. 33/33).
  /// The next tap starts a new cycle at 1.
  bool get isCycleComplete => targetCount > 0 && currentCount >= targetCount;

  TasbeehState copyWith({
    int? currentCount,
    int? targetCount,
    int? completedCycles,
    int? totalLifetimeCount,
    DhikrItem? currentDhikr,
    bool? hapticEnabled,
    bool? soundEnabled,
  }) {
    return TasbeehState(
      currentCount: currentCount ?? this.currentCount,
      targetCount: targetCount ?? this.targetCount,
      completedCycles: completedCycles ?? this.completedCycles,
      totalLifetimeCount: totalLifetimeCount ?? this.totalLifetimeCount,
      currentDhikr: currentDhikr ?? this.currentDhikr,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}

class TasbeehNotifier extends StateNotifier<TasbeehState> {
  static const String keyLifetime = 'tasbeeh_lifetime_count';
  static const String keyCycles = 'tasbeeh_completed_cycles';
  static const String keyHaptic = 'tasbeeh_haptic_enabled';
  static const String keySound = 'tasbeeh_sound_enabled';
  static const String keyCyclesDate = 'tasbeeh_cycles_date';

  /// Persistence is debounced so rapid tapping doesn't hit storage per tap.
  static const Duration defaultSaveDebounce = Duration(milliseconds: 800);

  /// Delay before pending state is persisted after the last change.
  final Duration saveDebounce;
  final DateTime Function() _clock;

  late final Future<void> _loadFuture;
  bool _isLoaded = false;

  // Tracks what the user changed before the stored values were loaded, so the
  // load can merge instead of being skipped or clobbering session progress.
  bool _lifetimeOverridden = false;
  bool _cyclesOverridden = false;
  bool _hapticChanged = false;
  bool _soundChanged = false;

  /// Date key ("y-m-d") that [TasbeehState.completedCycles] belongs to.
  late String _cyclesDate;

  bool _dirty = false;
  Timer? _saveTimer;
  Future<void> _saveQueue = Future<void>.value();
  TasbeehState? _disposedSnapshot;

  TasbeehNotifier({
    this.saveDebounce = defaultSaveDebounce,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(
         TasbeehState(
           currentCount: 0,
           targetCount: DhikrItem.presets.first.recommendedTarget,
           completedCycles: 0,
           totalLifetimeCount: 0,
           currentDhikr: DhikrItem.presets.first,
           hapticEnabled: true,
           soundEnabled: false,
         ),
       ) {
    _cyclesDate = _todayKey();
    _loadFuture = _loadFromPrefs();
  }

  /// Completes once stored values have been loaded and merged.
  Future<void> get ready => _loadFuture;

  bool get isLoaded => _isLoaded;

  /// Completes when all writes queued so far have finished.
  @visibleForTesting
  Future<void> get pendingWrites => _saveQueue;

  Future<void> _loadFromPrefs() async {
    var storedLifetime = 0;
    var storedCycles = 0;
    var storedHaptic = true;
    var storedSound = false;
    String? storedDate;
    try {
      final prefs = await SharedPreferences.getInstance();
      storedLifetime = prefs.getInt(keyLifetime) ?? 0;
      storedCycles = prefs.getInt(keyCycles) ?? 0;
      storedHaptic = prefs.getBool(keyHaptic) ?? true;
      storedSound = prefs.getBool(keySound) ?? false;
      storedDate = prefs.getString(keyCyclesDate);
    } catch (_) {}

    final today = _todayKey();
    final storedDailyCycles = storedDate == today ? storedCycles : 0;
    final current = mounted ? state : _disposedSnapshot!;

    final merged = current.copyWith(
      totalLifetimeCount: _lifetimeOverridden
          ? current.totalLifetimeCount
          : storedLifetime + current.totalLifetimeCount,
      completedCycles: _cyclesOverridden
          ? current.completedCycles
          : storedDailyCycles + current.completedCycles,
      hapticEnabled: _hapticChanged ? current.hapticEnabled : storedHaptic,
      soundEnabled: _soundChanged ? current.soundEnabled : storedSound,
    );
    _cyclesDate = today;
    _isLoaded = true;

    if (mounted) {
      state = merged;
      if (_dirty) _scheduleSave();
    } else if (_dirty) {
      // Disposed before load finished: persist the merged result now.
      _dirty = false;
      await _enqueueWrite(merged, _cyclesDate);
    }
  }

  String _todayKey() {
    final now = _clock();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// Daily cycles must not carry over midnight.
  void _rolloverDayIfNeeded() {
    final today = _todayKey();
    if (_cyclesDate == today) return;
    _cyclesDate = today;
    if (state.completedCycles != 0) {
      state = state.copyWith(completedCycles: 0);
      _dirty = true;
    }
  }

  void _scheduleSave() {
    _dirty = true;
    // Never write before the stored values are loaded; the load flushes.
    if (!_isLoaded) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDebounce, flush);
  }

  /// Writes any pending state immediately (after the initial load).
  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    if (!_isLoaded) {
      await _loadFuture;
      _saveTimer?.cancel();
      _saveTimer = null;
    }
    if (!mounted) return _saveQueue;
    if (_dirty) {
      _dirty = false;
      _enqueueWrite(state, _cyclesDate);
    }
    return _saveQueue;
  }

  Future<void> _enqueueWrite(TasbeehState snapshot, String cyclesDate) {
    _saveQueue = _saveQueue.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(keyLifetime, snapshot.totalLifetimeCount);
        await prefs.setInt(keyCycles, snapshot.completedCycles);
        await prefs.setString(keyCyclesDate, cyclesDate);
        await prefs.setBool(keyHaptic, snapshot.hapticEnabled);
        await prefs.setBool(keySound, snapshot.soundEnabled);
      } catch (_) {}
    });
    return _saveQueue;
  }

  void increment() {
    _rolloverDayIfNeeded();
    final s = state;
    // After a completed cycle (e.g. 33/33) the next tap starts at 1.
    final base = s.isCycleComplete ? 0 : s.currentCount;
    final nextCount = base + 1;
    final nextLifetime = s.totalLifetimeCount + 1;

    if (s.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    if (s.hapticEnabled) {
      HapticFeedback.lightImpact();
    }

    if (s.targetCount > 0 && nextCount >= s.targetCount) {
      if (s.hapticEnabled) {
        HapticFeedback.heavyImpact();
      }
      state = s.copyWith(
        currentCount: s.targetCount,
        completedCycles: s.completedCycles + 1,
        totalLifetimeCount: nextLifetime,
      );
    } else {
      state = s.copyWith(
        currentCount: nextCount,
        totalLifetimeCount: nextLifetime,
      );
    }

    _scheduleSave();
  }

  void resetCurrent() {
    if (state.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
    state = state.copyWith(currentCount: 0);
  }

  /// Resets the current count and today's completed cycles.
  void resetAll() {
    _rolloverDayIfNeeded();
    if (state.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (!_isLoaded) _cyclesOverridden = true;
    state = state.copyWith(currentCount: 0, completedCycles: 0);
    _scheduleSave();
  }

  /// Resets the all-time (lifetime) count. Daily data is left untouched.
  void resetLifetime() {
    if (state.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (!_isLoaded) _lifetimeOverridden = true;
    state = state.copyWith(totalLifetimeCount: 0);
    _scheduleSave();
  }

  void selectDhikr(DhikrItem item) {
    if (state.hapticEnabled) {
      HapticFeedback.selectionClick();
    }
    state = state.copyWith(
      currentDhikr: item,
      targetCount: item.recommendedTarget,
      currentCount: 0,
    );
  }

  void setTarget(int target) {
    if (state.hapticEnabled) {
      HapticFeedback.selectionClick();
    }
    state = state.copyWith(targetCount: target, currentCount: 0);
  }

  void toggleHaptic() {
    _hapticChanged = true;
    final next = !state.hapticEnabled;
    if (next) {
      HapticFeedback.lightImpact();
    }
    state = state.copyWith(hapticEnabled: next);
    _scheduleSave();
  }

  void toggleSound() {
    _soundChanged = true;
    state = state.copyWith(soundEnabled: !state.soundEnabled);
    _scheduleSave();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _saveTimer = null;
    final snapshot = state;
    _disposedSnapshot = snapshot;
    if (_dirty && _isLoaded) {
      _dirty = false;
      _enqueueWrite(snapshot, _cyclesDate);
    }
    // If not loaded yet, _loadFromPrefs persists the merged result on completion.
    super.dispose();
  }
}

final tasbeehProvider = StateNotifierProvider<TasbeehNotifier, TasbeehState>((
  ref,
) {
  return TasbeehNotifier();
});
