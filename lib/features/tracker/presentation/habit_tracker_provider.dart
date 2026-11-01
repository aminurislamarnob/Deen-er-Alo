import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../prayer_times/domain/prayer_model.dart';
import '../data/habit_repository.dart';
import '../domain/habit_models.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

final selectedTrackerDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final habitStreakSummaryProvider =
    FutureProvider.autoDispose<HabitStreakSummary>((ref) async {
  final repo = ref.watch(habitRepositoryProvider);
  return repo.getStreakSummary();
});

class CurrentHabitRecordNotifier
    extends StateNotifier<AsyncValue<DailyHabitRecord>> {
  final HabitRepository _repo;
  final DateTime _date;
  final Ref _ref;

  CurrentHabitRecordNotifier(this._repo, this._date, this._ref)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final rec = await _repo.getRecord(_date);
      state = AsyncValue.data(rec);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setPrayerStatus(PrayerType type, PrayerStatus status) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedPrayers = Map<PrayerType, PrayerStatus>.from(current.prayers);
    updatedPrayers[type] = status;

    final updatedRec = current.copyWith(prayers: updatedPrayers);
    state = AsyncValue.data(updatedRec);
    await _repo.saveRecord(updatedRec);
    _ref.invalidate(habitStreakSummaryProvider);
  }

  Future<void> setFastingStatus(FastingStatus status) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedRec = current.copyWith(fasting: status);
    state = AsyncValue.data(updatedRec);
    await _repo.saveRecord(updatedRec);
    _ref.invalidate(habitStreakSummaryProvider);
  }

  Future<void> toggleQuran() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedRec = current.copyWith(readQuran: !current.readQuran);
    state = AsyncValue.data(updatedRec);
    await _repo.saveRecord(updatedRec);
    _ref.invalidate(habitStreakSummaryProvider);
  }

  Future<void> toggleAdhkar() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedRec =
        current.copyWith(morningEveningAdhkar: !current.morningEveningAdhkar);
    state = AsyncValue.data(updatedRec);
    await _repo.saveRecord(updatedRec);
    _ref.invalidate(habitStreakSummaryProvider);
  }

  Future<void> toggleTahajjudOrDuha() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedRec =
        current.copyWith(tahajjudOrDuha: !current.tahajjudOrDuha);
    state = AsyncValue.data(updatedRec);
    await _repo.saveRecord(updatedRec);
    _ref.invalidate(habitStreakSummaryProvider);
  }

  Future<void> toggleSadaqah() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedRec = current.copyWith(gaveSadaqah: !current.gaveSadaqah);
    state = AsyncValue.data(updatedRec);
    await _repo.saveRecord(updatedRec);
    _ref.invalidate(habitStreakSummaryProvider);
  }
}

final currentHabitRecordProvider = StateNotifierProvider.autoDispose<
    CurrentHabitRecordNotifier, AsyncValue<DailyHabitRecord>>((ref) {
  final repo = ref.watch(habitRepositoryProvider);
  final date = ref.watch(selectedTrackerDateProvider);
  return CurrentHabitRecordNotifier(repo, date, ref);
});

class QazaCounterNotifier extends StateNotifier<int> {
  final HabitRepository _repo;
  final Ref _ref;

  QazaCounterNotifier(this._repo, this._ref) : super(0) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.getQazaBalance();
  }

  Future<void> increment() async {
    state++;
    await _repo.setQazaBalance(state);
    _ref.invalidate(habitStreakSummaryProvider);
  }

  Future<void> decrement() async {
    if (state > 0) {
      state--;
      await _repo.setQazaBalance(state);
      _ref.invalidate(habitStreakSummaryProvider);
    }
  }
}

final qazaCounterProvider =
    StateNotifierProvider<QazaCounterNotifier, int>((ref) {
  final repo = ref.watch(habitRepositoryProvider);
  return QazaCounterNotifier(repo, ref);
});
