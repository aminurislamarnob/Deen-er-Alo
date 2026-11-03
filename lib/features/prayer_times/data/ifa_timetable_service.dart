import 'dart:convert';
import 'package:flutter/services.dart';

class IFBScheduleResult {
  final DateTime sehriEnd;
  final DateTime fajrStart;
  final DateTime iftarTime;
  final DateTime? sunrise;
  final DateTime? dhuhr;
  final DateTime? asr;
  final DateTime? isha;

  const IFBScheduleResult({
    required this.sehriEnd,
    required this.fajrStart,
    required this.iftarTime,
    this.sunrise,
    this.dhuhr,
    this.asr,
    this.isha,
  });
}

typedef IFAScheduleResult = IFBScheduleResult;
typedef IFATimetableService = IFBTimetableService;

class IFBTimetableService {
  Map<String, dynamic>? _cachedData;

  static const List<int> _daysBeforeMonth = [
    0,   // Jan (31 days)
    31,  // Feb (29 days in leap year table)
    60,  // Mar (31 days)
    91,  // Apr (30 days)
    121, // May (31 days)
    152, // Jun (30 days)
    182, // Jul (31 days)
    213, // Aug (31 days)
    244, // Sep (30 days)
    274, // Oct (31 days)
    305, // Nov (30 days)
    335, // Dec (31 days)
  ];

  Future<void> _ensureLoaded() async {
    if (_cachedData != null) return;
    final jsonStr = await rootBundle.loadString('assets/data/ifb_times.json');
    _cachedData = json.decode(jsonStr) as Map<String, dynamic>;
  }

  /// Returns the leap-year day index (0..365) for [date].
  ///
  /// In non-leap years, February 29 (day index 59) is skipped, so March 1
  /// maps directly to index 60 (the 60th day of the solar calendar).
  int getDayIndex(DateTime date) {
    final monthIdx = (date.month - 1).clamp(0, 11);
    final dayOffset = (date.day - 1);
    return (_daysBeforeMonth[monthIdx] + dayOffset).clamp(0, 365);
  }

  Future<IFBScheduleResult?> getSchedule({
    required int districtId,
    required DateTime date,
  }) async {
    await _ensureLoaded();
    if (_cachedData == null) return null;

    final districts = _cachedData!['districts'] as Map<String, dynamic>?;
    if (districts == null) return null;

    final distKey = districtId.toString();
    final districtData = districts[distKey] as Map<String, dynamic>?;
    if (districtData == null) return null;

    final dayIndex = getDayIndex(date);

    final sehriList = districtData['sehri'] as List<dynamic>?;
    final fajrList = districtData['fajr'] as List<dynamic>?;
    final iftarList = districtData['iftar'] as List<dynamic>?;

    if (sehriList == null || fajrList == null || iftarList == null) return null;
    if (dayIndex >= sehriList.length ||
        dayIndex >= fajrList.length ||
        dayIndex >= iftarList.length) {
      return null;
    }

    final sStr = sehriList[dayIndex] as String;
    final fsStr = fajrList[dayIndex] as String;
    final iStr = iftarList[dayIndex] as String;

    final sehri = _parseTime(date, sStr, isPM: false);
    final fajr = _parseTime(date, fsStr, isPM: false);
    final iftar = _parseTime(date, iStr, isPM: true);

    DateTime? sunrise;
    DateTime? dhuhr;
    DateTime? asr;
    DateTime? isha;

    // For Dhaka (district 8486), full official times are bundled in dhaka_full
    if (districtId == 8486) {
      final dhakaFull = _cachedData!['dhaka_full'] as Map<String, dynamic>?;
      if (dhakaFull != null) {
        final sunList = dhakaFull['sunrise'] as List<dynamic>?;
        final dhuList = dhakaFull['dhuhr'] as List<dynamic>?;
        final asrList = dhakaFull['asr'] as List<dynamic>?;
        final ishaList = dhakaFull['isha'] as List<dynamic>?;

        if (sunList != null && dayIndex < sunList.length) {
          sunrise = _parseTime(date, sunList[dayIndex] as String, isPM: false);
        }
        if (dhuList != null && dayIndex < dhuList.length) {
          // Dhuhr is either 11:xx or 12:xx, parsing as isPM: false preserves both
          dhuhr = _parseTime(date, dhuList[dayIndex] as String, isPM: false);
        }
        if (asrList != null && dayIndex < asrList.length) {
          asr = _parseTime(date, asrList[dayIndex] as String, isPM: true);
        }
        if (ishaList != null && dayIndex < ishaList.length) {
          isha = _parseTime(date, ishaList[dayIndex] as String, isPM: true);
        }
      }
    }

    return IFBScheduleResult(
      sehriEnd: sehri,
      fajrStart: fajr,
      iftarTime: iftar,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      isha: isha,
    );
  }

  DateTime _parseTime(DateTime baseDate, String timeStr, {required bool isPM}) {
    final parts = timeStr.split(':');
    var hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    if (isPM && hour < 12) {
      hour += 12;
    }

    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      hour,
      minute,
    );
  }
}
