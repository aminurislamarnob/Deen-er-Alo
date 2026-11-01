import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../prayer_times/domain/prayer_model.dart';
import '../../prayer_times/presentation/prayer_providers.dart';
import '../data/islamic_events_repository.dart';

final islamicEventsRepositoryProvider = Provider<IslamicEventsRepository>((ref) {
  return IslamicEventsRepository();
});

class MoonOffsetNotifier extends StateNotifier<int> {
  static const _key = 'deener_alo_moon_offset_v1';

  MoonOffsetNotifier() : super(0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_key) ?? 0;
  }

  Future<void> setOffset(int offset) async {
    state = offset;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, offset);
  }
}

final moonOffsetProvider = StateNotifierProvider<MoonOffsetNotifier, int>((ref) {
  return MoonOffsetNotifier();
});

final calendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final selectedCalendarDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Calculates Hijri date for any Gregorian DateTime factoring in the active moon-sighting offset
HijriCalendar getAdjustedHijriDate(DateTime dt, int offsetDays) {
  final effectiveDate = dt.add(Duration(days: offsetDays));
  return HijriCalendar.fromDate(effectiveDate);
}

/// Computes the exact prayer timetable for the date selected on the calendar
final calendarDayPrayersProvider =
    FutureProvider.autoDispose<DayPrayerTimes?>((ref) async {
  final cityAsync = ref.watch(selectedCityProvider);
  final city = cityAsync.valueOrNull;
  if (city == null) return null;

  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final prayerEngine = ref.watch(prayerEngineProvider);

  return prayerEngine.calculateDayPrayers(
    city: city,
    date: selectedDate,
  );
});
