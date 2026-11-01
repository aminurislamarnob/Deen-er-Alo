import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/prayer_model.dart';

class PrayerCardWidget extends StatelessWidget {
  final PrayerScheduleItem item;
  final bool isAlarmActive;
  final VoidCallback onToggleAlarm;
  final bool isLast;

  const PrayerCardWidget({
    super.key,
    required this.item,
    required this.isAlarmActive,
    required this.onToggleAlarm,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
    final startStr = timeFormat.format(item.startTime);
    final endStr = timeFormat.format(item.endTime);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator (left side)
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isCurrent ? AppColors.gold : Colors.white,
                    border: Border.all(
                      color: AppColors.gold,
                      width: 2.5,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
          ),

          // Main Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: item.isCurrent
                    ? const Color(0xFFF0FDF4)
                    : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: item.isCurrent
                      ? AppColors.activeGreen.withValues(alpha: 0.4)
                      : AppColors.cardBorder,
                  width: item.isCurrent ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Weather style Prayer Icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.type.iconData,
                      color: const Color(0xFFEA580C),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name & Time Range
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: item.isCurrent
                                ? AppColors.primary
                                : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$startStr-$endStr',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSubdued,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Speaker / Alarm Toggle Button
                  GestureDetector(
                    onTap: onToggleAlarm,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        isAlarmActive
                            ? LucideIcons.volume2
                            : LucideIcons.volumeOff,
                        color: isAlarmActive
                            ? AppColors.activeGreen
                            : AppColors.inactiveMuted,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
