import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_icons.dart';

class QiblaCompassDial extends StatelessWidget {
  final double heading; // in degrees
  final double qiblaBearing; // in degrees
  final bool isAligned;
  final double size;

  const QiblaCompassDial({
    super.key,
    required this.heading,
    required this.qiblaBearing,
    required this.isAligned,
    this.size = 280,
  });

  @override
  Widget build(BuildContext context) {
    // Rotation angle for the dial: -heading degrees in radians
    final dialRotation = -heading * (math.pi / 180.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow when aligned
          if (isAligned)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: size + 20,
              height: size + 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emeraldBright.withValues(alpha: 0.35),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),

          // Rotating Compass Face
          Transform.rotate(
            angle: dialRotation,
            child: CustomPaint(
              size: Size(size, size),
              painter: _CompassFacePainter(
                qiblaBearing: qiblaBearing,
                isAligned: isAligned,
              ),
            ),
          ),

          // Center Medallion with Kaaba Vector
          Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAligned ? AppColors.primary : Colors.white,
              border: Border.all(
                color: isAligned ? AppColors.gold : AppColors.cardBorder,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isAligned
                      ? AppColors.gold.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: AppIcons.svg(
                AppIcons.kaabaSvg,
                size: size * 0.15,
                color: isAligned ? AppColors.goldLight : AppColors.primary,
              ),
            ),
          ),

          // Fixed Top Needle (Phone Target Indicator at 12 o'clock)
          Positioned(
            top: 0,
            child: Container(
              width: 14,
              height: 18,
              decoration: BoxDecoration(
                color: isAligned ? AppColors.gold : AppColors.primary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
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

class _CompassFacePainter extends CustomPainter {
  final double qiblaBearing;
  final bool isAligned;

  _CompassFacePainter({
    required this.qiblaBearing,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background disk
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Border ring
    final borderPaint = Paint()
      ..color = isAligned ? AppColors.emeraldBright : AppColors.cardBorder
      ..strokeWidth = isAligned ? 3.0 : 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 2, borderPaint);

    // Inner subtle ring
    final innerRingPaint = Paint()
      ..color = AppColors.surfaceMuted
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * 0.72, innerRingPaint);

    // Draw degree tick marks
    final tickPaint = Paint()
      ..color = AppColors.textSubdued.withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final majorTickPaint = Paint()
      ..color = AppColors.textSubdued
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 360; i += 5) {
      final rad = i * (math.pi / 180.0) - (math.pi / 2);
      final isMajor = i % 30 == 0;
      final tickLength = isMajor ? 12.0 : 6.0;

      final startX = center.dx + (radius - 8) * math.cos(rad);
      final startY = center.dy + (radius - 8) * math.sin(rad);
      final endX = center.dx + (radius - 8 - tickLength) * math.cos(rad);
      final endY = center.dy + (radius - 8 - tickLength) * math.sin(rad);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        isMajor ? majorTickPaint : tickPaint,
      );
    }

    // Draw Cardinal Labels
    _drawText(canvas, 'N', center, radius - 30, 0, color: const Color(0xFFE53935), isBold: true);
    _drawText(canvas, 'E', center, radius - 30, 90, color: AppColors.textDark, isBold: true);
    _drawText(canvas, 'S', center, radius - 30, 180, color: AppColors.textDark, isBold: true);
    _drawText(canvas, 'W', center, radius - 30, 270, color: AppColors.textDark, isBold: true);

    // Draw Qibla Pointer Marker on the dial
    final qiblaRad = qiblaBearing * (math.pi / 180.0) - (math.pi / 2);
    final qiblaX = center.dx + (radius - 22) * math.cos(qiblaRad);
    final qiblaY = center.dy + (radius - 22) * math.sin(qiblaRad);

    // Qibla direction beam
    final beamPaint = Paint()
      ..color = isAligned
          ? AppColors.emeraldBright
          : AppColors.gold.withValues(alpha: 0.8)
      ..strokeWidth = isAligned ? 3.0 : 2.0
      ..strokeCap = StrokeCap.round;

    final beamStartX = center.dx + (radius * 0.38) * math.cos(qiblaRad);
    final beamStartY = center.dy + (radius * 0.38) * math.sin(qiblaRad);
    canvas.drawLine(
      Offset(beamStartX, beamStartY),
      Offset(qiblaX, qiblaY),
      beamPaint,
    );

    // Kaaba pointer pin
    final pinPaint = Paint()
      ..color = isAligned ? AppColors.emeraldBright : AppColors.gold
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(qiblaX, qiblaY), 8, pinPaint);

    final pinBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(qiblaX, qiblaY), 8, pinBorder);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    double distFromCenter,
    double angleDeg, {
    required Color color,
    bool isBold = false,
  }) {
    final rad = angleDeg * (math.pi / 180.0) - (math.pi / 2);
    final textX = center.dx + distFromCenter * math.cos(rad);
    final textY = center.dy + distFromCenter * math.sin(rad);

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassFacePainter oldDelegate) {
    return oldDelegate.qiblaBearing != qiblaBearing ||
        oldDelegate.isAligned != isAligned;
  }
}
