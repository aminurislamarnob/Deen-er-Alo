import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/location_service.dart';
import '../data/city_repository.dart';
import '../data/ifa_timetable_service.dart';
import '../data/prayer_engine.dart';
import '../domain/city_model.dart';
import '../domain/prayer_model.dart';

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
    state = const AsyncValue.loading();
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
        // Fallback to saved
        final savedCity = await _cityRepo.getSavedCity();
        state = AsyncValue.data(savedCity);
        return false;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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

// Selected Date Provider (Defaults to today)
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

// Day Prayer Times Provider
final dayPrayerTimesProvider = FutureProvider<DayPrayerTimes>((ref) async {
  final cityAsync = ref.watch(selectedCityProvider);
  final date = ref.watch(selectedDateProvider);
  final engine = ref.watch(prayerEngineProvider);

  final city = cityAsync.value ?? CityModel.dhakaDefault();
  return await engine.calculateDayPrayers(city: city, date: date);
});

// Real-time Clock Stream (ticks every 1 second)
final clockStreamProvider = StreamProvider.autoDispose<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

// Real-time Countdown Provider
final countdownProvider = Provider.autoDispose<NextPrayerCountdown?>((ref) {
  final dayPrayersAsync = ref.watch(dayPrayerTimesProvider);
  final nowAsync = ref.watch(clockStreamProvider);
  final engine = ref.watch(prayerEngineProvider);

  final dayPrayers = dayPrayersAsync.value;
  if (dayPrayers == null) return null;

  final now = nowAsync.value ?? DateTime.now();
  return engine.calculateCountdown(dayPrayers: dayPrayers, now: now);
});

// Prayer Alarm Notification Toggles
class PrayerAlarmNotifier extends StateNotifier<Map<PrayerType, bool>> {
  PrayerAlarmNotifier()
      : super({
          PrayerType.fajr: true,
          PrayerType.dhuhr: false,
          PrayerType.asr: false,
          PrayerType.maghrib: true,
          PrayerType.isha: false,
        });

  void toggleAlarm(PrayerType type) {
    state = {
      ...state,
      type: !(state[type] ?? false),
    };
  }
}

final prayerAlarmProvider =
    StateNotifierProvider<PrayerAlarmNotifier, Map<PrayerType, bool>>((ref) {
  return PrayerAlarmNotifier();
});

