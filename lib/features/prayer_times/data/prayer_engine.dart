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
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();
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

    // Check Bangladesh Islamic Foundation (IFA) schedule override if applicable
    if (city.isBangladeshDistrict ||
        city.countryName.toLowerCase() == 'bangladesh') {
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
    final nextDayComponents =
        DateComponents(nextDayDate.year, nextDayDate.month, nextDayDate.day);
    final nextDayAdhan = PrayerTimes(coordinates, nextDayComponents, params);
    DateTime nextFajr = nextDayAdhan.fajr;

    if (city.isBangladeshDistrict ||
        city.countryName.toLowerCase() == 'bangladesh') {
      final nextDayIfa = await _ifaService.getSchedule(
        districtId: city.id,
        date: nextDayDate,
      );
      if (nextDayIfa != null) {
        nextFajr = nextDayIfa.fajrStart;
      }
    }

    // Determine currently active prayer interval
    final isSameDate = effectiveNow.year == date.year &&
        effectiveNow.month == date.month &&
        effectiveNow.day == date.day;

    bool isCurrentFajr = isSameDate &&
        effectiveNow.isAfter(fajr) &&
        effectiveNow.isBefore(sunrise);
    bool isCurrentDhuhr = isSameDate &&
        effectiveNow.isAfter(dhuhr) &&
        effectiveNow.isBefore(asr);
    bool isCurrentAsr = isSameDate &&
        effectiveNow.isAfter(asr) &&
        effectiveNow.isBefore(maghrib);
    bool isCurrentMaghrib = isSameDate &&
        effectiveNow.isAfter(maghrib) &&
        effectiveNow.isBefore(isha);
    bool isCurrentIsha = isSameDate &&
        (effectiveNow.isAfter(isha) || effectiveNow.isBefore(fajr));

    final scheduleItems = [
      PrayerScheduleItem(
        type: PrayerType.fajr,
        title: PrayerType.fajr.displayName,
        startTime: fajr,
        endTime: sunrise,
        isCurrent: isCurrentFajr,
      ),
      PrayerScheduleItem(
        type: PrayerType.dhuhr,
        title: PrayerType.dhuhr.displayName,
        startTime: dhuhr,
        endTime: asr,
        isCurrent: isCurrentDhuhr,
      ),
      PrayerScheduleItem(
        type: PrayerType.asr,
        title: PrayerType.asr.displayName,
        startTime: asr,
        endTime: maghrib,
        isCurrent: isCurrentAsr,
      ),
      PrayerScheduleItem(
        type: PrayerType.maghrib,
        title: PrayerType.maghrib.displayName,
        startTime: maghrib,
        endTime: isha,
        isCurrent: isCurrentMaghrib,
      ),
      PrayerScheduleItem(
        type: PrayerType.isha,
        title: PrayerType.isha.displayName,
        startTime: isha,
        endTime: nextFajr,
        isCurrent: isCurrentIsha,
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
      prevTime = dayPrayers.sunrise;
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
      nextPrayer = PrayerType.fajr;
      targetTime = dayPrayers.fajr.add(const Duration(days: 1));
      prevTime = dayPrayers.isha;
    }

    final remaining = targetTime.difference(now);
    final totalWindow = targetTime.difference(prevTime).inSeconds;
    final elapsed = now.difference(prevTime).inSeconds;
    final progress =
        totalWindow > 0 ? (elapsed / totalWindow).clamp(0.0, 1.0) : 0.0;

    return NextPrayerCountdown(
      nextPrayer: nextPrayer,
      prayerName: nextPrayer.displayName,
      targetTime: targetTime,
      remaining: remaining.isNegative ? Duration.zero : remaining,
      progress: progress,
    );
  }

  List<ProhibitedTimeRange> getProhibitedTimes(DayPrayerTimes dayPrayers) {
    return [
      ProhibitedTimeRange(
        title: 'Sunrise (সূর্যোদয়)',
        bengaliTitle: 'সূর্যোদয়ের সময়',
        startTime: dayPrayers.sunrise,
        endTime: dayPrayers.sunrise.add(const Duration(minutes: 15)),
        reason: 'সূর্য ওঠার সময় থেকে আনুমানিক ১৫ মিনিট পর্যন্ত নামাজ পড়া নিষিদ্ধ।',
      ),
      ProhibitedTimeRange(
        title: 'Midday Zenith (দ্বিপ্রহর / যাওয়াল)',
        bengaliTitle: 'ঠিক দ্বিপ্রহরের সময়',
        startTime: dayPrayers.dhuhr.subtract(const Duration(minutes: 10)),
        endTime: dayPrayers.dhuhr,
        reason: 'সূর্য ঠিক মাথার ওপর থাকা অবস্থায় (যোহরের ওয়াক্ত হওয়ার পূর্বের ১০ মিনিট) নামাজ নিষিদ্ধ।',
      ),
      ProhibitedTimeRange(
        title: 'Sunset (সূর্যাস্ত)',
        bengaliTitle: 'সূর্যাস্তের সময়',
        startTime: dayPrayers.maghrib.subtract(const Duration(minutes: 15)),
        endTime: dayPrayers.maghrib,
        reason: 'সূর্য ডোবার পূর্ববর্তী আনুমানিক ১৫ মিনিট (সূর্য হলুদ বর্ণ ধারণ থেকে ডোবা পর্যন্ত) নামাজ নিষিদ্ধ (সেদিনের আসর কাজা না থাকলে)।',
      ),
    ];
  }

  ProhibitedTimeRange? getCurrentProhibitedTime(
      DayPrayerTimes dayPrayers, DateTime now) {
    final ranges = getProhibitedTimes(dayPrayers);
    for (final r in ranges) {
      if (r.contains(now)) {
        return r;
      }
    }
    return null;
  }
}
