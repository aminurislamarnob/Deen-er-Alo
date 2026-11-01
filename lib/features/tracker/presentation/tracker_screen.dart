import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/bangla_numbers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../calendar/domain/bengali_date_names.dart';
import '../../calendar/domain/hijri_utils.dart';
import '../../prayer_times/domain/prayer_model.dart';
import '../domain/habit_models.dart';
import 'habit_tracker_provider.dart';

class TrackerScreen extends ConsumerWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = dateOnly(ref.watch(selectedTrackerDateProvider));
    final recordProvider = habitRecordProvider(selectedDate);
    final habitRecordAsync = ref.watch(recordProvider);
    final streakSummaryAsync = ref.watch(habitStreakSummaryProvider);
    final qazaBalance = ref.watch(qazaCounterProvider);
    final notifier = ref.read(recordProvider.notifier);

    final today = dateOnly(DateTime.now());
    final isToday = isSameDay(selectedDate, today);
    final canGoForward = selectedDate.isBefore(today);
    final dateDisplay = BengaliDateNames.dayMonthYear(selectedDate);

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
                  tooltip: 'আগের দিন',
                  onPressed: () {
                    ref.read(selectedTrackerDateProvider.notifier).state =
                        addDays(selectedDate, -1);
                  },
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        isToday ? 'আজ' : BengaliDateNames.weekday(selectedDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateDisplay,
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
                  disabledColor: Colors.grey.shade300,
                  tooltip: canGoForward ? 'পরের দিন' : null,
                  // Future days cannot be logged.
                  onPressed: canGoForward
                      ? () {
                          final next = addDays(selectedDate, 1);
                          ref.read(selectedTrackerDateProvider.notifier).state =
                              next.isAfter(today) ? today : next;
                        }
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Streak & Weekly Summary Card
          streakSummaryAsync.when(
            data: (summary) => _buildStreakCard(summary),
            // Same-size placeholder so the page does not jump when loaded.
            loading: () => _buildStreakCard(null),
            error: (_, __) => _buildStreakCard(null),
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
            error: (_, __) => _buildErrorCard(() => notifier.reload()),
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
          _buildQazaCard(context, ref, qazaBalance),
        ],
      ),
    );
  }

  Widget _buildErrorCard(VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.circleAlert, color: AppColors.dangerRed),
          const SizedBox(height: 8),
          const Text(
            'দুঃখিত, এই দিনের তথ্য লোড করা যায়নি।',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'অনুগ্রহ করে আবার চেষ্টা করুন।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSubdued),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('আবার চেষ্টা করুন')),
        ],
      ),
    );
  }

  /// Text that renders as a translucent bar of the same size while loading.
  Widget _maybeSkeleton(String text, TextStyle style, bool loading) {
    if (!loading) return Text(text, style: style);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: style.copyWith(color: Colors.transparent)),
    );
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

  Widget _buildStreakCard(HabitStreakSummary? summary) {
    final loading = summary == null;
    String n(int Function(HabitStreakSummary s) f) =>
        summary == null ? '০০' : BanglaUtils.toBanglaDigits(f(summary));
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
                child: const Icon(
                  LucideIcons.flame,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _maybeSkeleton(
                      'ধারাবাহিক আমল: ${n((s) => s.streakDays)} দিন',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      loading,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'পাঁচ ওয়াক্ত নামাজ আদায়ের ধারাবাহিক দিন। আল্লাহর সন্তুষ্টির পথে প্রচেষ্টা অব্যাহত রাখুন',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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
                  '${n((s) => s.weeklyPrayersOffered)}/৩৫',
                  loading,
                ),
                Container(
                  width: 1,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: Colors.white24,
                ),
                _buildStatColumn(
                  'জামাতে আদায়',
                  '${n((s) => s.weeklyJamaatCount)} ওয়াক্ত',
                  loading,
                ),
                Container(
                  width: 1,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: Colors.white24,
                ),
                _buildStatColumn(
                  '৩০ দিনে রোজা',
                  '${n((s) => s.monthlyFastingDays)} দিন',
                  loading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, bool loading) {
    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          children: [
            _maybeSkeleton(
              value,
              const TextStyle(
                color: AppColors.gold,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              loading,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayersCard(
    BuildContext context,
    DailyHabitRecord record,
    HabitRecordNotifier notifier,
  ) {
    final prayers = [
      (PrayerType.fajr, 'ফজর (Fajr)'),
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
              currentStatus: record.prayers[prayers[i].$1] ?? PrayerStatus.none,
              // Tapping the selected pill again clears it ("not logged").
              onStatusSelected: (status) => notifier.setPrayerStatus(
                prayers[i].$1,
                status == record.prayers[prayers[i].$1]
                    ? PrayerStatus.none
                    : status,
              ),
            ),
            if (i < prayers.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.cardBorder,
              ),
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
          // 2x2 layout so longer labels like "আদায় হয়নি" fit comfortably.
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
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPrayerStatusPill(
                label: 'কাজা আদায়',
                status: PrayerStatus.qaza,
                current: currentStatus,
                activeColor: const Color(0xFFD97706),
                onTap: () => onStatusSelected(PrayerStatus.qaza),
              ),
              const SizedBox(width: 8),
              _buildPrayerStatusPill(
                label: 'আদায় হয়নি',
                status: PrayerStatus.notOffered,
                current: currentStatus,
                activeColor: const Color(0xFFDC2626),
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
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFastingCard(
    DailyHabitRecord record,
    HabitRecordNotifier notifier,
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
    HabitRecordNotifier notifier,
  ) {
    // Material (not a decorated Container) so ListTile ink is visible.
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
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
          color: checked
              ? AppColors.primaryLight.withValues(alpha: 0.15)
              : const Color(0xFFF1F5F9),
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
        style: const TextStyle(fontSize: 12, color: AppColors.textSubdued),
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

  Widget _buildQazaCard(BuildContext context, WidgetRef ref, int balance) {
    return Container(
      padding: const EdgeInsets.all(18),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.clock,
                  color: Color(0xFFD97706),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'মোট বকেয়া কাজা নামাজ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'অবশিষ্ট: ${BanglaUtils.toBanglaDigits(balance)} ওয়াক্ত',
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
                tooltip: 'এক ওয়াক্ত কমান',
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
                icon: const Icon(
                  LucideIcons.plusCircle,
                  color: AppColors.primary,
                ),
                tooltip: 'এক ওয়াক্ত যোগ করুন',
                onPressed: () {
                  ref.read(qazaCounterProvider.notifier).increment();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'কোনো নামাজ "আদায় হয়নি" চিহ্নিত করলে বকেয়ায় এক ওয়াক্ত যোগ হয়; পরে "কাজা আদায়" বা আদায় চিহ্নিত করলে তা কমে যায়।',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSubdued,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(LucideIcons.calculator, size: 18),
              label: const Text(
                'পুরোনো বকেয়া হিসাব করুন',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => _showBacklogCalculator(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  void _showBacklogCalculator(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => QazaBacklogSheet(
        onConfirm: (prayers) =>
            ref.read(qazaCounterProvider.notifier).addBacklog(prayers),
      ),
    );
  }
}

/// Bottom sheet that estimates missed prayers from a period
/// (years / months / days × 5 fard prayers) and, after confirmation, adds
/// them to the qaza balance.
class QazaBacklogSheet extends StatefulWidget {
  final Future<void> Function(int prayers) onConfirm;

  const QazaBacklogSheet({super.key, required this.onConfirm});

  @override
  State<QazaBacklogSheet> createState() => _QazaBacklogSheetState();
}

class _QazaBacklogSheetState extends State<QazaBacklogSheet> {
  final _years = TextEditingController();
  final _months = TextEditingController();
  final _days = TextEditingController();

  @override
  void dispose() {
    _years.dispose();
    _months.dispose();
    _days.dispose();
    super.dispose();
  }

  /// Parses ASCII or Bangla digits; empty/invalid → 0.
  static int _parse(String raw) {
    const bangla = '০১২৩৪৫৬৭৮৯';
    final ascii = raw.trim().split('').map((c) {
      final i = bangla.indexOf(c);
      return i >= 0 ? '$i' : c;
    }).join();
    final v = int.tryParse(ascii) ?? 0;
    return v < 0 ? 0 : v;
  }

  int get _total => qazaBacklogPrayers(
    years: _parse(_years.text),
    months: _parse(_months.text),
    days: _parse(_days.text),
  );

  Widget _field(String label, TextEditingController c) {
    return Expanded(
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 4,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          hintText: '০',
          counterText: '',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    final total = _total;
    if (total <= 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নিশ্চিত করুন'),
        content: Text(
          'মোট ${BanglaUtils.toBanglaDigits(total)} ওয়াক্ত কাজা নামাজ আপনার বকেয়া হিসাবে যোগ করা হবে। আপনি কি নিশ্চিত?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('যোগ করুন'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await widget.onConfirm(total);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    Navigator.pop(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          '${BanglaUtils.toBanglaDigits(total)} ওয়াক্ত কাজা বকেয়ায় যোগ হয়েছে',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _total;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
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
                'পুরোনো কাজা নামাজের হিসাব',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'যত সময় নামাজ আদায় হয়নি তা আনুমানিক লিখুন। প্রতিদিন ৫ ওয়াক্ত ফরজ নামাজ ধরে হিসাব করা হবে (১ বছর = ৩৬৫ দিন, ১ মাস = ৩০ দিন)।',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSubdued,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _field('বছর', _years),
                  const SizedBox(width: 10),
                  _field('মাস', _months),
                  const SizedBox(width: 10),
                  _field('দিন', _days),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'মোট: ${BanglaUtils.toBanglaDigits(total)} ওয়াক্ত নামাজ',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: total > 0 ? _confirm : null,
                  child: const Text('বকেয়া হিসাবে যোগ করুন'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
