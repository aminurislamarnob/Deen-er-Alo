import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/services/widget_sync_service.dart';
import '../../../core/utils/bangla_numbers.dart';
import '../../prayer_times/domain/prayer_model.dart';
import '../../prayer_times/presentation/city_picker_sheet.dart';
import '../../prayer_times/presentation/prayer_providers.dart';
import '../../prayer_times/presentation/prohibited_times_sheet.dart';
import '../data/hadith_repository.dart';
import 'fasting_provider.dart';
import 'prayer_tracker_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCityAsync = ref.watch(selectedCityProvider);
    final dayPrayersAsync = ref.watch(dayPrayerTimesProvider);
    final countdown = ref.watch(countdownProvider);
    final clock = ref.watch(clockStreamProvider);
    final fasting = ref.watch(fastingProvider);
    final prayerTracker = ref.watch(prayerTrackerProvider);
    final dailyHadithAsync = ref.watch(dailyHadithProvider);

    // Sync Home Screen Widgets whenever prayer times or city is updated
    ref.listen(dayPrayerTimesProvider, (prev, next) {
      final prayers = next.valueOrNull;
      final currentCity = ref.read(selectedCityProvider).valueOrNull;
      if (prayers != null && currentCity != null) {
        final currentCountdown = ref.read(countdownProvider);
        final hijri = HijriCalendar.now();
        final hMonth =
            BanglaUtils.hijriMonthBengali[hijri.hMonth] ?? hijri.longMonthName;
        final hDate =
            '${BanglaUtils.toBanglaDigits(hijri.hDay)} $hMonth, ${BanglaUtils.toBanglaDigits(hijri.hYear)} হিজরি';

        WidgetSyncService.instance.syncAllWidgets(
          city: currentCity,
          dayPrayers: prayers,
          hijriDateString: hDate,
          nextWaqtName: currentCountdown?.prayerName,
          nextWaqtTime: currentCountdown?.targetTime,
          remainingDuration: currentCountdown?.remaining,
        );
      }
    });

    final now = clock.value ?? DateTime.now();
    final timeFormat = DateFormat('hh:mm');
    final periodFormat = DateFormat('a');
    final gregorianDateFormat = DateFormat('EEEE, d MMM yyyy');

    final city = selectedCityAsync.value;
    final locationLabel = city != null
        ? '${city.name}, ${city.countryName}'
        : 'Dhaka, Bangladesh';

    // Hijri date calculation
    final hijriNow = HijriCalendar.now();
    final hijriMonthBn =
        BanglaUtils.hijriMonthBengali[hijriNow.hMonth] ??
        hijriNow.longMonthName;
    final hijriDateStr =
        '${BanglaUtils.toBanglaDigits(hijriNow.hDay)} $hijriMonthBn, ${BanglaUtils.toBanglaDigits(hijriNow.hYear)} হিজরি';

    return Scaffold(
      backgroundColor: AppColors.primaryMedium,
      body: ColoredBox(
        color: AppColors.primaryMedium,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Islamic Header Area
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.islamicGradient,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Bar: App Identity & Location Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.gold,
                                      width: 1.5,
                                    ),
                                    image: const DecorationImage(
                                      image: AssetImage(
                                        'assets/images/app_logo.jpg',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'দ্বীনের আলো',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    Text(
                                      'Deener Alo • Daily Companion',
                                      style: TextStyle(
                                        color: AppColors.textLightSubdued,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Location Picker Button
                            InkWell(
                              onTap: () => CityPickerSheet.show(context),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.mapPin,
                                      color: AppColors.gold,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      city?.name ?? 'Dhaka',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      LucideIcons.chevronDown,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Hijri & Gregorian Calendar Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.calendar,
                                color: AppColors.gold,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hijriDateStr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      gregorianDateFormat.format(now),
                                      style: const TextStyle(
                                        color: AppColors.textLightSubdued,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                city?.isBangladeshDistrict == true
                                    ? 'ইফা সময়সূচি'
                                    : 'Karachi Method',
                                style: const TextStyle(
                                  color: AppColors.goldLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Hero Prayer Card (Current & Next Prayer with Countdown)
                        _buildHeroPrayerCard(
                          context: context,
                          dayPrayersAsync: dayPrayersAsync,
                          countdown: countdown,
                          currentTime: timeFormat.format(now),
                          period: periodFormat.format(now),
                          location: locationLabel,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Main Content Container
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Horizontal Prayer Times Quick Bar
                    _buildSectionTitle(
                      'আজকের নামাজের ওয়াক্ত (PRAYER TIMES)',
                      onSeeAll: () => context.go('/prayers'),
                    ),
                    const SizedBox(height: 10),
                    _buildTodayPrayerTimesCarousel(ref, dayPrayersAsync),

                    const SizedBox(height: 22),

                    // Islamic Tools Grid
                    _buildSectionTitle('ইসলামিক প্রয়োজনীয় টুলস (CORE TOOLS)'),
                    const SizedBox(height: 10),
                    _buildToolsGrid(context),

                    const SizedBox(height: 22),

                    // 5 Daily Prayers Checklist / Tracker
                    _buildSectionTitle(
                      'আজকের নামাজের ট্র্যাকার (PRAYER TRACKER)',
                    ),
                    const SizedBox(height: 10),
                    _buildPrayerTrackerCard(ref, prayerTracker),

                    const SizedBox(height: 22),

                    // Fasting & Sehri-Iftar Card
                    _buildSectionTitle('রোজা ও সেহরি-ইফতার (SAOM & IFTAR)'),
                    const SizedBox(height: 10),
                    _buildFastingCard(ref, fasting, dayPrayersAsync),

                    const SizedBox(height: 22),

                    // Hadith of the Day
                    _buildSectionTitle('আজকের হাদিস (HADITH OF THE DAY)'),
                    const SizedBox(height: 10),
                    _buildDailyHadithCard(dailyHadithAsync),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSubdued,
            letterSpacing: 0.6,
          ),
        ),
        if (onSeeAll != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'সব দেখুন',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 13,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeroPrayerCard({
    required BuildContext context,
    required AsyncValue<DayPrayerTimes> dayPrayersAsync,
    required NextPrayerCountdown? countdown,
    required String currentTime,
    required String period,
    required String location,
  }) {
    return InkWell(
      onTap: () => context.go('/prayers'),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF13533A), Color(0xFF1C6B4C), Color(0xFF0F432E)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Row: Current Time & Next Prayer Label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currentTime,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          period,
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location,
                      style: const TextStyle(
                        color: AppColors.textLightSubdued,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Next Prayer Countdown Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'পরবর্তী: ${countdown?.prayerName ?? "নামাজ"}',
                        style: const TextStyle(
                          color: AppColors.goldLight,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        countdown != null
                            ? '${countdown.remaining.inHours}ঘণ্টা ${countdown.remaining.inMinutes.remainder(60)}মিনিট বাকি'
                            : 'হিসাব হচ্ছে...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Bar for current prayer interval
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: countdown?.progress ?? 0.0,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Sehri, Fajr, Sunrise, Iftar row
            dayPrayersAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (dayPrayers) {
                final format = DateFormat('hh:mm a');
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatPill(
                      'সেহরি শেষ',
                      format.format(dayPrayers.sehriEnd ?? dayPrayers.fajr),
                    ),
                    _buildStatPill('ফজর', format.format(dayPrayers.fajr)),
                    _buildStatPill(
                      'সূর্যোদয়',
                      format.format(dayPrayers.sunrise),
                    ),
                    _buildStatPill(
                      'ইফতার',
                      format.format(dayPrayers.iftar ?? dayPrayers.maghrib),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String title, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textLightSubdued,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPrayerTimesCarousel(
    WidgetRef ref,
    AsyncValue<DayPrayerTimes> dayPrayersAsync,
  ) {
    return dayPrayersAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (_, __) => _buildInlineState(
        icon: LucideIcons.cloudOff,
        message: 'আজকের নামাজের সময় লোড করা যায়নি',
      ),
      data: (dayPrayers) {
        final timeFormat = DateFormat('hh:mm a');
        return SizedBox(
          height: 98,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: dayPrayers.scheduleItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = dayPrayers.scheduleItems[index];
              final startStr = timeFormat.format(item.startTime);
              final alarms = ref.watch(prayerAlarmProvider);
              final isAlarm = alarms[item.type] ?? false;

              return Container(
                width: 110,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.isCurrent
                      ? const Color(0xFFF0FDF4)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: item.isCurrent
                        ? AppColors.activeGreen
                        : AppColors.cardBorder,
                    width: item.isCurrent ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          item.type.iconData,
                          color: const Color(0xFFEA580C),
                          size: 18,
                        ),
                        InkWell(
                          onTap: () {
                            ref
                                .read(prayerAlarmProvider.notifier)
                                .toggleAlarm(item.type);
                          },
                          child: Icon(
                            isAlarm
                                ? LucideIcons.volume2
                                : LucideIcons.volumeOff,
                            color: isAlarm
                                ? AppColors.activeGreen
                                : AppColors.inactiveMuted,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: item.isCurrent
                                ? AppColors.primary
                                : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          startStr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSubdued,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildToolsGrid(BuildContext context) {
    final tools = [
      {
        'title': 'ক্বিবলা কম্পাস',
        'sub': 'Qibla Direction',
        'icon': LucideIcons.compass,
        'color': const Color(0xFF10B981),
        'route': '/qibla',
      },
      {
        'title': 'ডিজিটাল তাসবীহ',
        'sub': 'Digital Tasbeeh',
        'svg': AppIcons.tasbeehSvg,
        'color': const Color(0xFF3B82F6),
        'route': '/tasbeeh',
      },
      {
        'title': 'আল-কুরআন',
        'sub': 'শীঘ্রই আসছে',
        'icon': LucideIcons.bookOpen,
        'color': const Color(0xFF8B5CF6),
        'route': 'quran_coming_soon',
      },
      {
        'title': 'দুআ ও যিক্‌র',
        'sub': 'Duas & Adhkar',
        'svg': AppIcons.handsPrayingSvg,
        'color': const Color(0xFFF59E0B),
        'route': '/dua',
      },
      {
        'title': 'আল্লাহর ৯৯ নাম',
        'sub': '99 Names',
        'icon': LucideIcons.sparkles,
        'color': const Color(0xFFEC4899),
        'route': '/names',
      },
      {
        'title': 'আমল ট্র্যাকার',
        'sub': 'Daily Tracker',
        'icon': LucideIcons.calendarCheck,
        'color': const Color(0xFF0D9488),
        'route': '/tracker',
      },
      {
        'title': 'হিজরি ক্যালেন্ডার',
        'sub': 'Hijri Calendar',
        'icon': LucideIcons.calendar,
        'color': const Color(0xFF6366F1),
        'route': '/calendar',
      },
      {
        'title': 'নামাজ নিষিদ্ধ সময়',
        'sub': 'Prohibited Times',
        'icon': LucideIcons.triangleAlert,
        'color': const Color(0xFFEF4444),
        'route': 'prohibited',
      },
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tools.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.98,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final t = tools[index];
        final iconColor = t['color'] as Color;

        return InkWell(
          onTap: () {
            final route = t['route'] as String;
            if (route == 'prohibited') {
              ProhibitedTimesSheet.show(context);
            } else if (route == 'quran_coming_soon') {
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(LucideIcons.info, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'আল-কুরআন ফিচারটি পরবর্তী আপডেটে আসবে ইনশাআল্লাহ',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            } else if (route == '/qibla' ||
                route == '/tasbeeh' ||
                route == '/names' ||
                route == '/tracker' ||
                route == '/calendar' ||
                route == '/notification-settings') {
              context.push(route);
            } else {
              context.go(route);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: t.containsKey('svg')
                        ? AppIcons.svg(
                            t['svg'] as String,
                            size: 20,
                            color: iconColor,
                          )
                        : Icon(
                            t['icon'] as IconData,
                            color: iconColor,
                            size: 20,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t['title'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  t['sub'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSubdued,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrayerTrackerCard(WidgetRef ref, Map<PrayerType, bool> tracker) {
    final completedCount = tracker.values.where((v) => v).length;

    final prayerList = [
      PrayerType.fajr,
      PrayerType.dhuhr,
      PrayerType.asr,
      PrayerType.maghrib,
      PrayerType.isha,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '৫ ওয়াক্ত নামাজ ট্র্যাকার',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'প্রতি ওয়াক্ত নামাজ শেষে ট্যাপ করে মার্ক করুন',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSubdued,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedCount/৫ সম্পন্ন',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 5 Prayer Buttons
          Row(
            children: prayerList.map((type) {
              final isDone = tracker[type] ?? false;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () {
                      ref
                          .read(prayerTrackerProvider.notifier)
                          .togglePrayer(type);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.activeGreen
                            : AppColors.bgLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDone
                              ? AppColors.activeGreen
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isDone
                                ? LucideIcons.circleCheck
                                : LucideIcons.circle,
                            color: isDone
                                ? Colors.white
                                : AppColors.inactiveMuted,
                            size: 16,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDone ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineState({required IconData icon, required String message}) {
    return Container(
      height: 98,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textSubdued),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSubdued,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFastingCard(
    WidgetRef ref,
    FastingState fasting,
    AsyncValue<DayPrayerTimes> dayPrayersAsync,
  ) {
    return dayPrayersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (dayPrayers) {
        final format = DateFormat('hh:mm a');
        final sehriTime = format.format(dayPrayers.sehriEnd ?? dayPrayers.fajr);
        final iftarTime = format.format(dayPrayers.iftar ?? dayPrayers.maghrib);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'আজকের রোজা ও সেহরি-ইফতার',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'ইসলামিক ফাউন্ডেশন স্থায়ী ক্যালেন্ডার অনুয়ায়ী',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSubdued,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () =>
                        ref.read(fastingProvider.notifier).toggleTodayFast(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: fasting.isFastToday
                            ? AppColors.activeGreen.withValues(alpha: 0.12)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: fasting.isFastToday
                              ? AppColors.activeGreen
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            fasting.isFastToday
                                ? LucideIcons.circleCheck
                                : LucideIcons.circle,
                            size: 14,
                            color: fasting.isFastToday
                                ? AppColors.activeGreen
                                : AppColors.textSubdued,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            fasting.isFastToday ? 'রোজাদার' : 'রোজা নেই',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: fasting.isFastToday
                                  ? AppColors.activeGreen
                                  : AppColors.textSubdued,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bgLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.moon,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'সেহরি শেষ',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSubdued,
                                ),
                              ),
                              Text(
                                sehriTime,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.sunset,
                            color: Color(0xFFEA580C),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ইফতার সময়',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFC2410C),
                                ),
                              ),
                              Text(
                                iftarTime,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9A3412),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyHadithCard(AsyncValue<HadithItem?> dailyHadithAsync) {
    return dailyHadithAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (hadith) {
        if (hadith == null) return const SizedBox.shrink();

        // Extract clean first paragraph
        final cleanSnippet = hadith.text.split('\n\n').first;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.quote,
                      color: AppColors.goldDark,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hadith.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                cleanSnippet,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
