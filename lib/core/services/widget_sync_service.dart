import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../../features/prayer_times/domain/city_model.dart';
import '../../features/prayer_times/domain/prayer_model.dart';
import '../utils/bangla_numbers.dart';
import '../utils/city_clock.dart';

/// Pushes a multi-day schedule to the native home screen widgets.
///
/// Widgets compute the current/next waqt themselves from epoch instants and
/// count down with a native `Chronometer`, so they stay live and roll over at
/// prayer boundaries and midnight without the app running. Display strings are
/// pre-formatted on the city's wall clock.
class WidgetSyncService {
  WidgetSyncService._();
  static final WidgetSyncService instance = WidgetSyncService._();

  static const String scheduleKey = 'widget_schedule_v2';

  static const List<String> _androidProviders = [
    'SaomTimerWidgetProvider',
    'DaySummaryWidgetProvider',
    'PrayerListWidgetProvider',
  ];

  /// Builds the JSON payload (pure; unit-testable).
  static Map<String, dynamic> buildPayload({
    required CityModel city,
    required List<DayPrayerTimes> days,
    required String Function(DateTime cityDate) hijriLabel,
  }) {
    final zone = city.effectiveTimeZone;
    int ms(DateTime wall) =>
        CityClock.toInstant(wall, zone).millisecondsSinceEpoch;
    String hm(DateTime wall) =>
        BanglaUtils.toBanglaDigits(DateFormat('hh:mm').format(wall));

    return {
      'version': 2,
      'city': city.name,
      'days': [
        for (final day in days)
          {
            'date': DateFormat('yyyy-MM-dd').format(day.date),
            'start': ms(day.date),
            'end': ms(DateTime(day.date.year, day.date.month, day.date.day + 1)),
            'hijri': hijriLabel(day.date),
            'sehri': ms(day.sehriEnd ?? day.fajr),
            'sehriText': BanglaUtils.formatBanglaTime(day.sehriEnd ?? day.fajr),
            'iftar': ms(day.iftar ?? day.maghrib),
            'iftarText': BanglaUtils.formatBanglaTime(day.iftar ?? day.maghrib),
            'prayers': [
              for (final item in day.scheduleItems)
                if (item.type.isFard)
                  {
                    'key': item.type.name,
                    'name': item.type.bengaliName,
                    'start': ms(item.startTime),
                    'end': ms(item.endTime),
                    'text': hm(item.startTime),
                  },
            ],
          },
      ],
    };
  }

  Future<void> syncSchedule({
    required CityModel city,
    required List<DayPrayerTimes> days,
    required String Function(DateTime cityDate) hijriLabel,
  }) async {
    if (days.isEmpty) return;
    try {
      final payload = buildPayload(city: city, days: days, hijriLabel: hijriLabel);
      await HomeWidget.saveWidgetData<String>(scheduleKey, json.encode(payload));
      for (final name in _androidProviders) {
        await HomeWidget.updateWidget(androidName: name);
      }
    } catch (e) {
      // Widgets are optional (e.g. iOS without an extension, or tests).
      debugPrint('Widget sync skipped: $e');
    }
  }
}
