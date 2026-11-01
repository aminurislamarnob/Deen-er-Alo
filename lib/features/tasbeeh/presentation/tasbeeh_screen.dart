import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_back_button.dart';
import '../domain/dhikr_item.dart';
import '../../../app/theme/app_fonts.dart';
import 'tasbeeh_provider.dart';

/// Standard target choices shown as pills (0 = unlimited).
const List<int> kStandardTasbeehTargets = [33, 99, 100];

/// Target pills to show: the standard ones plus the selected dhikr's
/// recommended target and the active target when they aren't standard
/// (e.g. 34 for Allahu Akbar), sorted, with unlimited (0) last.
List<int> tasbeehTargetOptions(TasbeehState state) {
  final targets = <int>{...kStandardTasbeehTargets};
  if (state.currentDhikr.recommendedTarget > 0) {
    targets.add(state.currentDhikr.recommendedTarget);
  }
  if (state.targetCount > 0) targets.add(state.targetCount);
  return [...(targets.toList()..sort()), 0];
}

String _toBnNumber(int num) {
  const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return num.toString().split('').map((c) {
    final i = int.tryParse(c);
    return i != null ? bnDigits[i] : c;
  }).join();
}

/// Screen-reader label for the tap counter, e.g. 'তাসবীহ গণনা, ১০/৩৩'.
String tasbeehCounterSemanticLabel(TasbeehState state) {
  final count = _toBnNumber(state.currentCount);
  final base = state.targetCount > 0
      ? 'তাসবীহ গণনা, $count/${_toBnNumber(state.targetCount)}'
      : 'তাসবীহ গণনা, $count';
  final complete = state.isCycleComplete ? ', চক্র সম্পন্ন' : '';
  return '$base$complete, চক্র: ${_toBnNumber(state.completedCycles)}';
}

enum _ResetAction { current, today, lifetime }

class TasbeehScreen extends ConsumerStatefulWidget {
  const TasbeehScreen({super.key});

  @override
  ConsumerState<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends ConsumerState<TasbeehScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late final TasbeehNotifier _notifier;
  late final AppLifecycleListener _lifecycleListener;

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
    _notifier = ref.read(tasbeehProvider.notifier);
    // Flush debounced writes when the app goes to the background.
    _lifecycleListener = AppLifecycleListener(
      onInactive: _flushPending,
      onPause: _flushPending,
    );
  }

  void _flushPending() {
    _notifier.flush();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _flushPending();
    _animController.dispose();
    super.dispose();
  }

  void _onTapCounter() {
    _animController.reverse().then((_) => _animController.forward());
    ref.read(tasbeehProvider.notifier).increment();
  }

  Future<bool> _confirm({
    required String title,
    required String content,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(fontSize: 14, color: AppColors.textSubdued),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'বাতিল',
              style: TextStyle(color: AppColors.textSubdued),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _onResetSelected(_ResetAction action) async {
    final notifier = ref.read(tasbeehProvider.notifier);
    switch (action) {
      case _ResetAction.current:
        if (await _confirm(
          title: 'কাউন্টার রিসেট করবেন?',
          content: 'বর্তমান গণনা শূন্য (০) থেকে শুরু হবে।',
          confirmLabel: 'রিসেট',
        )) {
          notifier.resetCurrent();
        }
      case _ResetAction.today:
        if (await _confirm(
          title: 'আজকের গণনা রিসেট করবেন?',
          content:
              'বর্তমান গণনা ও আজকের সম্পন্ন চক্র শূন্য (০) হবে। সর্বমোট গণনা অপরিবর্তিত থাকবে।',
          confirmLabel: 'রিসেট',
        )) {
          notifier.resetAll();
        }
      case _ResetAction.lifetime:
        final lifetime = _toBnNumber(ref.read(tasbeehProvider).lifetimeCount);
        if (await _confirm(
          title: 'সর্বমোট গণনা মুছে ফেলবেন?',
          content:
              'আপনার এ যাবৎ আদায়কৃত সর্বমোট তাসবীহের হিসাব ($lifetime বার) স্থায়ীভাবে শূন্য হয়ে যাবে। এটি আর ফিরিয়ে আনা যাবে না।',
          confirmLabel: 'হ্যাঁ, মুছে ফেলুন',
        )) {
          notifier.resetLifetime();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasbeeh = ref.watch(tasbeehProvider);
    final currentDhikr = tasbeeh.currentDhikr;
    final textScaler = MediaQuery.textScalerOf(context);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        leadingWidth: 62,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: AppBackButton(),
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
          PopupMenuButton<_ResetAction>(
            icon: const Icon(
              LucideIcons.rotateCcw,
              color: Colors.white,
              size: 20,
            ),
            tooltip: 'রিসেট',
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: _onResetSelected,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _ResetAction.current,
                child: Text('বর্তমান গণনা রিসেট'),
              ),
              PopupMenuItem(
                value: _ResetAction.today,
                child: Text('আজকের গণনা ও চক্র রিসেট'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _ResetAction.lifetime,
                child: Text(
                  'সর্বমোট গণনা রিসেট…',
                  style: TextStyle(color: AppColors.dangerRed),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Size the counter from the available space so small screens
            // and large text scales don't overflow.
            final circleSize = math
                .min(constraints.maxWidth - 80, constraints.maxHeight * 0.42)
                .clamp(150.0, 250.0)
                .toDouble();

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildDhikrSelector(currentDhikr, textScaler),
                        const SizedBox(height: 16),
                        _buildDhikrCard(currentDhikr),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          _buildCounter(tasbeeh, circleSize),
                          const SizedBox(height: 12),
                          const Text(
                            'গণনা করতে গোল অংশে ট্যাপ করুন',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSubdued,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        // Target selector pills
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            children: [
                              for (final target in tasbeehTargetOptions(
                                tasbeeh,
                              ))
                                _buildTargetPill(tasbeeh, target),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLifetimeBar(tasbeeh),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDhikrSelector(DhikrItem currentDhikr, TextScaler textScaler) {
    return SizedBox(
      height: math.max(40.0, textScaler.scale(13) * 1.6 + 18),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: DhikrItem.presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = DhikrItem.presets[index];
          final isSelected = item.id == currentDhikr.id;

          return Semantics(
            button: true,
            selected: isSelected,
            child: InkWell(
              onTap: () {
                ref.read(tasbeehProvider.notifier).selectDhikr(item);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                alignment: Alignment.center,
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
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDhikrCard(DhikrItem currentDhikr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
              textAlign: TextAlign.center,
              style: AppFonts.arabicStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                height: 1.7,
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
    );
  }

  Widget _buildCounter(TasbeehState tasbeeh, double circleSize) {
    final isComplete = tasbeeh.isCycleComplete;
    return Semantics(
      button: true,
      label: tasbeehCounterSemanticLabel(tasbeeh),
      hint: 'গণনা বাড়াতে ট্যাপ করুন',
      onTap: _onTapCounter,
      excludeSemantics: true,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: _onTapCounter,
          child: Container(
            width: circleSize,
            height: circleSize,
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
                  width: circleSize - 14,
                  height: circleSize - 14,
                  child: CircularProgressIndicator(
                    value: tasbeeh.progress,
                    strokeWidth: 10,
                    backgroundColor: AppColors.cardBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete ? AppColors.activeGreen : AppColors.gold,
                    ),
                  ),
                ),

                // Center Count Content (scales down to fit the ring)
                SizedBox(
                  width: circleSize * 0.64,
                  height: circleSize * 0.64,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _toBnNumber(tasbeeh.currentCount),
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: isComplete
                                ? AppColors.activeGreen
                                : AppColors.primaryDark,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          isComplete
                              ? 'চক্র সম্পন্ন!'
                              : '(${tasbeeh.currentCount})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isComplete
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isComplete
                                ? AppColors.activeGreen
                                : AppColors.textSubdued,
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLifetimeBar(TasbeehState tasbeeh) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'সর্বমোট তাসবীহ আদায়',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
    );
  }

  Widget _buildTargetPill(TasbeehState state, int target) {
    final isSelected = state.targetCount == target;
    final label = target == 0 ? 'অসীম (∞)' : _toBnNumber(target);
    final semanticLabel = target == 0
        ? 'অসীম লক্ষ্য'
        : 'লক্ষ্য ${_toBnNumber(target)}';
    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => ref.read(tasbeehProvider.notifier).setTarget(target),
        borderRadius: BorderRadius.circular(14),
        // Keep the compact pill look but give it a >=48dp tap target.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(
            widthFactor: 1.0,
            heightFactor: 1.0,
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
          ),
        ),
      ),
    );
  }
}
