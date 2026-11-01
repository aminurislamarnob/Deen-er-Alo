import 'package:flutter/material.dart';
import '../../../core/utils/bangla_numbers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import 'prayer_providers.dart';

class ProhibitedTimesSheet extends ConsumerWidget {
  const ProhibitedTimesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProhibitedTimesSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prohibitedTimes = ref.watch(prohibitedTimesProvider);
    final currentProhibited = ref.watch(currentProhibitedTimeProvider);

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
                  Icon(LucideIcons.triangleAlert,
                      color: Color(0xFFEF4444), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'নামাজের নিষিদ্ধ সময় (মাকরূহ ওয়াক্ত)',
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

          const SizedBox(height: 12),

          // Current Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: currentProhibited != null
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: currentProhibited != null
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFF86EFAC),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  currentProhibited != null
                      ? LucideIcons.ban
                      : LucideIcons.circleCheck,
                  color: currentProhibited != null
                      ? const Color(0xFFDC2626)
                      : AppColors.activeGreen,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    currentProhibited != null
                        ? 'সতর্কতা: এখন নামাজ পড়া নিষিদ্ধ (${currentProhibited.bengaliTitle})'
                        : 'আলহামদুলিল্লাহ, এখন নামাজ আদায় করা যাবে। কোনো নিষিদ্ধ সময় নেই।',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: currentProhibited != null
                          ? const Color(0xFF991B1B)
                          : const Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3 Prohibited Times List
          const Text(
            'আজকের ৩টি নিষিদ্ধ সময়সূচি:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),

          for (final item in prohibitedTimes) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.bengaliTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${BanglaUtils.formatBanglaTime(item.startTime)} - ${BanglaUtils.formatBanglaTime(item.endTime)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.reason,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSubdued,
                      height: 1.4,
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
}

