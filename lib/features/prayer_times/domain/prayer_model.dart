import 'package:flutter/material.dart';
import 'package:deener_alo/core/constants/app_icons.dart';

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
        return 'Maghrib';
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
        return 'মাগরিব';
      case PrayerType.isha:
        return 'এশা';
    }
  }

  IconData get iconData {
    switch (this) {
      case PrayerType.fajr:
        return AppIcons.fajr;
      case PrayerType.sunrise:
        return AppIcons.sunrise;
      case PrayerType.dhuhr:
        return AppIcons.dhuhr;
      case PrayerType.asr:
        return AppIcons.asr;
      case PrayerType.maghrib:
        return AppIcons.maghrib;
      case PrayerType.isha:
        return AppIcons.isha;
    }
  }

  bool get isFard => this != PrayerType.sunrise;
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

  bool isActiveAt(DateTime now) {
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

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
  final DateTime? sehriEnd;
  final DateTime? iftar;
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
  final double progress;

  const NextPrayerCountdown({
    required this.nextPrayer,
    required this.prayerName,
    required this.targetTime,
    required this.remaining,
    required this.progress,
  });
}

class ProhibitedTimeRange {
  final String title;
  final String bengaliTitle;
  final DateTime startTime;
  final DateTime endTime;
  final String reason;

  const ProhibitedTimeRange({
    required this.title,
    required this.bengaliTitle,
    required this.startTime,
    required this.endTime,
    required this.reason,
  });

  bool contains(DateTime time) =>
      time.isAfter(startTime) && time.isBefore(endTime);
}
