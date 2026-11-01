import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../calendar/domain/hijri_utils.dart';
import '../../prayer_times/domain/prayer_model.dart';
import '../data/habit_repository.dart';
import '../domain/habit_models.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

/// Date shown on the tracker screen. Auto-disposed so reopening the screen
/// (e.g. after midnight) always starts on today.
final selectedTrackerDateProvider = StateProvider.autoDispose<DateTime>((ref) {
  return dateOnly(DateTime.now());
});

final habitStreakSummaryProvider =
    FutureProvider.autoDispose<HabitStreakSummary>((ref) async {
      final repo = ref.watch(habitRepositoryProvider);
      return repo.getStreakSummary();
    });

/// Holds one day's habit record. Every screen that shows a given day (tracker
/// screen, home prayer tracker, home fasting card) reads the same instance of
/// [habitRecordProvider], so changes made anywhere are reflected everywhere.
class HabitRecordNotifier extends StateNotifier<AsyncValue<DailyHabitRecord>> {
  final HabitRepository _repo;
  final DateTime date;
  final Ref _ref;
  final Completer<void> _loaded = Completer<void>();

  HabitRecordNotifier(this._repo, DateTime date, this._ref)
    : date = dateOnly(date),
      super(const AsyncValue.loading()) {
    _load();
  }

  /// Completes once the initial load finished (successfully or not).
  Future<void> get ready => _loaded.future;

  /// Future days cannot be logged.
  bool get isEditable => !date.isAfter(dateOnly(DateTime.now()));

  Future<void> _load() async {
    try {
      final rec = await _repo.getRecord(date);
      if (mounted) state = AsyncValue.data(rec);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    } finally {
      if (!_loaded.isCompleted) _loaded.complete();
    }
  }

  /// Re-reads the record from storage (used by the error retry button).
  Future<void> reload() async {
    await ready;
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final rec = await _repo.getRecord(date);
      if (mounted) state = AsyncValue.data(rec);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Applies [change] to the loaded record, persists it and refreshes stats.
  /// Waits for the initial load so an early tap never overwrites saved data.
  Future<void> _mutate(
    DailyHabitRecord? Function(DailyHabitRecord current) change, {
    int Function(DailyHabitRecord current)? qazaDelta,
  }) async {
    await ready;
    if (!mounted || !isEditable) return;
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = change(current);
    if (updated == null) return;
    final delta = qazaDelta?.call(current) ?? 0;

    state = AsyncValue.data(updated);
    final qazaNotifier = delta != 0
        ? _ref.read(qazaCounterProvider.notifier)
        : null;

    await _repo.saveRecord(updated);
    if (qazaNotifier != null) await qazaNotifier.applyDelta(delta);
    if (mounted) _ref.invalidate(habitStreakSummaryProvider);
  }

  Future<void> setPrayerStatus(PrayerType type, PrayerStatus status) {
    PrayerStatus oldOf(DailyHabitRecord r) =>
        r.prayers[type] ?? PrayerStatus.none;
    return _mutate((current) {
      if (oldOf(current) == status) return null;
      final prayers = Map<PrayerType, PrayerStatus>.from(current.prayers);
      prayers[type] = status;
      return current.copyWith(prayers: prayers);
    }, qazaDelta: (current) => qazaDeltaFor(oldOf(current), status));
  }

  Future<void> setFastingStatus(FastingStatus status) => _mutate(
    (current) =>
        current.fasting == status ? null : current.copyWith(fasting: status),
  );

  Future<void> toggleQuran() =>
      _mutate((c) => c.copyWith(readQuran: !c.readQuran));

  Future<void> toggleAdhkar() =>
      _mutate((c) => c.copyWith(morningEveningAdhkar: !c.morningEveningAdhkar));

  Future<void> toggleTahajjudOrDuha() =>
      _mutate((c) => c.copyWith(tahajjudOrDuha: !c.tahajjudOrDuha));

  Future<void> toggleSadaqah() =>
      _mutate((c) => c.copyWith(gaveSadaqah: !c.gaveSadaqah));
}

/// The habit record for a calendar day. Pass a date without a time part
/// (use [dateOnly]); the same instance is shared by all listeners of that day.
final habitRecordProvider = StateNotifierProvider.autoDispose
    .family<HabitRecordNotifier, AsyncValue<DailyHabitRecord>, DateTime>((
      ref,
      date,
    ) {
      final repo = ref.watch(habitRepositoryProvider);
      return HabitRecordNotifier(repo, date, ref);
    });

class QazaCounterNotifier extends StateNotifier<int> {
  final HabitRepository _repo;
  final Ref _ref;
  final Completer<void> _loaded = Completer<void>();

  QazaCounterNotifier(this._repo, this._ref) : super(0) {
    _load();
  }

  /// Completes once the saved balance has been loaded.
  Future<void> get ready => _loaded.future;

  Future<void> _load() async {
    try {
      final saved = await _repo.getQazaBalance();
      if (mounted) state = saved;
    } catch (_) {
      // Keep 0.
    } finally {
      if (!_loaded.isCompleted) _loaded.complete();
    }
  }

  Future<void> _set(int value) async {
    if (!mounted) return;
    state = value < 0 ? 0 : value;
    await _repo.setQazaBalance(state);
    if (mounted) _ref.invalidate(habitStreakSummaryProvider);
  }

  Future<void> increment() async {
    await ready;
    await _set(state + 1);
  }

  Future<void> decrement() async {
    await ready;
    if (state > 0) await _set(state - 1);
  }

  /// Adjusts the balance by [delta] (from a prayer status change).
  Future<void> applyDelta(int delta) async {
    await ready;
    if (delta == 0) return;
    await _set(state + delta);
  }

  /// Adds a backlog of [prayers] missed prayers (from the calculator).
  Future<void> addBacklog(int prayers) async {
    await ready;
    if (prayers <= 0) return;
    await _set(state + prayers);
  }
}

final qazaCounterProvider = StateNotifierProvider<QazaCounterNotifier, int>((
  ref,
) {
  final repo = ref.watch(habitRepositoryProvider);
  return QazaCounterNotifier(repo, ref);
});
