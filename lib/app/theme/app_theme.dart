import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_fonts.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final textTheme = ThemeData.light().textTheme.apply(
          fontFamily: AppFonts.ui,
          fontFamilyFallback: AppFonts.fallback,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppFonts.ui,
      fontFamilyFallback: AppFonts.fallback,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.gold,
        surface: AppColors.cardWhite,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColors.textDark,
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: AppColors.textDark),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSubdued,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: AppFonts.ui,
            fontFamilyFallback: AppFonts.fallback,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: const TextStyle(
          fontFamily: AppFonts.ui,
          fontFamilyFallback: AppFonts.fallback,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.ui,
          fontFamilyFallback: AppFonts.fallback,
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = ThemeData.dark().textTheme.apply(
          fontFamily: AppFonts.ui,
          fontFamilyFallback: AppFonts.fallback,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppFonts.ui,
      fontFamilyFallback: AppFonts.fallback,
      primaryColor: AppColors.primaryLight,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.gold,
        surface: AppColors.cardDark,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColors.textLight,
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: AppColors.textLight,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: AppColors.textLight,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: AppColors.textLight),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColors.textLightSubdued,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: AppFonts.ui,
            fontFamilyFallback: AppFonts.fallback,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.ui,
          fontFamilyFallback: AppFonts.fallback,
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }
}
