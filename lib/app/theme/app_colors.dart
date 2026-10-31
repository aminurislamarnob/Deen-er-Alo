import 'package:flutter/material.dart';

/// App color palette matching the modern Emerald & Gold Islamic design system.
class AppColors {
  AppColors._();

  // Primary Islamic Emerald Greens
  static const Color primaryDark = Color(0xFF072B1E);
  static const Color primary = Color(0xFF0D3D2A);
  static const Color primaryMedium = Color(0xFF13533A);
  static const Color primaryLight = Color(0xFF1C6B4C);
  static const Color emeraldBright = Color(0xFF27AE60);
  static const Color mintAccent = Color(0xFF2ECC71);

  // Radiant Golden Ambers
  static const Color gold = Color(0xFFF7B52C);
  static const Color goldLight = Color(0xFFFFD269);
  static const Color goldDark = Color(0xFFD8920E);
  static const Color goldMuted = Color(0xFFFBF1D9);

  // Backgrounds & Surfaces
  static const Color bgDark = Color(0xFF062319);
  static const Color bgLight = Color(0xFFF5F7F5);
  static const Color cardWhite = Colors.white;
  static const Color cardDark = Color(0xFF0F3627);
  static const Color cardBorder = Color(0xFFE5EFE8);
  static const Color surfaceMuted = Color(0xFFF0F5F2);

  // Text Colors
  static const Color textDark = Color(0xFF14241E);
  static const Color textSubdued = Color(0xFF6A7F76);
  static const Color textLight = Colors.white;
  static const Color textLightSubdued = Color(0xFFBDD9CC);

  // Action / State Colors
  static const Color activeGreen = Color(0xFF0EA371);
  static const Color inactiveMuted = Color(0xFFA1B3AA);
  static const Color dangerRed = Color(0xFFE53935);

  // Gradients
  static const LinearGradient islamicGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, primary, primaryMedium],
  );

  static const LinearGradient cardHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient arcFillGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2ECC71), Color(0xFF1E824C)],
  );
}

