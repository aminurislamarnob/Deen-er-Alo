import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../prayer_times/presentation/city_picker_sheet.dart';
import '../../prayer_times/presentation/prayer_providers.dart';
import '../domain/qibla_compass_model.dart';
import 'qibla_providers.dart';
import 'widgets/qibla_compass_dial.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  double _manualHeading = 0.0;

  /// The state actually shown: sensor heading, or the manual slider heading
  /// when the device has no compass.
  QiblaCompassModel _effective(QiblaCompassModel s) {
    return QiblaCompassModel(
      userHeading: s.hasSensor ? s.userHeading : _manualHeading,
      qiblaBearing: s.qiblaBearing,
      hasSensor: s.hasSensor,
      accuracy: s.accuracy,
      isLoading: s.isLoading,
    );
  }

  void _hapticIfBecameAligned(bool wasAligned, bool isAligned) {
    if (isAligned && !wasAligned) {
      HapticFeedback.mediumImpact();
    }
  }

  void _onManualHeadingChanged(double value) {
    final current = ref.read(qiblaStateProvider);
    final wasAligned = _effective(current).isAligned;
    setState(() => _manualHeading = value);
    _hapticIfBecameAligned(wasAligned, _effective(current).isAligned);
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

    // Haptic only on the transition into the aligned state (not per build).
    ref.listen<QiblaCompassModel>(qiblaStateProvider, (previous, next) {
      final wasAligned = previous != null && _effective(previous).isAligned;
      _hapticIfBecameAligned(wasAligned, _effective(next).isAligned);
    });

    // If device doesn't have sensor, allow manual simulation
    final effectiveState = _effective(qiblaState);
    final currentHeading = effectiveState.userHeading;
    final isLoading = effectiveState.isLoading;
    final isAligned = effectiveState.isAligned;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        leadingWidth: 62,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: AppBackButton(),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                    isLoading
                        ? '--°'
                        : '${_toBnNumber(currentHeading.toStringAsFixed(0))}°',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: isAligned
                          ? AppColors.activeGreen
                          : AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    isLoading
                        ? 'অপেক্ষা করুন…'
                        : effectiveState.cardinalDirectionBn,
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
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isLoading ? 0.4 : 1.0,
                  child: QiblaCompassDial(
                    heading: currentHeading,
                    qiblaBearing: qiblaState.qiblaBearing,
                    isAligned: isAligned,
                    size: 280,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Alignment Banner
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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
                      isAligned ? LucideIcons.circleCheck : LucideIcons.compass,
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
                            isLoading
                                ? 'সেন্সর চালু হচ্ছে…'
                                : isAligned
                                ? 'আলহামদুলিল্লাহ! আপনি ক্বিবলামুখী আছেন'
                                : effectiveState.deltaAngle > 0
                                ? 'ফোনটি ${_toBnNumber(effectiveState.deltaAngle.abs().toStringAsFixed(0))}° বামে ঘুরান'
                                : 'ফোনটি ${_toBnNumber(effectiveState.deltaAngle.abs().toStringAsFixed(0))}° ডানে ঘুরান',
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
                            isLoading
                                ? 'কম্পাসের তথ্য পাওয়া মাত্র দিকনির্দেশনা দেখানো হবে।'
                                : isAligned
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
                        'আপনার ডিভাইসে রিয়েল-টাইম ম্যাগনেটোমিটার সেন্সর পাওয়া যায়নি (এম্যুলেটর বা বাজেট ডিভাইস)। গাণিতিক হিসাব অনুযায়ী $cityName থেকে ক্বিবলার কোণ ${_toBnNumber(qiblaState.qiblaBearing.toStringAsFixed(1))}°। সূর্যের অবস্থান বা ছায়ার দিক দেখে ফোনের উত্তর দিক মিলিয়ে তারপর নিচের কোণটি অনুসরণ করুন।',
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
                            child: Semantics(
                              label: 'ম্যানুয়াল কোণ নির্বাচন (ডিগ্রি)',
                              child: Slider(
                                value: _manualHeading,
                                min: 0,
                                max: 360,
                                activeColor: AppColors.primary,
                                inactiveColor: AppColors.cardBorder,
                                semanticFormatterCallback: (val) =>
                                    '${_toBnNumber(val.toStringAsFixed(0))} ডিগ্রি',
                                onChanged: _onManualHeadingChanged,
                              ),
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
