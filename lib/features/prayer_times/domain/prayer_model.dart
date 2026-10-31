import 'package:flutter/material.dart';

enum PrayerType {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
}

extension PrayerTypeX on PrayerType {
  String get displayName {
    switch (this) {
      case PrayerType.fajr:
        return 'Fazr';
      case PrayerType.sunrise:
        return 'Sunrise';
      case PrayerType.dhuhr:
        return 'Dhuhr';
      case PrayerType.asr:
        return 'Asr';
      case PrayerType.maghrib:
        return 'Iftar';
      case PrayerType.isha:
        return 'Esha';
    }
  }

  String get bengaliName {
    switch (this) {
      case PrayerType.fajr:
        return 'ফজর';
      case PrayerType.sunrise:
        return 'সূর্যোদয়';
      case PrayerType.dhuhr:
        return 'যোহর';
      case PrayerType.asr:
        return 'আসর';
      case PrayerType.maghrib:
        return 'মাগরিব (ইফতার)';
      case PrayerType.isha:
        return 'এশা';
    }
  }

  IconData get iconData {
    switch (this) {
      case PrayerType.fajr:
        return Icons.wb_twilight_rounded;
      case PrayerType.sunrise:
        return Icons.wb_sunny_outlined;
      case PrayerType.dhuhr:
        return Icons.wb_sunny_rounded;
      case PrayerType.asr:
        return Icons.wb_cloudy_rounded;
      case PrayerType.maghrib:
        return Icons.nights_stay_outlined;
      case PrayerType.isha:
        return Icons.bedtime_rounded;
    }
  }
}

class PrayerScheduleItem {
  final PrayerType type;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAlarmActive;
  final bool isCurrent;
  final bool isNext;

  const PrayerScheduleItem({
    required this.type,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.isAlarmActive = true,
    this.isCurrent = false,
    this.isNext = false,
  });

  PrayerScheduleItem copyWith({
    bool? isAlarmActive,
    bool? isCurrent,
    bool? isNext,
  }) {
    return PrayerScheduleItem(
      type: type,
      title: title,
      startTime: startTime,
      endTime: endTime,
      isAlarmActive: isAlarmActive ?? this.isAlarmActive,
      isCurrent: isCurrent ?? this.isCurrent,
      isNext: isNext ?? this.isNext,
    );
  }
}

class DayPrayerTimes {
  final DateTime date;
  final String cityName;
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime? sehriEnd; // If available (e.g. from IFA)
  final DateTime? iftar;    // If available (from IFA or Maghrib)
  final List<PrayerScheduleItem> scheduleItems;

  const DayPrayerTimes({
    required this.date,
    required this.cityName,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.sehriEnd,
    this.iftar,
    required this.scheduleItems,
  });
}

class NextPrayerCountdown {
  final PrayerType nextPrayer;
  final String prayerName;
  final DateTime targetTime;
  final Duration remaining;
  final double progress; // 0.0 to 1.0 between previous prayer and next prayer

  const NextPrayerCountdown({
    required this.nextPrayer,
    required this.prayerName,
    required this.targetTime,
    required this.remaining,
    required this.progress,
  });
}
