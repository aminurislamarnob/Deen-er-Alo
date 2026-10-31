import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import 'city_picker_sheet.dart';
import 'prayer_providers.dart';
import 'widgets/arc_timer_widget.dart';
import 'widgets/prayer_card_widget.dart';

class PrayerTimesScreen extends ConsumerWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCityAsync = ref.watch(selectedCityProvider);
    final dayPrayersAsync = ref.watch(dayPrayerTimesProvider);
    final countdown = ref.watch(countdownProvider);
    final alarms = ref.watch(prayerAlarmProvider);
    final clock = ref.watch(clockStreamProvider);

    final now = clock.value ?? DateTime.now();
    final timeFormat = DateFormat('hh:mm');
    final periodFormat = DateFormat('a');
    final currentTimeStr = timeFormat.format(now);
    final currentPeriodStr = periodFormat.format(now);

    final city = selectedCityAsync.value;
    final locationLabel = city != null
        ? '${city.name}, ${city.countryName}'
        : 'Dhaka, Bangladesh';

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: dayPrayersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error loading prayer times: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (dayPrayers) {
          final timeFormatStat = DateFormat('hh:mm a');
          final fajrStr = timeFormatStat.format(dayPrayers.fajr);
          final iftarStr = timeFormatStat.format(dayPrayers.iftar ?? dayPrayers.maghrib);

          String nextPrayerLabel = countdown?.prayerName ?? 'Next';
          String remainingStr = '';
          if (countdown != null) {
            final hours = countdown.remaining.inHours;
            final mins = countdown.remaining.inMinutes.remainder(60);
            final secs = countdown.remaining.inSeconds.remainder(60);
            if (hours > 0) {
              remainingStr = '${hours}h ${mins}m';
            } else {
              remainingStr = '${mins}m ${secs}s';
            }
          }

          return CustomScrollView(
            slivers: [
              // Top Arc Header Sliver
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.islamicGradient,
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          // App Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Circular Back Button
                                InkWell(
                                  onTap: () {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_rounded,
                                      color: AppColors.primaryDark,
                                      size: 20,
                                    ),
                                  ),
                                ),

                                const Text(
                                  'Prayer Time',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                // Location change button
                                IconButton(
                                  icon: const Icon(
                                    Icons.tune_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  onPressed: () =>
                                      CityPickerSheet.show(context),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Arc Timer Widget
                          ArcTimerWidget(
                            locationText: locationLabel,
                            currentTimeString: currentTimeStr,
                            periodString: currentPeriodStr,
                            nextPrayerLabel: nextPrayerLabel,
                            nextPrayerRemaining: remainingStr,
                            progress: countdown?.progress ?? 0.0,
                            fajrTime: fajrStr,
                            iftarTime: iftarStr,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Curved White Sheet with Prayer List
              SliverFillRemaining(
                hasScrollBody: false,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // Little ornamental top notch
                      Positioned(
                        top: -6,
                        child: Container(
                          width: 32,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
                        child: Column(
                          children: [
                            for (int i = 0;
                                i < dayPrayers.scheduleItems.length;
                                i++) ...[
                              Builder(
                                builder: (context) {
                                  final item = dayPrayers.scheduleItems[i];
                                  final isAlarmOn =
                                      alarms[item.type] ?? false;
                                  final isLast =
                                      i == dayPrayers.scheduleItems.length - 1;

                                  return PrayerCardWidget(
                                    item: item,
                                    isAlarmActive: isAlarmOn,
                                    isLast: isLast,
                                    onToggleAlarm: () {
                                      ref
                                          .read(prayerAlarmProvider.notifier)
                                          .toggleAlarm(item.type);
                                    },
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

