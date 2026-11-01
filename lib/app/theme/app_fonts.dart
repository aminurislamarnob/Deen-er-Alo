import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// Bundled font families (see `assets/fonts/` and `pubspec.yaml`).
///
/// All fonts ship with the app, so text renders identically offline and on
/// first launch. Licences (SIL OFL 1.1) are in `assets/fonts/licenses/` and
/// registered with Flutter's licence page via [registerLicenses].
class AppFonts {
  AppFonts._();

  /// Latin UI text and digits.
  static const String ui = 'PlusJakartaSans';

  /// Bengali script (picked automatically per glyph via [fallback]).
  static const String bengali = 'NotoSansBengali';

  /// Arabic: Quranic text, duas, dhikr and the Names of Allah.
  static const String arabic = 'Amiri';

  /// Glyph-level fallback for the UI font: any Bengali or Arabic character in
  /// an ordinary `Text` is rendered with the bundled script font instead of a
  /// device-dependent system font.
  static const List<String> fallback = [bengali, arabic];

  /// Style for Arabic text. The generous [height] keeps stacked harakat
  /// (vowel marks) from being clipped between lines.
  static TextStyle arabicStyle({
    double fontSize = 22,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double height = 1.9,
  }) {
    return TextStyle(
      fontFamily: arabic,
      fontFamilyFallback: const [ui, bengali],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static const Map<String, String> _licenses = {
    'Plus Jakarta Sans': 'assets/fonts/licenses/PlusJakartaSans-OFL.txt',
    'Noto Sans Bengali': 'assets/fonts/licenses/NotoSansBengali-OFL.txt',
    'Amiri': 'assets/fonts/licenses/Amiri-OFL.txt',
  };

  /// Adds the bundled fonts' OFL licences to `showLicensePage`.
  static void registerLicenses() {
    LicenseRegistry.addLicense(() async* {
      for (final entry in _licenses.entries) {
        yield LicenseEntryWithLineBreaks([
          entry.key,
        ], await rootBundle.loadString(entry.value));
      }
    });
  }
}
