import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/dhikr_item.dart';

class TasbeehState {
  final int currentCount;
  final int targetCount;
  final int completedCycles;
  final int lifetimeCount;
  final DhikrItem currentDhikr;
  final bool hapticEnabled;

  const TasbeehState({
    required this.currentCount,
    required this.targetCount,
    required this.completedCycles,
    required this.lifetimeCount,
    required this.currentDhikr,
    required this.hapticEnabled,
  });

  double get progress {
    if (targetCount <= 0) return 0.0;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }

  TasbeehState copyWith({
    int? currentCount,
    int? targetCount,
    int? completedCycles,
    int? lifetimeCount,
    DhikrItem? currentDhikr,
    bool? hapticEnabled,
  }) {
    return TasbeehState(
      currentCount: currentCount ?? this.currentCount,
      targetCount: targetCount ?? this.targetCount,
      completedCycles: completedCycles ?? this.completedCycles,
      lifetimeCount: lifetimeCount ?? this.lifetimeCount,
      currentDhikr: currentDhikr ?? this.currentDhikr,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    );
  }
}

class TasbeehNotifier extends StateNotifier<TasbeehState> {
  static const String _keyLifetime = 'tasbeeh_lifetime_count';
  static const String _keyCycles = 'tasbeeh_completed_cycles';
  static const String _keyHaptic = 'tasbeeh_haptic_enabled';

  TasbeehNotifier()
      : super(
          TasbeehState(
            currentCount: 0,
            targetCount: DhikrItem.presets.first.recommendedTarget,
            completedCycles: 0,
            lifetimeCount: 0,
            currentDhikr: DhikrItem.presets.first,
            hapticEnabled: true,
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

      state = state.copyWith(
        lifetimeCount: lifetime,
        completedCycles: cycles,
        hapticEnabled: haptic,
      );
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLifetime, state.lifetimeCount);
      await prefs.setInt(_keyCycles, state.completedCycles);
      await prefs.setBool(_keyHaptic, state.hapticEnabled);
    } catch (_) {}
  }

  void increment() {
    final nextCount = state.currentCount + 1;
    final nextLifetime = state.lifetimeCount + 1;

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
        lifetimeCount: nextLifetime,
      );
    } else {
      state = state.copyWith(
        currentCount: nextCount,
        lifetimeCount: nextLifetime,
      );
    }

    _saveToPrefs();
  }

  void resetCurrent() {
    if (state.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
    state = state.copyWith(currentCount: 0);
  }

  void resetAll() {
    if (state.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
    state = state.copyWith(currentCount: 0, completedCycles: 0);
    _saveToPrefs();
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
    final next = !state.hapticEnabled;
    if (next) {
      HapticFeedback.lightImpact();
    }
    state = state.copyWith(hapticEnabled: next);
    _saveToPrefs();
  }
}

final tasbeehProvider =
    StateNotifierProvider<TasbeehNotifier, TasbeehState>((ref) {
      return TasbeehNotifier();
    });
