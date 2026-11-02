import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../app/theme/app_colors.dart';
import '../../prayer_times/domain/prayer_model.dart';
import '../../prayer_times/presentation/prayer_providers.dart';
import '../../../app/theme/app_fonts.dart';
import '../../settings/presentation/notification_settings_provider.dart';

class RamadanChecklistScreen extends ConsumerWidget {
  const RamadanChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayPrayersAsync = ref.watch(todayPrayerTimesProvider);
    final alarms = ref.watch(prayerAlarmProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.islamicGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top App Bar with back button
                Row(
                  children: [
                    const AppBackButton(),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Ramadan Activity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40), // Balances back button
                  ],
                ),

                const SizedBox(height: 12),

                // Calligraphy Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    // No letterSpacing: it breaks the joins between Arabic letters.
                    child: Text(
                      'رَمَضَان كَرِيم',
                      textDirection: TextDirection.rtl,
                      style: AppFonts.arabicStyle(
                        color: AppColors.gold,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Dark Translucent Prayer Cards
                Expanded(
                  child: dayPrayersAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                    error: (e, _) => Center(
                      child: Text('Error: $e', style: const TextStyle(color: Colors.white)),
                    ),
                    data: (dayPrayers) {
                      final timeFormat = DateFormat('hh:mm a');
                      return ListView.separated(
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        itemCount: dayPrayers.scheduleItems.take(4).length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = dayPrayers.scheduleItems[index];
                          final startStr = timeFormat.format(item.startTime);
                          final endStr = timeFormat.format(item.endTime);
                          final isAlarm = alarms[item.type] ?? false;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.type.iconData,
                                  color: AppColors.gold,
                                  size: 20,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$startStr-$endStr',
                                        style: const TextStyle(
                                          color: AppColors.textLightSubdued,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isAlarm
                                        ? LucideIcons.volume2
                                        : LucideIcons.volumeOff,
                                    color: isAlarm
                                        ? AppColors.gold
                                        : Colors.white38,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    ref
                                        .read(prayerAlarmProvider.notifier)
                                        .toggleAlarm(item.type);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom Titles & CTA
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Daily Checklist\nRamadan Activity',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Plan and make it easy to track activities in the month of Ramadan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textLightSubdued,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 3 Dots / Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 22,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Big Golden CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.primaryDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => context.go('/prayers'),
                        child: const Text(
                          'Explore Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
