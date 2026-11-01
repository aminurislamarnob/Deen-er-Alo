import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/bangla_numbers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../prayer_times/domain/prayer_model.dart';
import '../data/islamic_events_repository.dart';
import '../domain/bengali_date_names.dart';
import '../domain/islamic_event.dart';
import 'calendar_providers.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  static const Color _fridayColor = Color(0xFF0EA371);
  static const Color _beedColor = Color(0xFF0284C7);

  /// Header subtitle: the Hijri month(s) covered by the Gregorian [month],
  /// e.g. "জুমাদাল উলা – জুমাদাস সানি ১৪৪৮ হিজরি".
  static String hijriRangeLabel(DateTime month, int moonOffset) {
    final first = hijriForDate(
      DateTime(month.year, month.month, 1),
      moonOffset,
    );
    final last = hijriForDate(
      DateTime(month.year, month.month + 1, 0),
      moonOffset,
    );
    String name(int m) => BanglaUtils.hijriMonthBengali[m] ?? '';
    String year(int y) => BanglaUtils.toBanglaDigits(y);
    if (first.hMonth == last.hMonth && first.hYear == last.hYear) {
      return '${name(first.hMonth)}, ${year(first.hYear)} হিজরি';
    }
    if (first.hYear == last.hYear) {
      return '${name(first.hMonth)} – ${name(last.hMonth)} ${year(last.hYear)} হিজরি';
    }
    return '${name(first.hMonth)} ${year(first.hYear)} – '
        '${name(last.hMonth)} ${year(last.hYear)} হিজরি';
  }

  /// Moves the calendar by [delta] months and keeps the selected day inside
  /// the visible month (today for the current month, otherwise the 1st).
  void _changeMonth(WidgetRef ref, DateTime activeMonth, int delta) {
    final target = DateTime(activeMonth.year, activeMonth.month + delta, 1);
    final today = dateOnly(DateTime.now());
    ref.read(calendarMonthProvider.notifier).state = target;
    ref
        .read(selectedCalendarDateProvider.notifier)
        .state = (target.year == today.year && target.month == today.month)
        ? today
        : target;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMonth = ref.watch(calendarMonthProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final moonOffset = ref.watch(moonOffsetProvider);
    final eventsRepo = ref.watch(islamicEventsRepositoryProvider);
    final dayPrayersAsync = ref.watch(calendarDayPrayersProvider);

    final hijriYearNow = ref.watch(hijriTodayProvider).hYear;

    final selectedHijri = hijriForDate(selectedDate, moonOffset);
    final selectedEvents = eventsRepo.getEventsForDate(
      selectedDate,
      moonOffset,
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
                  icon: const Icon(
                    LucideIcons.chevronLeft,
                    color: Colors.white,
                  ),
                  tooltip: 'আগের মাস',
                  onPressed: () => _changeMonth(ref, activeMonth, -1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        BengaliDateNames.monthYear(activeMonth),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hijriRangeLabel(activeMonth, moonOffset),
                        textAlign: TextAlign.center,
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
                  icon: const Icon(
                    LucideIcons.chevronRight,
                    color: Colors.white,
                  ),
                  tooltip: 'পরের মাস',
                  onPressed: () => _changeMonth(ref, activeMonth, 1),
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
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.cardBorder,
                ),
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
                const SizedBox(height: 10),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.cardBorder,
                ),
                const SizedBox(height: 10),
                _buildLegend(),
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
          _buildMajorEventsSection(eventsRepo, moonOffset, hijriYearNow),
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
                color: isFriday ? _fridayColor : AppColors.textSubdued,
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
      final isSelected =
          cellDate.year == selectedDate.year &&
          cellDate.month == selectedDate.month &&
          cellDate.day == selectedDate.day;
      final isToday =
          cellDate.year == now.year &&
          cellDate.month == now.month &&
          cellDate.day == now.day;
      final isFriday = cellDate.weekday == DateTime.friday;

      final events = eventsRepo.getEventsForDate(cellDate, moonOffset);
      final cellHijri = hijriForDate(cellDate, moonOffset);
      final hasMajor = events.any((e) => e.isMajor);
      final hasBeed = events.any((e) => e.isAyyamBeed);
      final hasOther = events.any((e) => !e.isMajor && !e.isAyyamBeed);

      final markerColor = isSelected ? Colors.white : AppColors.goldDark;
      final markers = <Widget>[
        if (hasMajor) _buildMarkerDot(markerColor),
        if (hasOther) _buildMarkerDot(markerColor, hollow: true),
        if (hasBeed) _buildMarkerDot(isSelected ? Colors.white : _beedColor),
      ];

      cells.add(
        InkWell(
          onTap: () {
            ref.read(selectedCalendarDateProvider.notifier).state = cellDate;
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(2),
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
            // Scale down instead of overflowing at large text sizes.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    BanglaUtils.toBanglaDigits(day),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected || isToday || isFriday
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : isFriday
                          ? _fridayColor
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
                  SizedBox(
                    height: 7,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: markers,
                    ),
                  ),
                ],
              ),
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

  Widget _buildMarkerDot(Color color, {bool hollow = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: hollow ? Colors.transparent : color,
        shape: BoxShape.circle,
        border: hollow ? Border.all(color: color, width: 1.2) : null,
      ),
    );
  }

  Widget _buildLegend() {
    Widget item(Widget marker, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        marker,
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSubdued),
        ),
      ],
    );
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        item(_buildMarkerDot(AppColors.goldDark), 'প্রধান দিবস'),
        item(
          _buildMarkerDot(AppColors.goldDark, hollow: true),
          'অন্যান্য দিবস',
        ),
        item(_buildMarkerDot(_beedColor), 'আইয়ামে বিজ'),
        item(
          Text(
            BanglaUtils.toBanglaDigits(7),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _fridayColor,
            ),
          ),
          'শুক্রবার (জুমা)',
        ),
      ],
    );
  }

  Widget _buildDayInspectorCard(
    BuildContext context,
    DateTime date,
    HijriCalendar hijriDate,
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
                child: const Icon(
                  LucideIcons.calendarCheck,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      BengaliDateNames.fullDate(date),
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
                  color: ev.isAyyamBeed
                      ? const Color(0xFFE0F2FE)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: ev.isAyyamBeed
                        ? const Color(0xFFBAE6FD)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      ev.isAyyamBeed ? LucideIcons.moon : LucideIcons.star,
                      color: ev.isAyyamBeed
                          ? _beedColor
                          : const Color(0xFFD97706),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ev.titleBn,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: ev.isAyyamBeed
                              ? const Color(0xFF075985)
                              : const Color(0xFF92400E),
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
                  _buildPrayerTimeChip(
                    'ফজর',
                    BanglaUtils.formatBanglaTime(prayers.fajr),
                  ),
                  _buildPrayerTimeChip(
                    'সূর্যোদয়',
                    BanglaUtils.formatBanglaTime(prayers.sunrise),
                  ),
                  _buildPrayerTimeChip(
                    'জোহর',
                    BanglaUtils.formatBanglaTime(prayers.dhuhr),
                  ),
                  _buildPrayerTimeChip(
                    'আসর',
                    BanglaUtils.formatBanglaTime(prayers.asr),
                  ),
                  _buildPrayerTimeChip(
                    'মাগরিব',
                    BanglaUtils.formatBanglaTime(prayers.maghrib),
                  ),
                  _buildPrayerTimeChip(
                    'ইশা',
                    BanglaUtils.formatBanglaTime(prayers.isha),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (_, __) => const Text(
              'দুঃখিত, এই দিনের নামাজের সময়সূচি হিসাব করা যায়নি।',
              style: TextStyle(fontSize: 12, color: AppColors.textSubdued),
            ),
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
    int hijriYear,
  ) {
    String gregorianLabel(IslamicEvent e) {
      try {
        return BengaliDateNames.dayMonthYear(
          gregorianForHijri(hijriYear, e.hijriMonth, e.hijriDay, moonOffset),
        );
      } catch (_) {
        return '';
      }
    }

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
        Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              for (int i = 0; i < events.length; i++) ...[
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${BanglaUtils.toBanglaDigits(events[i].hijriDay)} ${BanglaUtils.hijriMonthBengali[events[i].hijriMonth]}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        if (gregorianLabel(events[i]).isNotEmpty)
                          Text(
                            gregorianLabel(events[i]),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFB45309),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (i < events.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.cardBorder,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showMoonOffsetSheet(
    BuildContext context,
    WidgetRef ref,
    int currentOffset,
  ) {
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
                          : '${offset > 0 ? "+" : "−"}${BanglaUtils.toBanglaDigits(offset.abs())} দিন ${offset > 0 ? "যোগ" : "বিয়োগ"}',
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
