import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FastingState {
  final int completedDays;
  final int targetDays;
  final bool isFastToday;

  const FastingState({
    required this.completedDays,
    required this.targetDays,
    required this.isFastToday,
  });

  FastingState copyWith({
    int? completedDays,
    int? targetDays,
    bool? isFastToday,
  }) {
    return FastingState(
      completedDays: completedDays ?? this.completedDays,
      targetDays: targetDays ?? this.targetDays,
      isFastToday: isFastToday ?? this.isFastToday,
    );
  }
}

class FastingNotifier extends StateNotifier<FastingState> {
  static const String _prefKeyCompleted = 'pref_fasting_completed_days';
  static const String _prefKeyToday = 'pref_fasting_today_active';

  FastingNotifier()
      : super(const FastingState(
          completedDays: 6,
          targetDays: 30,
          isFastToday: true,
        )) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getInt(_prefKeyCompleted) ?? 6;
    final today = prefs.getBool(_prefKeyToday) ?? true;
    state = FastingState(
      completedDays: completed,
      targetDays: 30,
      isFastToday: today,
    );
  }

  Future<void> toggleTodayFast() async {
    final newToday = !state.isFastToday;
    final newCompleted = newToday
        ? (state.completedDays + 1).clamp(0, state.targetDays)
        : (state.completedDays - 1).clamp(0, state.targetDays);

    state = state.copyWith(
      isFastToday: newToday,
      completedDays: newCompleted,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyToday, newToday);
    await prefs.setInt(_prefKeyCompleted, newCompleted);
  }
}

final fastingProvider =
    StateNotifierProvider<FastingNotifier, FastingState>((ref) {
  return FastingNotifier();
});
