import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../calendar/domain/hijri_utils.dart';
import '../../calendar/presentation/hijri_providers.dart';
import '../../tracker/data/habit_repository.dart';
import '../../tracker/domain/habit_models.dart';
import '../../tracker/presentation/habit_tracker_provider.dart';

class FastingState {
  /// Days fasted in the last [targetDays] days (including today).
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

/// Home-screen fasting toggle, backed by today's habit record so it stays in
/// sync with the tracker screen.
class FastingNotifier extends StateNotifier<FastingState> {
  static const int _windowDays = 30;

  final HabitRecordNotifier Function() _record;
  final Future<int> Function() _moonOffset;
  final DateTime _today;

  /// Fast days in the 29 days before today (today is added from the record).
  int _pastFastDays = 0;

  FastingNotifier(
    this._record,
    this._moonOffset,
    this._today,
    HabitRepository repo,
    DailyHabitRecord? initial,
  ) : super(
        FastingState(
          completedDays: _isFasting(initial) ? 1 : 0,
          targetDays: _windowDays,
          isFastToday: _isFasting(initial),
        ),
      ) {
    _loadPastDays(repo);
  }

  static bool _isFasting(DailyHabitRecord? r) =>
      r != null && r.fasting != FastingStatus.notFasting;

  Future<void> _loadPastDays(HabitRepository repo) async {
    try {
      _pastFastDays = await repo.countFastingDays(
        endDate: addDays(_today, -1),
        days: _windowDays - 1,
      );
    } catch (_) {
      _pastFastDays = 0;
    }
    if (mounted) _emit(state.isFastToday);
  }

  void _emit(bool fastToday) {
    state = FastingState(
      completedDays: (_pastFastDays + (fastToday ? 1 : 0)).clamp(
        0,
        _windowDays,
      ),
      targetDays: _windowDays,
      isFastToday: fastToday,
    );
  }

  void _sync(DailyHabitRecord? record) {
    if (record != null && mounted) _emit(_isFasting(record));
  }

  /// Toggles today's fast: on → Ramadan fard during Ramadan, otherwise nafl;
  /// off → not fasting.
  Future<void> toggleTodayFast() async {
    final record = _record();
    await record.ready;
    final current = record.state.valueOrNull;
    if (current == null) return;
    if (current.fasting != FastingStatus.notFasting) {
      await record.setFastingStatus(FastingStatus.notFasting);
      return;
    }
    final offset = await _moonOffset();
    final isRamadan = hijriForDate(_today, offset).hMonth == 9;
    await record.setFastingStatus(
      isRamadan ? FastingStatus.ramadanFarz : FastingStatus.nafl,
    );
  }
}

final fastingProvider = StateNotifierProvider<FastingNotifier, FastingState>((
  ref,
) {
  final today = ref.watch(currentDayProvider);
  final recordProvider = habitRecordProvider(today);
  final notifier = FastingNotifier(
    () => ref.read(recordProvider.notifier),
    () async {
      final moon = ref.read(moonOffsetProvider.notifier);
      await moon.ready;
      return ref.read(moonOffsetProvider);
    },
    today,
    ref.read(habitRepositoryProvider),
    ref.read(recordProvider).valueOrNull,
  );
  ref.listen<AsyncValue<DailyHabitRecord>>(
    recordProvider,
    (_, next) => notifier._sync(next.valueOrNull),
  );
  return notifier;
});
