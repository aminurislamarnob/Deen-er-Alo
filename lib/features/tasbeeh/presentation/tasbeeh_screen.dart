import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../domain/dhikr_item.dart';
import 'tasbeeh_provider.dart';

class TasbeehScreen extends ConsumerStatefulWidget {
  const TasbeehScreen({super.key});

  @override
  ConsumerState<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends ConsumerState<TasbeehScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _animController;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapCounter() {
    _animController.reverse().then((_) => _animController.forward());
    ref.read(tasbeehProvider.notifier).increment();
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'কাউন্টার রিসেট করবেন?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        content: const Text(
          'বর্তমান গণনা শূন্য (০) থেকে শুরু হবে।',
          style: TextStyle(fontSize: 14, color: AppColors.textSubdued),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'বাতিল',
              style: TextStyle(color: AppColors.textSubdued),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(tasbeehProvider.notifier).resetCurrent();
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text('রিসেট'),
          ),
        ],
      ),
    );
  }

  String _toBnNumber(int num) {
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return num.toString().split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? bnDigits[i] : c;
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    final tasbeeh = ref.watch(tasbeehProvider);
    final currentDhikr = tasbeeh.currentDhikr;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'ডিজিটাল তাসবীহ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              tasbeeh.soundEnabled
                  ? LucideIcons.volume2
                  : LucideIcons.volumeOff,
              color: tasbeeh.soundEnabled ? AppColors.gold : Colors.white60,
              size: 20,
            ),
            tooltip: 'সাউন্ড অন/অফ',
            onPressed: () => ref.read(tasbeehProvider.notifier).toggleSound(),
          ),
          IconButton(
            icon: Icon(
              tasbeeh.hapticEnabled
                  ? LucideIcons.vibrate
                  : LucideIcons.vibrateOff,
              color: tasbeeh.hapticEnabled ? AppColors.gold : Colors.white60,
              size: 20,
            ),
            tooltip: 'ভাইব্রেশন অন/অফ',
            onPressed: () => ref.read(tasbeehProvider.notifier).toggleHaptic(),
          ),
          IconButton(
            icon: const Icon(
              LucideIcons.rotateCcw,
              color: Colors.white,
              size: 20,
            ),
            tooltip: 'রিসেট',
            onPressed: _showResetDialog,
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
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Horizontal Dhikr Selector
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: DhikrItem.presets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = DhikrItem.presets[index];
                  final isSelected = item.id == currentDhikr.id;

                  return InkWell(
                    onTap: () {
                      ref.read(tasbeehProvider.notifier).selectDhikr(item);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.cardBorder,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Text(
                        item.transliteration,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Dhikr Meaning & Arabic Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      currentDhikr.arabicText,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentDhikr.bengaliMeaning,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSubdued,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Radial Tap Counter
            ScaleTransition(
              scale: _scaleAnimation,
              child: GestureDetector(
                onTap: _onTapCounter,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Colors.white, Color(0xFFF9FBF9)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 28,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress Ring
                      SizedBox(
                        width: 236,
                        height: 236,
                        child: CircularProgressIndicator(
                          value: tasbeeh.progress,
                          strokeWidth: 10,
                          backgroundColor: AppColors.cardBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.gold,
                          ),
                        ),
                      ),

                      // Center Count Content
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _toBnNumber(tasbeeh.currentCount),
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryDark,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            '(${tasbeeh.currentCount})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSubdued,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.goldMuted,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tasbeeh.targetCount > 0
                                  ? 'লক্ষ্য: ${_toBnNumber(tasbeeh.targetCount)}'
                                  : 'অসীম (∞)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.goldDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'চক্র: ${_toBnNumber(tasbeeh.completedCycles)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSubdued,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Text(
              'গণনা করতে গোল অংশে ট্যাপ করুন',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSubdued,
              ),
            ),

            const Spacer(),

            // Target selector pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTargetPill(ref, tasbeeh, 33, '৩৩'),
                  const SizedBox(width: 8),
                  _buildTargetPill(ref, tasbeeh, 99, '৯৯'),
                  const SizedBox(width: 8),
                  _buildTargetPill(ref, tasbeeh, 100, '১০০'),
                  const SizedBox(width: 8),
                  _buildTargetPill(ref, tasbeeh, 0, 'অসীম (∞)'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Lifetime Counter Bar
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        LucideIcons.sparkles,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'সর্বমোট তাসবীহ আদায়',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_toBnNumber(tasbeeh.lifetimeCount)} বার',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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

  Widget _buildTargetPill(
    WidgetRef ref,
    TasbeehState state,
    int target,
    String label,
  ) {
    final isSelected = state.targetCount == target;
    return InkWell(
      onTap: () => ref.read(tasbeehProvider.notifier).setTarget(target),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSubdued,
          ),
        ),
      ),
    );
  }
}
