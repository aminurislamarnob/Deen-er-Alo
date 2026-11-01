import 'package:adhan/adhan.dart';
import '../../../core/utils/city_clock.dart';
import '../domain/city_model.dart';
import '../domain/prayer_model.dart';
import 'ifa_timetable_service.dart';

class PrayerEngine {
  final IFATimetableService _ifaService;

  PrayerEngine({IFATimetableService? ifaService})
      : _ifaService = ifaService ?? IFATimetableService();

  /// Maximum plausible deviation between an IFA timetable entry and the
  /// astronomical calculation. Entries outside this window are treated as
  /// data errors and the calculated time is used instead.
  static const Duration ifaTolerance = Duration(minutes: 20);

  /// Calculates the prayer schedule for [date] (a date in the city's local
  /// calendar). All returned times are wall-clock times in the city's time
  /// zone (see [CityClock]).
  Future<DayPrayerTimes> calculateDayPrayers({
    required CityModel city,
    required DateTime date,
    DateTime? now,
  }) async {
    final zone = city.effectiveTimeZone;
    final day = CityClock.dateOnly(date);
    final effectiveNow = now ?? CityClock.now(zone);

    final today = _adhanDay(city, day);
    final nextDay = DateTime(day.year, day.month, day.day + 1);
    final tomorrow = _adhanDay(city, nextDay);

    DateTime fajr = today.fajr;
    final DateTime sunrise = today.sunrise;
    final DateTime dhuhr = today.dhuhr;
    final DateTime asr = today.asr;
    DateTime maghrib = today.maghrib;
    final DateTime isha = today.isha;
    DateTime nextFajr = tomorrow.fajr;

    DateTime? sehriEnd;
    DateTime? iftarTime;

    // Bangladesh Islamic Foundation (IFA) timetable override. IFA times are
    // Asia/Dhaka wall-clock times, which is the zone of every BD district.
    if (_isBangladesh(city) && zone == 'Asia/Dhaka') {
      final ifa = await _safeIfa(city.id, day);
      if (ifa != null &&
          _withinTolerance(ifa.fajrStart, fajr) &&
          _withinTolerance(ifa.iftarTime, maghrib)) {
        sehriEnd = ifa.sehriEnd;
        fajr = ifa.fajrStart;
        iftarTime = ifa.iftarTime;
        maghrib = ifa.iftarTime;
      }
      final nextIfa = await _safeIfa(city.id, nextDay);
      if (nextIfa != null && _withinTolerance(nextIfa.fajrStart, nextFajr)) {
        nextFajr = nextIfa.fajrStart;
      }
    }

    sehriEnd ??= fajr.subtract(const Duration(minutes: 3));
    iftarTime ??= maghrib;

    final base = DayPrayerTimes(
      date: day,
      cityName: city.name,
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
      sehriEnd: sehriEnd,
      iftar: iftarTime,
      scheduleItems: [
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
      ],
    );
    return markCurrent(base, effectiveNow);
  }

  /// Returns a copy of [dayPrayers] whose `isCurrent` / `isNext` flags reflect
  /// [now] (a wall-clock time in the city's zone). Between midnight and Fajr
  /// the previous night's Isha is considered current.
  DayPrayerTimes markCurrent(DayPrayerTimes dayPrayers, DateTime now) {
    final isSameDate = now.year == dayPrayers.date.year &&
        now.month == dayPrayers.date.month &&
        now.day == dayPrayers.date.day;

    PrayerType? current;
    if (isSameDate) {
      if (now.isBefore(dayPrayers.fajr)) {
        current = PrayerType.isha;
      } else {
        for (final item in dayPrayers.scheduleItems) {
          if (!now.isBefore(item.startTime) && now.isBefore(item.endTime)) {
            current = item.type;
            break;
          }
        }
      }
    }

    PrayerType? next;
    if (isSameDate) {
      for (final item in dayPrayers.scheduleItems) {
        if (now.isBefore(item.startTime)) {
          next = item.type;
          break;
        }
      }
    }

    return DayPrayerTimes(
      date: dayPrayers.date,
      cityName: dayPrayers.cityName,
      fajr: dayPrayers.fajr,
      sunrise: dayPrayers.sunrise,
      dhuhr: dayPrayers.dhuhr,
      asr: dayPrayers.asr,
      maghrib: dayPrayers.maghrib,
      isha: dayPrayers.isha,
      sehriEnd: dayPrayers.sehriEnd,
      iftar: dayPrayers.iftar,
      scheduleItems: [
        for (final item in dayPrayers.scheduleItems)
          item.copyWith(
            isCurrent: item.type == current,
            isNext: item.type == next,
          ),
      ],
    );
  }

  /// Countdown to the next event for the Home dashboard. [now] is a wall-clock
  /// time in the city's zone and [dayPrayers] is *today's* schedule.
  ///
  /// During Fajr the countdown targets sunrise (end of Fajr); after Isha it
  /// targets tomorrow's Fajr using the real next-day time.
  NextPrayerCountdown calculateCountdown({
    required DayPrayerTimes dayPrayers,
    required DateTime now,
  }) {
    final nextFajr = dayPrayers.scheduleItems
        .firstWhere((i) => i.type == PrayerType.isha)
        .endTime;
    // Previous night's Isha, approximated from today's Isha.
    final prevIsha = DateTime(
      dayPrayers.isha.year,
      dayPrayers.isha.month,
      dayPrayers.isha.day - 1,
      dayPrayers.isha.hour,
      dayPrayers.isha.minute,
    );

    late final PrayerType nextPrayer;
    late final DateTime targetTime;
    late final DateTime prevTime;

    if (now.isBefore(dayPrayers.fajr)) {
      nextPrayer = PrayerType.fajr;
      targetTime = dayPrayers.fajr;
      prevTime = prevIsha;
    } else if (now.isBefore(dayPrayers.sunrise)) {
      nextPrayer = PrayerType.sunrise;
      targetTime = dayPrayers.sunrise;
      prevTime = dayPrayers.fajr;
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
      targetTime = nextFajr;
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

  _DayTimes _adhanDay(CityModel city, DateTime day) {
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;
    final zone = city.effectiveTimeZone;
    final components = DateComponents(day.year, day.month, day.day);
    final coordinates = Coordinates(city.latitude, city.longitude);

    if (!CityClock.isValidZone(zone)) {
      // Unknown zone: device-local times (legacy behaviour).
      return _DayTimes.from(
        PrayerTimes(coordinates, components, params),
        (t) => t.toLocal(),
      );
    }
    // Offset at local noon handles DST days correctly enough for prayers.
    final noon = CityClock.toInstant(
      DateTime(day.year, day.month, day.day, 12),
      zone,
    );
    final offset = CityClock.offsetAt(zone, noon);
    return _DayTimes.from(
      PrayerTimes(coordinates, components, params, utcOffset: offset),
      CityClock.stripUtcFlag,
    );
  }

  bool _isBangladesh(CityModel city) =>
      city.isBangladeshDistrict ||
      city.countryName.toLowerCase() == 'bangladesh';

  bool _withinTolerance(DateTime a, DateTime b) =>
      a.difference(b).abs() <= ifaTolerance;

  Future<IFAScheduleResult?> _safeIfa(int districtId, DateTime date) async {
    try {
      return await _ifaService.getSchedule(districtId: districtId, date: date);
    } catch (_) {
      return null; // Fall back to astronomical times.
    }
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

/// One day of astronomical times as plain wall-clock [DateTime]s.
class _DayTimes {
  final DateTime fajr, sunrise, dhuhr, asr, maghrib, isha;

  const _DayTimes(
    this.fajr,
    this.sunrise,
    this.dhuhr,
    this.asr,
    this.maghrib,
    this.isha,
  );

  factory _DayTimes.from(PrayerTimes p, DateTime Function(DateTime) map) =>
      _DayTimes(
        map(p.fajr),
        map(p.sunrise),
        map(p.dhuhr),
        map(p.asr),
        map(p.maghrib),
        map(p.isha),
      );
}
