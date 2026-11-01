import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../calendar/presentation/hijri_providers.dart';
import '../../prayer_times/domain/prayer_model.dart';
import '../../tracker/domain/habit_models.dart';
import '../../tracker/presentation/habit_tracker_provider.dart';

/// Home-screen view of today's five prayers as simple done/not-done flags.
///
/// Backed by the tracker's [habitRecordProvider] for today, so the home card
/// and the tracker screen always show the same data.
class PrayerTrackerNotifier extends StateNotifier<Map<PrayerType, bool>> {
  final HabitRecordNotifier Function() _record;

  PrayerTrackerNotifier(this._record, DailyHabitRecord? initial)
    : super(_flagsFrom(initial));

  static Map<PrayerType, bool> _flagsFrom(DailyHabitRecord? record) => {
    for (final type in fardPrayerTypes)
      type: (record?.prayers[type] ?? PrayerStatus.none).countsAsPrayed,
  };

  void _sync(DailyHabitRecord? record) {
    if (record != null && mounted) state = _flagsFrom(record);
  }

  /// Marks the prayer as prayed alone ("একাকী") when it is not yet prayed,
  /// otherwise clears it back to "not logged".
  Future<void> togglePrayer(PrayerType type) async {
    final record = _record();
    await record.ready;
    final current =
        record.state.valueOrNull?.prayers[type] ?? PrayerStatus.none;
    await record.setPrayerStatus(
      type,
      current.countsAsPrayed ? PrayerStatus.none : PrayerStatus.alone,
    );
  }
}

final prayerTrackerProvider =
    StateNotifierProvider<PrayerTrackerNotifier, Map<PrayerType, bool>>((ref) {
      final today = ref.watch(currentDayProvider);
      final recordProvider = habitRecordProvider(today);
      final notifier = PrayerTrackerNotifier(
        () => ref.read(recordProvider.notifier),
        ref.read(recordProvider).valueOrNull,
      );
      ref.listen<AsyncValue<DailyHabitRecord>>(
        recordProvider,
        (_, next) => notifier._sync(next.valueOrNull),
      );
      return notifier;
    });
