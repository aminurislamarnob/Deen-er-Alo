import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/bangla_numbers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../prayer_times/domain/prayer_model.dart';
import '../data/islamic_events_repository.dart';
import '../domain/islamic_event.dart';
import 'calendar_providers.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMonth = ref.watch(calendarMonthProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final moonOffset = ref.watch(moonOffsetProvider);
    final eventsRepo = ref.watch(islamicEventsRepositoryProvider);
    final dayPrayersAsync = ref.watch(calendarDayPrayersProvider);

    final hijriActive = getAdjustedHijriDate(activeMonth, moonOffset);
    final hijriMonthBn =
        BanglaUtils.hijriMonthBengali[hijriActive.hMonth] ??
        hijriActive.longMonthName;

    final selectedHijri = getAdjustedHijriDate(selectedDate, moonOffset);
    final selectedEvents = eventsRepo.getEventsForHijriDate(
      selectedHijri.hMonth,
      selectedHijri.hDay,
    );

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 64,
        leading: const Center(
          child: Padding(
            padding: EdgeInsets.only(left: 16),
            child: AppBackButton(),
          ),
        ),
        title: const Text(
          'ইসলামিক ও হিজরি ক্যালেন্ডার',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.moon, color: AppColors.primary),
            tooltip: 'চাঁদ দেখা অনুযায়ী সমন্বয়',
            onPressed: () => _showMoonOffsetSheet(context, ref, moonOffset),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // Month Header Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.cardHeaderGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
                  onPressed: () {
                    ref.read(calendarMonthProvider.notifier).state = DateTime(
                      activeMonth.year,
                      activeMonth.month - 1,
                      1,
                    );
                  },
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(activeMonth),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$hijriMonthBn, ${BanglaUtils.toBanglaDigits(hijriActive.hYear)} হিজরি',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.chevronRight, color: Colors.white),
                  onPressed: () {
                    ref.read(calendarMonthProvider.notifier).state = DateTime(
                      activeMonth.year,
                      activeMonth.month + 1,
                      1,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Calendar Grid Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                // Weekday headers
                _buildWeekdayHeader(),
                const SizedBox(height: 8),
                const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                const SizedBox(height: 8),
                // Days grid
                _buildDaysGrid(
                  context,
                  ref,
                  activeMonth,
                  selectedDate,
                  moonOffset,
                  eventsRepo,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Selected Day Inspector Card
          _buildDayInspectorCard(
            context,
            selectedDate,
            selectedHijri,
            selectedEvents,
            dayPrayersAsync,
          ),

          const SizedBox(height: 20),

          // Major Islamic Events of the Year
          _buildMajorEventsSection(eventsRepo, moonOffset),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const days = ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি'];
    return Row(
      children: days.map((d) {
        final isFriday = d == 'শুক্র';
        return Expanded(
          child: Center(
            child: Text(
              d,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isFriday ? FontWeight.bold : FontWeight.w600,
                color: isFriday ? const Color(0xFF0EA371) : AppColors.textSubdued,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaysGrid(
    BuildContext context,
    WidgetRef ref,
    DateTime month,
    DateTime selectedDate,
    int moonOffset,
    IslamicEventsRepository eventsRepo,
  ) {
    final firstDayOfWeek = DateTime(month.year, month.month, 1).weekday % 7;
    final totalDaysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final now = DateTime.now();
    final cells = <Widget>[];

    // Blank cells before first day
    for (int i = 0; i < firstDayOfWeek; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= totalDaysInMonth; day++) {
      final cellDate = DateTime(month.year, month.month, day);
      final isSelected = cellDate.year == selectedDate.year &&
          cellDate.month == selectedDate.month &&
          cellDate.day == selectedDate.day;
      final isToday = cellDate.year == now.year &&
          cellDate.month == now.month &&
          cellDate.day == now.day;
      final isFriday = cellDate.weekday == DateTime.friday;

      final cellHijri = getAdjustedHijriDate(cellDate, moonOffset);
      final events = eventsRepo.getEventsForHijriDate(
        cellHijri.hMonth,
        cellHijri.hDay,
      );
      final hasEvent = events.isNotEmpty;

      cells.add(
        InkWell(
          onTap: () {
            ref.read(selectedCalendarDateProvider.notifier).state = cellDate;
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isToday
                      ? AppColors.primaryLight.withValues(alpha: 0.12)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : isToday
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected || isToday
                        ? FontWeight.bold
                        : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : isFriday
                            ? const Color(0xFF0EA371)
                            : AppColors.textDark,
                  ),
                ),
                Text(
                  BanglaUtils.toBanglaDigits(cellHijri.hDay),
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? AppColors.gold
                        : AppColors.textSubdued,
                  ),
                ),
                if (hasEvent)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppColors.goldDark,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 4,
      mainAxisSpacing: 6,
      children: cells,
    );
  }

  Widget _buildDayInspectorCard(
    BuildContext context,
    DateTime date,
    dynamic hijriDate,
    List<IslamicEvent> events,
    AsyncValue<DayPrayerTimes?> dayPrayersAsync,
  ) {
    final hijriMonthBn =
        BanglaUtils.hijriMonthBengali[hijriDate.hMonth] ??
        hijriDate.longMonthName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.calendarCheck,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(date),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${BanglaUtils.toBanglaDigits(hijriDate.hDay)} $hijriMonthBn, ${BanglaUtils.toBanglaDigits(hijriDate.hYear)} হিজরি',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Events on this day
          if (events.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final ev in events)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.star,
                        color: Color(0xFFD97706), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ev.titleBn,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          const SizedBox(height: 14),
          const Text(
            'নির্বাচিত দিনের নামাজের সময়সূচি',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textSubdued,
            ),
          ),
          const SizedBox(height: 8),

          // Prayer schedule for the selected date
          dayPrayersAsync.when(
            data: (prayers) {
              if (prayers == null) {
                return const Text('সময়সূচি লোড করা সম্ভব হয়নি');
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPrayerTimeChip('ফজর', BanglaUtils.formatBanglaTime(prayers.fajr)),
                  _buildPrayerTimeChip('সূর্যোদয়', BanglaUtils.formatBanglaTime(prayers.sunrise)),
                  _buildPrayerTimeChip('জোহর', BanglaUtils.formatBanglaTime(prayers.dhuhr)),
                  _buildPrayerTimeChip('আসর', BanglaUtils.formatBanglaTime(prayers.asr)),
                  _buildPrayerTimeChip('মাগরিব', BanglaUtils.formatBanglaTime(prayers.maghrib)),
                  _buildPrayerTimeChip('ইশা', BanglaUtils.formatBanglaTime(prayers.isha)),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeChip(String title, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$title: $time',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildMajorEventsSection(
    IslamicEventsRepository eventsRepo,
    int moonOffset,
  ) {
    final events = eventsRepo.getAllEvents().where((e) => e.isMajor).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'ইসলামিক গুরুত্বপূর্ণ দিবসসমূহ',
            style: TextStyle(
              color: AppColors.textSubdued,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              for (int i = 0; i < events.length; i++) ...[
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.sparkles,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    events[i].titleBn,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  subtitle: Text(
                    events[i].descriptionBn,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSubdued,
                    ),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${BanglaUtils.toBanglaDigits(events[i].hijriDay)} ${BanglaUtils.hijriMonthBengali[events[i].hijriMonth]}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ),
                if (i < events.length - 1)
                  const Divider(
                      height: 1, thickness: 1, color: AppColors.cardBorder),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showMoonOffsetSheet(BuildContext context, WidgetRef ref, int currentOffset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'চাঁদ দেখা অনুযায়ী হিজরি তারিখ সমন্বয়',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'বাংলাদেশ ইসলামিক ফাউন্ডেশন বা স্থানীয় জাতীয় চাঁদ দেখা কমিটির ঘোষণার সাথে হিজরি তারিখ মেলানোর জন্য দিন সমন্বয় করুন।',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSubdued,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                for (final offset in [-2, -1, 0, 1, 2]) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      offset == currentOffset
                          ? LucideIcons.circleCheck
                          : LucideIcons.circle,
                      color: offset == currentOffset
                          ? AppColors.primary
                          : Colors.grey.shade400,
                    ),
                    title: Text(
                      offset == 0
                          ? 'স্বাভাবিক গণনা (০ দিন)'
                          : '${offset > 0 ? "+" : ""}$offset দিন ${offset > 0 ? "যোগ" : "বিয়োগ"}',
                      style: TextStyle(
                        fontWeight: offset == currentOffset
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: offset == currentOffset
                            ? AppColors.primary
                            : AppColors.textDark,
                      ),
                    ),
                    onTap: () {
                      ref.read(moonOffsetProvider.notifier).setOffset(offset);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
