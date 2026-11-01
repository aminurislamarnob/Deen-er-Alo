import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../prayer_times/domain/prayer_model.dart';
import '../../prayer_times/presentation/prayer_providers.dart';
import '../data/islamic_events_repository.dart';
import '../domain/hijri_utils.dart';

export '../domain/hijri_utils.dart';
export 'hijri_providers.dart';

final islamicEventsRepositoryProvider = Provider<IslamicEventsRepository>((
  ref,
) {
  return IslamicEventsRepository();
});

final calendarMonthProvider = StateProvider.autoDispose<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final selectedCalendarDateProvider = StateProvider.autoDispose<DateTime>((ref) {
  return dateOnly(DateTime.now());
});

/// Calculates Hijri date for any Gregorian DateTime factoring in the active
/// moon-sighting offset. Kept for backwards compatibility; prefer
/// [hijriForDate].
HijriCalendar getAdjustedHijriDate(DateTime dt, int offsetDays) =>
    hijriForDate(dt, offsetDays);

/// Computes the exact prayer timetable for the date selected on the calendar
final calendarDayPrayersProvider = FutureProvider.autoDispose<DayPrayerTimes?>((
  ref,
) async {
  final cityAsync = ref.watch(selectedCityProvider);
  final city = cityAsync.valueOrNull;
  if (city == null) return null;

  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final prayerEngine = ref.watch(prayerEngineProvider);

  return prayerEngine.calculateDayPrayers(city: city, date: selectedDate);
});
