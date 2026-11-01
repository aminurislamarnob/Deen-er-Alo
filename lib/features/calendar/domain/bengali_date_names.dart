import '../../../core/utils/bangla_numbers.dart';

/// Bengali Gregorian month and weekday names (no locale initialisation needed).
class BengaliDateNames {
  BengaliDateNames._();

  static const List<String> months = [
    'জানুয়ারি',
    'ফেব্রুয়ারি',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টেম্বর',
    'অক্টোবর',
    'নভেম্বর',
    'ডিসেম্বর',
  ];

  /// Indexed by `DateTime.weekday - 1` (Monday first).
  static const List<String> weekdays = [
    'সোমবার',
    'মঙ্গলবার',
    'বুধবার',
    'বৃহস্পতিবার',
    'শুক্রবার',
    'শনিবার',
    'রবিবার',
  ];

  static String month(int month) => months[month - 1];

  static String weekday(DateTime date) => weekdays[date.weekday - 1];

  /// e.g. "১ নভেম্বর, ২০২৬"
  static String dayMonthYear(DateTime date) =>
      '${BanglaUtils.toBanglaDigits(date.day)} ${month(date.month)}, '
      '${BanglaUtils.toBanglaDigits(date.year)}';

  /// e.g. "রবিবার, ১ নভেম্বর ২০২৬"
  static String fullDate(DateTime date) =>
      '${weekday(date)}, ${BanglaUtils.toBanglaDigits(date.day)} '
      '${month(date.month)} ${BanglaUtils.toBanglaDigits(date.year)}';

  /// e.g. "নভেম্বর ২০২৬"
  static String monthYear(DateTime date) =>
      '${month(date.month)} ${BanglaUtils.toBanglaDigits(date.year)}';
}
