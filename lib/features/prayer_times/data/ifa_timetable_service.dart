import 'dart:convert';
import 'package:flutter/services.dart';

class IFAScheduleResult {
  final DateTime sehriEnd;
  final DateTime fajrStart;
  final DateTime iftarTime;

  const IFAScheduleResult({
    required this.sehriEnd,
    required this.fajrStart,
    required this.iftarTime,
  });
}

class IFATimetableService {
  Map<String, dynamic>? _cachedIFAData;

  Future<void> _ensureLoaded() async {
    if (_cachedIFAData != null) return;
    final jsonStr = await rootBundle.loadString('assets/data/ifa_times.json');
    _cachedIFAData = json.decode(jsonStr) as Map<String, dynamic>;
  }

  Future<IFAScheduleResult?> getSchedule({
    required int districtId,
    required DateTime date,
  }) async {
    await _ensureLoaded();
    if (_cachedIFAData == null) return null;

    final key = districtId.toString();
    final districtSchedule = _cachedIFAData![key] as List<dynamic>?;
    if (districtSchedule == null || districtSchedule.isEmpty) return null;

    final monthIndex = (date.month - 1).clamp(0, 11);
    final monthDays = districtSchedule[monthIndex] as List<dynamic>?;
    if (monthDays == null || monthDays.isEmpty) return null;

    final dayIndex = (date.day - 1).clamp(0, monthDays.length - 1);
    final dayData = monthDays[dayIndex] as Map<String, dynamic>?;
    if (dayData == null) return null;

    final sStr = dayData['s'] as String? ?? '05:00';
    final fsStr = dayData['fs'] as String? ?? '05:03';
    final iStr = dayData['i'] as String? ?? '06:00';

    final sehri = _parseTime(date, sStr, isPM: false);
    final fajr = _parseTime(date, fsStr, isPM: false);
    final iftar = _parseTime(date, iStr, isPM: true);

    return IFAScheduleResult(
      sehriEnd: sehri,
      fajrStart: fajr,
      iftarTime: iftar,
    );
  }

  DateTime _parseTime(DateTime baseDate, String timeStr, {required bool isPM}) {
    final parts = timeStr.split(':');
    int hour = int.tryParse(parts[0]) ?? 0;
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

