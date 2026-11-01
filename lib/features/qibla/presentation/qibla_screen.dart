import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../prayer_times/presentation/city_picker_sheet.dart';
import '../../prayer_times/presentation/prayer_providers.dart';
import 'qibla_providers.dart';
import 'widgets/qibla_compass_dial.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  bool _wasAligned = false;
  double _manualHeading = 0.0;

  void _triggerHapticOnAlignment(bool isAligned) {
    if (isAligned && !_wasAligned) {
      HapticFeedback.heavyImpact();
    }
    _wasAligned = isAligned;
  }

  String _toBnNumber(String input) {
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return input.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? bnDigits[i] : c;
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(selectedCityProvider).value;
    final qiblaState = ref.watch(qiblaStateProvider);
    final cityName = city?.name ?? 'ঢাকা';

    // If device doesn't have sensor, allow manual simulation
    final currentHeading = qiblaState.hasSensor
        ? qiblaState.userHeading
        : _manualHeading;
    final deltaAngle = ((currentHeading - qiblaState.qiblaBearing) % 360.0);
    final normalizedDelta = deltaAngle > 180 ? deltaAngle - 360 : deltaAngle;
    final isAligned = normalizedDelta.abs() <= 3.5;

    _triggerHapticOnAlignment(isAligned);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('ক্বিবলা কম্পাস (Qibla Compass)'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.mapPin, color: Colors.white, size: 20),
            tooltip: 'শহর পরিবর্তন',
            onPressed: () => CityPickerSheet.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Location & Bearing Pill Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.mapPin,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cityName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'ক্বিবলা কোণ: ${_toBnNumber(qiblaState.qiblaBearing.toStringAsFixed(1))}°',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSubdued,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => CityPickerSheet.show(context),
                      icon: const Icon(
                        LucideIcons.refreshCw,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        'পরিবর্তন',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Degree Header
              Column(
                children: [
                  Text(
                    '${_toBnNumber(currentHeading.toStringAsFixed(0))}°',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: isAligned
                          ? AppColors.activeGreen
                          : AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    qiblaState.cardinalDirectionBn,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSubdued,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Rotating Compass Dial
              Center(
                child: QiblaCompassDial(
                  heading: currentHeading,
                  qiblaBearing: qiblaState.qiblaBearing,
                  isAligned: isAligned,
                  size: 280,
                ),
              ),

              const SizedBox(height: 28),

              // Alignment Banner
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isAligned
                      ? AppColors.activeGreen.withValues(alpha: 0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isAligned
                        ? AppColors.activeGreen
                        : AppColors.cardBorder,
                    width: isAligned ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAligned
                          ? LucideIcons.circleCheck
                          : LucideIcons.compass,
                      color: isAligned
                          ? AppColors.activeGreen
                          : AppColors.goldDark,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAligned
                                ? 'আলহামদুলিল্লাহ! আপনি ক্বিবলামুখী আছেন'
                                : normalizedDelta > 0
                                    ? 'ফোনটি ${_toBnNumber(normalizedDelta.abs().toStringAsFixed(0))}° বামে ঘুরান'
                                    : 'ফোনটি ${_toBnNumber(normalizedDelta.abs().toStringAsFixed(0))}° ডানে ঘুরান',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isAligned
                                  ? AppColors.activeGreen
                                  : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAligned
                                ? 'সরাসরি কাবার অভিমুখে লক্ষ্য স্থির হয়েছে।'
                                : 'সবুজ সূচক সোজা না হওয়া পর্যন্ত ডিভাইসটি সমান্তরালভাবে ঘুরান।',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSubdued,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Sensor Warning / Manual Fallback (if no magnetometer detected)
              if (!qiblaState.hasSensor) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            LucideIcons.triangleAlert,
                            size: 18,
                            color: AppColors.goldDark,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'ম্যাগনেটিক সেন্সর মোড (ম্যানুয়াল গাইড)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'আপনার ডিভাইসে রিয়েল-টাইম ম্যাগনেটোমিটার সেন্সর পাওয়া যায়নি (এম্যুলেটর বা বাজেট ডিভাইস)। গাণিতিক হিসাব অনুযায়ী $cityName থেকে ক্বিবলার কোণ ${_toBnNumber(qiblaState.qiblaBearing.toStringAsFixed(1))}° পশ্চিম।',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSubdued,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'কোণ টেস্ট:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: _manualHeading,
                              min: 0,
                              max: 360,
                              activeColor: AppColors.primary,
                              inactiveColor: AppColors.cardBorder,
                              onChanged: (val) {
                                setState(() => _manualHeading = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Calibration & Usage Guide
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.info,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'সঠিক ব্যবহারের নির্দেশনা',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '১. ফোনটিকে মেঝের সমান্তরালে অনুভূমিকভাবে (Flat) ধরে রাখুন।\n'
                      '২. কোনো বড় ধাতব বস্তু বা ইলেকট্রনিক্স ডিভাইস থেকে দূরে রাখুন।\n'
                      '৩. কম্পাস নির্ভুল করতে ফোনটিকে বাতাসে ৮ (8) আকারে দু-তিনবার ঘোরান।',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSubdued,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
