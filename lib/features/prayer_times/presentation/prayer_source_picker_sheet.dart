import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/bangla_numbers.dart';
import '../domain/city_model.dart';
import 'prayer_providers.dart';

class PrayerSourcePickerSheet extends ConsumerWidget {
  const PrayerSourcePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PrayerSourcePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSource = ref.watch(prayerSourceProvider);
    final selectedCity = ref.watch(selectedCityProvider).valueOrNull ?? CityModel.dhakaDefault();
    final isBd = selectedCity.isBangladeshDistrict ||
        selectedCity.countryName.toLowerCase() == 'bangladesh';
    final date = ref.watch(todayDateProvider);
    final engine = ref.watch(prayerEngineProvider);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.landmark, color: AppColors.primaryDark, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'নামাজের সময়ের উৎস',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(
              isBd
                  ? 'বাংলাদেশে স্থানীয় মসজিদ ও ক্যালেন্ডারের সাথে মেলাতে সরকারি ইসলামিক ফাউন্ডেশনের সময়সূচি অথবা জ্যোতির্বিজ্ঞানভিত্তিক পদ্ধতি নির্বাচন করুন।'
                  : 'আন্তর্জাতিক লোকেশনের জন্য ভৌগোলিক অক্ষাংশ-দ্রাঘিমাংশ অনুযায়ী জ্যোতির্বিজ্ঞানভিত্তিক গণনা ব্যবহৃত হয়।',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSubdued,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            if (isBd) ...[
              // Option 1: IFB
              FutureBuilder(
                future: engine.calculateDayPrayers(
                  city: selectedCity,
                  date: date,
                  source: PrayerCalculationSource.ifb,
                ),
                builder: (context, snapshot) {
                  final day = snapshot.data;
                  final previewText = (day != null && day.iftar != null)
                      ? 'আজ: ফজর ${BanglaUtils.formatBanglaTime(day.fajr)} • ইফতার ${BanglaUtils.formatBanglaTime(day.iftar!)}'
                      : 'সময়সূচি লোড হচ্ছে...';

                  return _buildSourceTile(
                    context: context,
                    ref: ref,
                    source: PrayerCalculationSource.ifb,
                    isSelected: currentSource == PrayerCalculationSource.ifb,
                    title: 'ইসলামিক ফাউন্ডেশন বাংলাদেশ',
                    subtitle: 'সরকারি স্থায়ী ক্যালেন্ডার অনুযায়ী (মসজিদের সাথে মিল)',
                    preview: previewText,
                    badge: 'প্রস্তাবিত',
                  );
                },
              ),

              const SizedBox(height: 12),

              // Option 2: Karachi
              FutureBuilder(
                future: engine.calculateDayPrayers(
                  city: selectedCity,
                  date: date,
                  source: PrayerCalculationSource.karachi,
                ),
                builder: (context, snapshot) {
                  final day = snapshot.data;
                  final previewText = (day != null && day.iftar != null)
                      ? 'আজ: ফজর ${BanglaUtils.formatBanglaTime(day.fajr)} • ইফতার ${BanglaUtils.formatBanglaTime(day.iftar!)}'
                      : 'সময়সূচি লোড হচ্ছে...';

                  return _buildSourceTile(
                    context: context,
                    ref: ref,
                    source: PrayerCalculationSource.karachi,
                    isSelected: currentSource == PrayerCalculationSource.karachi,
                    title: 'জ্যোতির্বিজ্ঞান ভিত্তিক (করাচি পদ্ধতি)',
                    subtitle: 'করাচি ১৮°/১৮° ও হানাফি আসর কোণ (মসৃণ সোলার কার্ভ)',
                    preview: previewText,
                  );
                },
              ),
            ] else ...[
              // Non-BD notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.globe, color: AppColors.primaryDark, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'জ্যোতির্বিজ্ঞান ভিত্তিক পদ্ধতি (সক্রিয়)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'আপনার নির্বাচিত দেশের জন্য বৈজ্ঞানিক কোণভিত্তিক গণনা প্রযোজ্য।',
                            style: TextStyle(fontSize: 11, color: AppColors.textSubdued),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSourceTile({
    required BuildContext context,
    required WidgetRef ref,
    required PrayerCalculationSource source,
    required bool isSelected,
    required String title,
    required String subtitle,
    required String preview,
    String? badge,
  }) {
    return InkWell(
      onTap: () {
        ref.read(prayerSourceProvider.notifier).setSource(source);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : AppColors.bgLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.activeGreen : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isSelected ? LucideIcons.circleDot : LucideIcons.circle,
                color: isSelected ? AppColors.activeGreen : Colors.grey.shade400,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.textDark : AppColors.textDark,
                          ),
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.activeGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.activeGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSubdued,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.activeGreen.withValues(alpha: 0.08)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      preview,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF166534) : AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
