import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class ArcTimerWidget extends StatelessWidget {
  final String locationText;
  final String currentTimeString;
  final String periodString; // AM / PM
  final String nextPrayerLabel;
  final String nextPrayerRemaining;
  final double progress; // 0.0 to 1.0
  final String fajrTime;
  final String iftarTime;

  const ArcTimerWidget({
    super.key,
    required this.locationText,
    required this.currentTimeString,
    required this.periodString,
    required this.nextPrayerLabel,
    required this.nextPrayerRemaining,
    required this.progress,
    required this.fajrTime,
    required this.iftarTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Arc Visual
        SizedBox(
          width: 280,
          height: 160,
          child: CustomPaint(
            painter: _ArcPainter(
              progress: progress.clamp(0.0, 1.0),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Location label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        locationText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Large digital time display
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currentTimeString,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          periodString,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Next prayer badge
                    Text(
                      '$nextPrayerLabel in $nextPrayerRemaining',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Flanking Quick Stats: Fajr & Iftar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Fajr quick stat
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wb_twilight_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fajr',
                        style: TextStyle(
                          color: AppColors.textLightSubdued,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        fajrTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Iftar quick stat
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Iftar',
                        style: TextStyle(
                          color: AppColors.textLightSubdued,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        iftarTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wb_sunny_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;

  _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 16;

    // 1. Draw inner semicircle dome with Islamic notch at bottom
    final domePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF27AE60),
          Color(0xFF1E824C),
          Color(0xFF145A32),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 10))
      ..style = PaintingStyle.fill;

    final domePath = Path();
    domePath.moveTo(center.dx - (radius - 12), center.dy);
    domePath.arcTo(
      Rect.fromCircle(center: center, radius: radius - 12),
      math.pi,
      math.pi,
      false,
    );
    // Draw bottom baseline with curved Islamic center notch
    final notchRadius = 24.0;
    domePath.lineTo(center.dx + notchRadius, center.dy);
    domePath.arcToPoint(
      Offset(center.dx - notchRadius, center.dy),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    domePath.close();

    canvas.drawPath(domePath, domePaint);

    // 2. Outer Track Arc
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(arcRect, math.pi, math.pi, false, trackPaint);

    // 3. Active Progress Arc (Golden Amber)
    if (progress > 0.0) {
      final activePaint = Paint()
        ..shader = const LinearGradient(
          colors: [
            AppColors.goldLight,
            AppColors.gold,
            Color(0xFFFF8F00),
          ],
        ).createShader(arcRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;

      final sweepAngle = math.pi * progress;
      canvas.drawArc(arcRect, math.pi, sweepAngle, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
