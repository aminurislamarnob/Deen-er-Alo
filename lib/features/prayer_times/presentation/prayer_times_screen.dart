import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import 'city_picker_sheet.dart';
import 'prayer_providers.dart';
import 'prohibited_times_sheet.dart';
import 'widgets/arc_timer_widget.dart';
import 'widgets/prayer_card_widget.dart';

class PrayerTimesScreen extends ConsumerWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCityAsync = ref.watch(selectedCityProvider);
    final selectedDate = ref.watch(selectedDateProvider);
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

    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    final dateDisplayFormat = DateFormat('EEE, d MMMM yyyy');

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
            physics: const BouncingScrollPhysics(),
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
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          // App Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Safe Back Button
                                InkWell(
                                  onTap: () {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    } else {
                                      context.go('/home');
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
                                      LucideIcons.arrowLeft,
                                      color: AppColors.primaryDark,
                                      size: 18,
                                    ),
                                  ),
                                ),

                                const Text(
                                  'নামাজের সময়সূচি (Prayer Times)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                // City & Location button
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.slidersHorizontal,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      CityPickerSheet.show(context),
                                ),
                              ],
                            ),
                          ),

                          // Date Switcher Row
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.chevronLeft,
                                        color: Colors.white, size: 20),
                                    onPressed: () {
                                      ref
                                          .read(selectedDateProvider.notifier)
                                          .state = selectedDate.subtract(
                                              const Duration(days: 1));
                                    },
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        ref
                                            .read(selectedDateProvider.notifier)
                                            .state = picked;
                                      }
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.calendar,
                                            color: AppColors.gold, size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          isToday
                                              ? 'আজ, ${dateDisplayFormat.format(selectedDate)}'
                                              : dateDisplayFormat
                                                  .format(selectedDate),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.chevronRight,
                                        color: Colors.white, size: 20),
                                    onPressed: () {
                                      ref
                                          .read(selectedDateProvider.notifier)
                                          .state = selectedDate.add(
                                              const Duration(days: 1));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

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

              // Curved White Sheet with Prayer List & Prohibited Times
              SliverToBoxAdapter(
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
                      // Top notch
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
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Prohibited Time Alert Pill
                            InkWell(
                              onTap: () => ProhibitedTimesSheet.show(context),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.bgLight,
                                  borderRadius: BorderRadius.circular(14),
                                  border:
                                      Border.all(color: AppColors.cardBorder),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(LucideIcons.triangleAlert,
                                        color: Color(0xFFEF4444), size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'আজকের নামাজের নিষিদ্ধ সময়সূচি দেখুন',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    Icon(LucideIcons.chevronRight,
                                        color: AppColors.textSubdued, size: 18),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Sunrise Notice Banner
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(LucideIcons.sunrise,
                                          color: Color(0xFFD97706), size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'সূর্যোদয় (Sunrise / ফজর শেষ)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    DateFormat('hh:mm a')
                                        .format(dayPrayers.sunrise),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 5 Prayer Cards
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
