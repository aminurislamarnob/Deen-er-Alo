import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/bangla_numbers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../prayer_times/domain/prayer_model.dart';
import '../domain/habit_models.dart';
import 'habit_tracker_provider.dart';

class TrackerScreen extends ConsumerWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedTrackerDateProvider);
    final habitRecordAsync = ref.watch(currentHabitRecordProvider);
    final streakSummaryAsync = ref.watch(habitStreakSummaryProvider);
    final qazaBalance = ref.watch(qazaCounterProvider);
    final notifier = ref.read(currentHabitRecordProvider.notifier);

    final isToday = _isSameDay(selectedDate, DateTime.now());
    final dateDisplay = DateFormat('d MMMM, yyyy').format(selectedDate);

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
          'দৈনিক আমল ও নামাজ ট্র্যাকার',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          // Date Selector Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevronLeft, size: 20),
                  color: AppColors.textDark,
                  onPressed: () {
                    ref.read(selectedTrackerDateProvider.notifier).state =
                        selectedDate.subtract(const Duration(days: 1));
                  },
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        isToday ? 'আজ' : 'তারিখ',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        BanglaUtils.toBanglaDigits(dateDisplay),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.chevronRight, size: 20),
                  color: AppColors.textDark,
                  onPressed: () {
                    ref.read(selectedTrackerDateProvider.notifier).state =
                        selectedDate.add(const Duration(days: 1));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Streak & Weekly Summary Card
          streakSummaryAsync.when(
            data: (summary) => _buildStreakCard(summary),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // 5 Daily Prayers Tracking Card
          _buildSectionHeader('৫ ওয়াক্ত নামাজের হিসাব'),
          habitRecordAsync.when(
            data: (record) => _buildPrayersCard(context, record, notifier),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) => Text('Error: $err'),
          ),

          const SizedBox(height: 24),

          // Fasting (Saom) Tracker Card
          _buildSectionHeader('রোজা পালন (সাওম)'),
          habitRecordAsync.when(
            data: (record) => _buildFastingCard(record, notifier),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // Sunnah & Daily Good Deeds Checklist
          _buildSectionHeader('মাসনুন নেক আমল'),
          habitRecordAsync.when(
            data: (record) => _buildGoodDeedsCard(record, notifier),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // Qaza Prayer Counter Card
          _buildSectionHeader('কাজা নামাজের হিসাব সংরক্ষণ'),
          _buildQazaCard(ref, qazaBalance),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSubdued,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildStreakCard(HabitStreakSummary summary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.cardHeaderGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.flame, color: AppColors.gold, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ধারাবাহিক আমল: ${BanglaUtils.toBanglaDigits(summary.streakDays)} দিন',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'আল্লাহর সন্তুষ্টির পথে আপনার প্রচেষ্টা অব্যাহত রাখুন',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'গত ৭ দিনে নামাজ',
                  '${BanglaUtils.toBanglaDigits(summary.weeklyPrayersOffered)}/৩৫',
                ),
                Container(width: 1, height: 28, color: Colors.white24),
                _buildStatColumn(
                  'জামাতে আদায়',
                  '${BanglaUtils.toBanglaDigits(summary.weeklyJamaatCount)} ওয়াক্ত',
                ),
                Container(width: 1, height: 28, color: Colors.white24),
                _buildStatColumn(
                  'রোজার দিন',
                  '${BanglaUtils.toBanglaDigits(summary.monthlyFastingDays)} দিন',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildPrayersCard(
    BuildContext context,
    DailyHabitRecord record,
    CurrentHabitRecordNotifier notifier,
  ) {
    final prayers = [
      (PrayerType.fajr, 'ফজর (Fazr)'),
      (PrayerType.dhuhr, 'জোহর (Dhuhr)'),
      (PrayerType.asr, 'আসর (Asr)'),
      (PrayerType.maghrib, 'মাগরিব (Maghrib)'),
      (PrayerType.isha, 'ইশা (Isha)'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          for (int i = 0; i < prayers.length; i++) ...[
            _buildPrayerRow(
              title: prayers[i].$2,
              currentStatus: record.prayers[prayers[i].$1] ?? PrayerStatus.notOffered,
              onStatusSelected: (status) =>
                  notifier.setPrayerStatus(prayers[i].$1, status),
            ),
            if (i < prayers.length - 1)
              const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
          ],
        ],
      ),
    );
  }

  Widget _buildPrayerRow({
    required String title,
    required PrayerStatus currentStatus,
    required ValueChanged<PrayerStatus> onStatusSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildPrayerStatusPill(
                label: 'জামাতে',
                status: PrayerStatus.jamaat,
                current: currentStatus,
                activeColor: const Color(0xFF0EA371),
                onTap: () => onStatusSelected(PrayerStatus.jamaat),
              ),
              const SizedBox(width: 8),
              _buildPrayerStatusPill(
                label: 'একাকী',
                status: PrayerStatus.alone,
                current: currentStatus,
                activeColor: const Color(0xFF0284C7),
                onTap: () => onStatusSelected(PrayerStatus.alone),
              ),
              const SizedBox(width: 8),
              _buildPrayerStatusPill(
                label: 'কাজা',
                status: PrayerStatus.qaza,
                current: currentStatus,
                activeColor: const Color(0xFFD97706),
                onTap: () => onStatusSelected(PrayerStatus.qaza),
              ),
              const SizedBox(width: 8),
              _buildPrayerStatusPill(
                label: 'আদায় হয়নি',
                status: PrayerStatus.notOffered,
                current: currentStatus,
                activeColor: Colors.grey.shade400,
                onTap: () => onStatusSelected(PrayerStatus.notOffered),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerStatusPill({
    required String label,
    required PrayerStatus status,
    required PrayerStatus current,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final isSelected = status == current;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFastingCard(
    DailyHabitRecord record,
    CurrentHabitRecordNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: FastingStatus.values.map((status) {
          final isSelected = record.fasting == status;
          return ChoiceChip(
            label: Text(status.label),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: const Color(0xFFF1F5F9),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppColors.textDark,
            ),
            onSelected: (_) => notifier.setFastingStatus(status),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGoodDeedsCard(
    DailyHabitRecord record,
    CurrentHabitRecordNotifier notifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _buildDeedCheckbox(
            icon: LucideIcons.bookOpen,
            title: 'আল-কুরআন তিলাওয়াত',
            subtitle: 'অর্থসহ বা সাধারণ তেলাওয়াত সম্পন্ন হয়েছে',
            checked: record.readQuran,
            onChanged: () => notifier.toggleQuran(),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
          _buildDeedCheckbox(
            icon: LucideIcons.sparkles,
            title: 'সকাল ও সন্ধ্যার মাসনুন জিকির',
            subtitle: 'হেফাজতের দোয়া, দরূদ ও ইস্তিগফার পাঠ',
            checked: record.morningEveningAdhkar,
            onChanged: () => notifier.toggleAdhkar(),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
          _buildDeedCheckbox(
            icon: LucideIcons.moon,
            title: 'তাহাজ্জুদ ও সালাতুদ দুহা',
            subtitle: 'রাতের নির্জন ইবাদত অথবা চাশতের সালাত',
            checked: record.tahajjudOrDuha,
            onChanged: () => notifier.toggleTahajjudOrDuha(),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
          _buildDeedCheckbox(
            icon: LucideIcons.heartHandshake,
            title: 'সাদাকাহ ও দানশীলতা',
            subtitle: 'অসহায়কে সাহায্য অথবা সদকার আমল',
            checked: record.gaveSadaqah,
            onChanged: () => notifier.toggleSadaqah(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeedCheckbox({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool checked,
    required VoidCallback onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: checked ? AppColors.primaryLight.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: checked ? AppColors.primary : Colors.grey.shade600,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: checked ? AppColors.primary : AppColors.textDark,
          decoration: checked ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSubdued,
        ),
      ),
      trailing: Checkbox(
        value: checked,
        activeColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        onChanged: (_) => onChanged(),
      ),
      onTap: onChanged,
    );
  }

  Widget _buildQazaCard(WidgetRef ref, int balance) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.clock, color: Color(0xFFD97706), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'মোট বকেয়া কাজা নামাজ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'অবশিষ্ট: ${BanglaUtils.toBanglaDigits(balance)} ওয়াক্ত',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.minusCircle, color: Colors.grey),
            onPressed: () {
              ref.read(qazaCounterProvider.notifier).decrement();
            },
          ),
          Text(
            BanglaUtils.toBanglaDigits(balance),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary),
            onPressed: () {
              ref.read(qazaCounterProvider.notifier).increment();
            },
          ),
        ],
      ),
    );
  }
}
