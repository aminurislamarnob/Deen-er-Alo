import 'package:flutter/material.dart';
import '../../app/theme/app_fonts.dart';

/// Arabic text rendered right-to-left with the bundled Arabic font.
class ArabicText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final TextAlign textAlign;
  final double height;
  final int? maxLines;
  final TextOverflow? overflow;

  const ArabicText(
    this.text, {
    super.key,
    this.fontSize = 22,
    this.fontWeight = FontWeight.w400,
    this.color,
    this.textAlign = TextAlign.center,
    this.height = 1.9,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textDirection: TextDirection.rtl,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: AppFonts.arabicStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      ),
    );
  }
}
