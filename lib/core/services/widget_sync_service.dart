import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../../features/prayer_times/domain/city_model.dart';
import '../../features/prayer_times/domain/prayer_model.dart';
import '../utils/bangla_numbers.dart';

class WidgetSyncService {
  WidgetSyncService._();
  static final WidgetSyncService instance = WidgetSyncService._();

  Future<void> syncAllWidgets({
    required CityModel city,
    required DayPrayerTimes dayPrayers,
    required String hijriDateString,
    String? currentWaqtName,
    String? nextWaqtName,
    DateTime? nextWaqtTime,
    Duration? remainingDuration,
  }) async {
    try {
      // 1. Saom Timer Data
      final sehriStr = dayPrayers.sehriEnd != null
          ? BanglaUtils.formatBanglaTime(dayPrayers.sehriEnd!)
          : BanglaUtils.formatBanglaTime(dayPrayers.fajr);
      final iftarStr = dayPrayers.iftar != null
          ? BanglaUtils.formatBanglaTime(dayPrayers.iftar!)
          : BanglaUtils.formatBanglaTime(dayPrayers.maghrib);

      String saomCountdownStr = 'রোজা পালনের প্রস্তুতি নিন';
      final now = DateTime.now();

      if (dayPrayers.sehriEnd != null && now.isBefore(dayPrayers.sehriEnd!)) {
        final diff = dayPrayers.sehriEnd!.difference(now);
        final hours = diff.inHours;
        final mins = diff.inMinutes.remainder(60);
        saomCountdownStr =
            'সাহরির বাকি: ${hours > 0 ? "${BanglaUtils.toBanglaDigits(hours)} ঘন্টা " : ""}${BanglaUtils.toBanglaDigits(mins)} মিনিট';
      } else if (dayPrayers.iftar != null && now.isBefore(dayPrayers.iftar!)) {
        final diff = dayPrayers.iftar!.difference(now);
        final hours = diff.inHours;
        final mins = diff.inMinutes.remainder(60);
        saomCountdownStr =
            'ইফতারের বাকি: ${hours > 0 ? "${BanglaUtils.toBanglaDigits(hours)} ঘন্টা " : ""}${BanglaUtils.toBanglaDigits(mins)} মিনিট';
      }

      await HomeWidget.saveWidgetData<String>('saom_location', city.name);
      await HomeWidget.saveWidgetData<String>('saom_sehri', sehriStr);
      await HomeWidget.saveWidgetData<String>('saom_iftar', iftarStr);
      await HomeWidget.saveWidgetData<String>('saom_countdown', saomCountdownStr);

      await HomeWidget.updateWidget(
        androidName: 'SaomTimerWidgetProvider',
      );

      // 2. Day Summary Data
      String nextWaqtDisplay = 'ওয়াক্ত লোড হচ্ছে...';
      String countdownDisplay = 'ওয়াক্ত সমাপ্তির অপেক্ষা';

      if (nextWaqtName != null && nextWaqtTime != null) {
        nextWaqtDisplay =
            'পরবর্তী: $nextWaqtName (${BanglaUtils.formatBanglaTime(nextWaqtTime)})';
      }

      if (remainingDuration != null) {
        final hours = remainingDuration.inHours;
        final mins = remainingDuration.inMinutes.remainder(60);
        countdownDisplay =
            'বাকি: ${hours > 0 ? "${BanglaUtils.toBanglaDigits(hours)} ঘন্টা " : ""}${BanglaUtils.toBanglaDigits(mins)} মিনিট';
      }

      await HomeWidget.saveWidgetData<String>('summary_hijri', hijriDateString);
      await HomeWidget.saveWidgetData<String>('summary_location', city.name);
      await HomeWidget.saveWidgetData<String>(
        'summary_current_waqt',
        currentWaqtName != null
            ? 'বর্তমান ওয়াক্ত: $currentWaqtName'
            : 'ওয়াক্ত চলমান',
      );
      await HomeWidget.saveWidgetData<String>('summary_next_waqt', nextWaqtDisplay);
      await HomeWidget.saveWidgetData<String>('summary_countdown', countdownDisplay);

      await HomeWidget.updateWidget(
        androidName: 'DaySummaryWidgetProvider',
      );

      // 3. 5 Prayer Times List
      await HomeWidget.saveWidgetData<String>('list_city', city.name);
      await HomeWidget.saveWidgetData<String>(
        'list_fajr',
        BanglaUtils.toBanglaDigits(DateFormat('hh:mm').format(dayPrayers.fajr)),
      );
      await HomeWidget.saveWidgetData<String>(
        'list_dhuhr',
        BanglaUtils.toBanglaDigits(DateFormat('hh:mm').format(dayPrayers.dhuhr)),
      );
      await HomeWidget.saveWidgetData<String>(
        'list_asr',
        BanglaUtils.toBanglaDigits(DateFormat('hh:mm').format(dayPrayers.asr)),
      );
      await HomeWidget.saveWidgetData<String>(
        'list_maghrib',
        BanglaUtils.toBanglaDigits(DateFormat('hh:mm').format(dayPrayers.maghrib)),
      );
      await HomeWidget.saveWidgetData<String>(
        'list_isha',
        BanglaUtils.toBanglaDigits(DateFormat('hh:mm').format(dayPrayers.isha)),
      );

      await HomeWidget.updateWidget(
        androidName: 'PrayerListWidgetProvider',
      );

      debugPrint('Successfully synchronized 3 Home Screen Widgets.');
    } catch (e) {
      debugPrint('Error syncing widgets with native platform: $e');
    }
  }
}
