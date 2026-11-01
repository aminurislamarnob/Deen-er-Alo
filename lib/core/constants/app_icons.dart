import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Centralized Icon Registry for Deener Alo.
///
/// Combines 2px-stroke [LucideIcons] for standard UI controls with
/// custom matching 2px-stroke SVG icons for specific Islamic symbols.
abstract final class AppIcons {
  // --- Navigation & Core App ---
  static const IconData home = LucideIcons.home;
  static const IconData prayers = LucideIcons.clock;
  static const IconData quran = LucideIcons.bookOpen;
  static const IconData dua = LucideIcons.sparkles;
  static const IconData more = LucideIcons.layoutGrid;

  // --- Prayer Times & Celestial ---
  static const IconData fajr = LucideIcons.sunrise;
  static const IconData sunrise = LucideIcons.sunrise;
  static const IconData dhuhr = LucideIcons.sun;
  static const IconData asr = LucideIcons.sunMedium;
  static const IconData maghrib = LucideIcons.sunset;
  static const IconData isha = LucideIcons.moonStar;
  static const IconData prohibited = LucideIcons.triangleAlert;
  static const IconData sehri = LucideIcons.moon;
  static const IconData iftar = LucideIcons.sunset;

  // --- General UI Controls ---
  static const IconData compass = LucideIcons.compass;
  static const IconData calendar = LucideIcons.calendar;
  static const IconData mapPin = LucideIcons.mapPin;
  static const IconData locate = LucideIcons.locateFixed;
  static const IconData bell = LucideIcons.bell;
  static const IconData bellOff = LucideIcons.bellOff;
  static const IconData volumeOn = LucideIcons.volume2;
  static const IconData volumeOff = LucideIcons.volumeOff;
  static const IconData checkCircle = LucideIcons.circleCheck;
  static const IconData uncheckCircle = LucideIcons.circle;
  static const IconData quote = LucideIcons.quote;
  static const IconData share = LucideIcons.share2;
  static const IconData search = LucideIcons.search;
  static const IconData settings = LucideIcons.settings;
  static const IconData back = LucideIcons.arrowLeft;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData bookmark = LucideIcons.bookmark;
  static const IconData info = LucideIcons.info;
  static const IconData fingerTouch = LucideIcons.fingerprint;

  // --- Dedicated Islamic Vector Assets ---
  static const String kaabaSvg = 'assets/icons/kaaba.svg';
  static const String mosqueSvg = 'assets/icons/mosque.svg';
  static const String tasbeehSvg = 'assets/icons/tasbeeh.svg';
  static const String handsPrayingSvg = 'assets/icons/hands_praying.svg';

  /// Helper widget to render an Islamic SVG icon with consistent sizing and tint.
  static Widget svg(
    String assetPath, {
    double size = 24.0,
    Color? color,
  }) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }
}

