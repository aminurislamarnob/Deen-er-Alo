import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/city_clock.dart';
import '../data/city_repository.dart';
import '../data/ifa_timetable_service.dart';
import '../data/prayer_engine.dart';
import '../domain/city_model.dart';
import '../domain/prayer_model.dart';
import 'prayer_source_provider.dart';
export '../domain/prayer_source.dart';
export 'prayer_source_provider.dart';

// Services
final cityRepositoryProvider = Provider<CityRepository>((ref) {
  return CityRepository();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final ifaServiceProvider = Provider<IFATimetableService>((ref) {
  return IFATimetableService();
});

final prayerEngineProvider = Provider<PrayerEngine>((ref) {
  final ifaService = ref.watch(ifaServiceProvider);
  return PrayerEngine(ifaService: ifaService);
});

// Selected City Notifier
class SelectedCityNotifier extends StateNotifier<AsyncValue<CityModel>> {
  final CityRepository _cityRepo;
  final LocationService _locationService;

  SelectedCityNotifier(this._cityRepo, this._locationService)
      : super(const AsyncValue.loading()) {
    _loadInitialCity();
  }

  Future<void> _loadInitialCity() async {
    try {
      final savedCity = await _cityRepo.getSavedCity();
      state = AsyncValue.data(savedCity);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> selectCity(CityModel city) async {
    state = AsyncValue.data(city);
    await _cityRepo.saveSelectedCity(city);
  }

  Future<bool> detectLocation() async {
    // Keep showing the previous city while detecting (no flicker to Dhaka).
    state = const AsyncLoading<CityModel>().copyWithPrevious(state);
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final nearest = await _cityRepo.findNearestCity(
          position.latitude,
          position.longitude,
        );
        state = AsyncValue.data(nearest);
        await _cityRepo.saveSelectedCity(nearest);
        return true;
      } else {
        final savedCity = await _cityRepo.getSavedCity();
        state = AsyncValue.data(savedCity);
        return false;
      }
    } catch (e, st) {
      state = AsyncError<CityModel>(e, st).copyWithPrevious(state);
      return false;
    }
  }
}

final selectedCityProvider =
    StateNotifierProvider<SelectedCityNotifier, AsyncValue<CityModel>>((ref) {
  final cityRepo = ref.watch(cityRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);
  return SelectedCityNotifier(cityRepo, locationService);
});

// Real-time clock (device instant, ticks every second).
final clockStreamProvider = StreamProvider.autoDispose<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

/// IANA zone of the selected city (null = device zone).
final cityTimeZoneProvider = Provider<String?>((ref) {
  final city = ref.watch(selectedCityProvider).valueOrNull;
  return (city ?? CityModel.dhakaDefault()).effectiveTimeZone;
});

/// Current wall-clock time in the selected city. Ticks every second.
final cityNowProvider = Provider.autoDispose<DateTime>((ref) {
  final zone = ref.watch(cityTimeZoneProvider);
  final instant = ref.watch(clockStreamProvider).valueOrNull ?? DateTime.now();
  return CityClock.toWall(instant, zone);
});

/// Today's date in the selected city. Only notifies when the date changes,
/// which gives every dependant an automatic midnight rollover.
final todayDateProvider = Provider.autoDispose<DateTime>((ref) {
  return CityClock.dateOnly(ref.watch(cityNowProvider));
});

/// Date browsed on the Prayers tab. Independent from "today" so browsing
/// never changes the Home dashboard, countdown, widgets or alarms.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return CityClock.dateOnly(CityClock.now(ref.read(cityTimeZoneProvider)));
});

/// Today's prayer schedule for the selected city (Home, alarms, widgets).
final todayPrayerTimesProvider =
    FutureProvider.autoDispose<DayPrayerTimes>((ref) async {
  final city =
      ref.watch(selectedCityProvider).valueOrNull ?? CityModel.dhakaDefault();
  final date = ref.watch(todayDateProvider);
  final engine = ref.watch(prayerEngineProvider);
  final source = ref.watch(prayerSourceProvider);
  return engine.calculateDayPrayers(city: city, date: date, source: source);
});

/// Today's schedule with `isCurrent`/`isNext` refreshed every second.
final liveTodayPrayerTimesProvider =
    Provider.autoDispose<AsyncValue<DayPrayerTimes>>((ref) {
  final engine = ref.watch(prayerEngineProvider);
  final now = ref.watch(cityNowProvider);
  return ref
      .watch(todayPrayerTimesProvider)
      .whenData((day) => engine.markCurrent(day, now));
});

/// Prayer schedule for the date browsed on the Prayers tab.
final dayPrayerTimesProvider =
    FutureProvider.autoDispose<DayPrayerTimes>((ref) async {
  final city =
      ref.watch(selectedCityProvider).valueOrNull ?? CityModel.dhakaDefault();
  final date = ref.watch(selectedDateProvider);
  final engine = ref.watch(prayerEngineProvider);
  final source = ref.watch(prayerSourceProvider);
  return engine.calculateDayPrayers(city: city, date: date, source: source);
});

/// Browsed schedule with live `isCurrent` flags (only today's can be current).
final liveDayPrayerTimesProvider =
    Provider.autoDispose<AsyncValue<DayPrayerTimes>>((ref) {
  final engine = ref.watch(prayerEngineProvider);
  final now = ref.watch(cityNowProvider);
  return ref
      .watch(dayPrayerTimesProvider)
      .whenData((day) => engine.markCurrent(day, now));
});

/// Live countdown to the next waqt — always based on *today*.
final countdownProvider = Provider.autoDispose<NextPrayerCountdown?>((ref) {
  final dayPrayers = ref.watch(todayPrayerTimesProvider).valueOrNull;
  if (dayPrayers == null) return null;
  final now = ref.watch(cityNowProvider);
  final engine = ref.watch(prayerEngineProvider);
  return engine.calculateCountdown(dayPrayers: dayPrayers, now: now);
});

// Prohibited Times Providers (today)
final prohibitedTimesProvider =
    Provider.autoDispose<List<ProhibitedTimeRange>>((ref) {
  final dayPrayers = ref.watch(todayPrayerTimesProvider).valueOrNull;
  if (dayPrayers == null) return [];
  final engine = ref.watch(prayerEngineProvider);
  return engine.getProhibitedTimes(dayPrayers);
});

final currentProhibitedTimeProvider =
    Provider.autoDispose<ProhibitedTimeRange?>((ref) {
  final dayPrayers = ref.watch(todayPrayerTimesProvider).valueOrNull;
  if (dayPrayers == null) return null;
  final now = ref.watch(cityNowProvider);
  final engine = ref.watch(prayerEngineProvider);
  return engine.getCurrentProhibitedTime(dayPrayers, now);
});

/// The currently active waqt today (null between sunrise and Dhuhr).
/// Changes only at waqt boundaries, so widgets that watch it rebuild rarely.
final currentPrayerTypeProvider = Provider.autoDispose<PrayerType?>((ref) {
  final day = ref.watch(todayPrayerTimesProvider).valueOrNull;
  if (day == null) return null;
  final engine = ref.watch(prayerEngineProvider);
  final marked = engine.markCurrent(day, ref.watch(cityNowProvider));
  for (final item in marked.scheduleItems) {
    if (item.isCurrent) return item.type;
  }
  return null;
});
