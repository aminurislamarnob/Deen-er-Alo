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
  static const String _keyLifetime = 'tasbeeh_lifetime_count';
  static const String _keyCycles = 'tasbeeh_completed_cycles';
  static const String _keyHaptic = 'tasbeeh_haptic_enabled';
  static const String _keySound = 'tasbeeh_sound_enabled';
  static const String _keyCyclesDate = 'tasbeeh_cycles_date';
  bool _hasLocalMutation = false;
  Future<void> _saveQueue = Future<void>.value();

  TasbeehNotifier()
    : super(
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
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lifetime = prefs.getInt(_keyLifetime) ?? 0;
      final cycles = prefs.getInt(_keyCycles) ?? 0;
      final haptic = prefs.getBool(_keyHaptic) ?? true;
      final sound = prefs.getBool(_keySound) ?? false;
      final storedDate = prefs.getString(_keyCyclesDate);
      final today = _todayKey();
      final dailyCycles = storedDate == today ? cycles : 0;

      if (!_hasLocalMutation) {
        state = state.copyWith(
          totalLifetimeCount: lifetime,
          completedCycles: dailyCycles,
          hapticEnabled: haptic,
          soundEnabled: sound,
        );
      }
    } catch (_) {}
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  void _saveToPrefs() {
    final snapshot = state;
    _saveQueue = _saveQueue.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_keyLifetime, snapshot.totalLifetimeCount);
        await prefs.setInt(_keyCycles, snapshot.completedCycles);
        await prefs.setString(_keyCyclesDate, _todayKey());
        await prefs.setBool(_keyHaptic, snapshot.hapticEnabled);
        await prefs.setBool(_keySound, snapshot.soundEnabled);
      } catch (_) {}
    });
  }

  void increment() {
    _hasLocalMutation = true;
    final nextCount = state.currentCount + 1;
    final nextLifetime = state.totalLifetimeCount + 1;

    if (state.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    if (state.hapticEnabled) {
      HapticFeedback.lightImpact();
    }

    if (state.targetCount > 0 && nextCount >= state.targetCount) {
      // Loop target reached!
      if (state.hapticEnabled) {
        HapticFeedback.heavyImpact();
      }
      state = state.copyWith(
        currentCount: 0,
        completedCycles: state.completedCycles + 1,
        totalLifetimeCount: nextLifetime,
      );
    } else {
      state = state.copyWith(
        currentCount: nextCount,
        totalLifetimeCount: nextLifetime,
      );
    }

    _saveToPrefs();
  }

  void resetCurrent() {
    _hasLocalMutation = true;
    if (state.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
    state = state.copyWith(currentCount: 0);
  }

  void resetAll() {
    _hasLocalMutation = true;
    if (state.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
    state = state.copyWith(currentCount: 0, completedCycles: 0);
    _saveToPrefs();
  }

  void selectDhikr(DhikrItem item) {
    _hasLocalMutation = true;
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
    _hasLocalMutation = true;
    if (state.hapticEnabled) {
      HapticFeedback.selectionClick();
    }
    state = state.copyWith(targetCount: target, currentCount: 0);
  }

  void toggleHaptic() {
    _hasLocalMutation = true;
    final next = !state.hapticEnabled;
    if (next) {
      HapticFeedback.lightImpact();
    }
    state = state.copyWith(hapticEnabled: next);
    _saveToPrefs();
  }

  void toggleSound() {
    _hasLocalMutation = true;
    state = state.copyWith(soundEnabled: !state.soundEnabled);
    _saveToPrefs();
  }
}

final tasbeehProvider = StateNotifierProvider<TasbeehNotifier, TasbeehState>((
  ref,
) {
  return TasbeehNotifier();
});
