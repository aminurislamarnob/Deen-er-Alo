import 'package:adhan/adhan.dart';
import '../domain/city_model.dart';
import '../domain/prayer_model.dart';
import 'ifa_timetable_service.dart';

class PrayerEngine {
  final IFATimetableService _ifaService;

  PrayerEngine({IFATimetableService? ifaService})
      : _ifaService = ifaService ?? IFATimetableService();

  Future<DayPrayerTimes> calculateDayPrayers({
    required CityModel city,
    required DateTime date,
  }) async {
    final coordinates = Coordinates(city.latitude, city.longitude);
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;

    final dateComponents = DateComponents(date.year, date.month, date.day);
    final adhanTimes = PrayerTimes(coordinates, dateComponents, params);

    DateTime fajr = adhanTimes.fajr;
    DateTime sunrise = adhanTimes.sunrise;
    DateTime dhuhr = adhanTimes.dhuhr;
    DateTime asr = adhanTimes.asr;
    DateTime maghrib = adhanTimes.maghrib;
    DateTime isha = adhanTimes.isha;

    DateTime? sehriEnd;
    DateTime? iftarTime;

    // Check Bangladesh IFA schedule override if applicable
    if (city.isBangladeshDistrict || city.countryName.toLowerCase() == 'bangladesh') {
      final ifaResult = await _ifaService.getSchedule(
        districtId: city.id,
        date: date,
      );

      if (ifaResult != null) {
        sehriEnd = ifaResult.sehriEnd;
        fajr = ifaResult.fajrStart;
        iftarTime = ifaResult.iftarTime;
        maghrib = ifaResult.iftarTime;
      }
    }

    sehriEnd ??= fajr.subtract(const Duration(minutes: 3));
    iftarTime ??= maghrib;

    // Next day's fajr for Esha end time
    final nextDayDate = date.add(const Duration(days: 1));
    final nextDayComponents = DateComponents(nextDayDate.year, nextDayDate.month, nextDayDate.day);
    final nextDayAdhan = PrayerTimes(coordinates, nextDayComponents, params);
    DateTime nextFajr = nextDayAdhan.fajr;

    if (city.isBangladeshDistrict || city.countryName.toLowerCase() == 'bangladesh') {
      final nextDayIfa = await _ifaService.getSchedule(
        districtId: city.id,
        date: nextDayDate,
      );
      if (nextDayIfa != null) {
        nextFajr = nextDayIfa.fajrStart;
      }
    }

    final scheduleItems = [
      PrayerScheduleItem(
        type: PrayerType.fajr,
        title: PrayerType.fajr.displayName,
        startTime: fajr,
        endTime: sunrise,
      ),
      PrayerScheduleItem(
        type: PrayerType.dhuhr,
        title: PrayerType.dhuhr.displayName,
        startTime: dhuhr,
        endTime: asr,
      ),
      PrayerScheduleItem(
        type: PrayerType.asr,
        title: PrayerType.asr.displayName,
        startTime: asr,
        endTime: maghrib,
      ),
      PrayerScheduleItem(
        type: PrayerType.maghrib,
        title: PrayerType.maghrib.displayName,
        startTime: maghrib,
        endTime: isha,
      ),
      PrayerScheduleItem(
        type: PrayerType.isha,
        title: PrayerType.isha.displayName,
        startTime: isha,
        endTime: nextFajr,
      ),
    ];

    return DayPrayerTimes(
      date: date,
      cityName: city.name,
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
      sehriEnd: sehriEnd,
      iftar: iftarTime,
      scheduleItems: scheduleItems,
    );
  }

  NextPrayerCountdown calculateCountdown({
    required DayPrayerTimes dayPrayers,
    required DateTime now,
  }) {
    DateTime targetTime;
    PrayerType nextPrayer;
    DateTime prevTime;

    if (now.isBefore(dayPrayers.fajr)) {
      nextPrayer = PrayerType.fajr;
      targetTime = dayPrayers.fajr;
      prevTime = dayPrayers.fajr.subtract(const Duration(hours: 6));
    } else if (now.isBefore(dayPrayers.dhuhr)) {
      nextPrayer = PrayerType.dhuhr;
      targetTime = dayPrayers.dhuhr;
      prevTime = dayPrayers.fajr;
    } else if (now.isBefore(dayPrayers.asr)) {
      nextPrayer = PrayerType.asr;
      targetTime = dayPrayers.asr;
      prevTime = dayPrayers.dhuhr;
    } else if (now.isBefore(dayPrayers.maghrib)) {
      nextPrayer = PrayerType.maghrib;
      targetTime = dayPrayers.maghrib;
      prevTime = dayPrayers.asr;
    } else if (now.isBefore(dayPrayers.isha)) {
      nextPrayer = PrayerType.isha;
      targetTime = dayPrayers.isha;
      prevTime = dayPrayers.maghrib;
    } else {
      // After Isha, next is tomorrow's Fajr
      nextPrayer = PrayerType.fajr;
      targetTime = dayPrayers.scheduleItems.first.endTime; // Tomorrow's fajr approximated or schedule
      targetTime = dayPrayers.fajr.add(const Duration(days: 1));
      prevTime = dayPrayers.isha;
    }

    final remaining = targetTime.difference(now);
    final totalWindow = targetTime.difference(prevTime).inSeconds;
    final elapsed = now.difference(prevTime).inSeconds;
    final progress = totalWindow > 0 ? (elapsed / totalWindow).clamp(0.0, 1.0) : 0.0;

    return NextPrayerCountdown(
      nextPrayer: nextPrayer,
      prayerName: nextPrayer.displayName,
      targetTime: targetTime,
      remaining: remaining.isNegative ? Duration.zero : remaining,
      progress: progress,
    );
  }
}

