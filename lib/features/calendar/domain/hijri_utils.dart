import 'package:hijri/hijri_calendar.dart';

/// Strips the time part of [date] (local calendar day).
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Adds [days] calendar days using field arithmetic, which is safe across DST
/// transitions (unlike `add(Duration(days: n))`).
DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Hijri date for the Gregorian [date], shifted by the user's moon-sighting
/// adjustment [offsetDays] (e.g. +1 means the local Hijri date is one day
/// ahead of the Umm al-Qura calculation).
HijriCalendar hijriForDate(DateTime date, int offsetDays) {
  return HijriCalendar.fromDate(addDays(date, offsetDays));
}

/// Inverse of [hijriForDate]: the Gregorian day whose adjusted Hijri date is
/// [hDay]/[hMonth]/[hYear].
DateTime gregorianForHijri(int hYear, int hMonth, int hDay, int offsetDays) {
  final g = HijriCalendar().hijriToGregorian(hYear, hMonth, hDay);
  return addDays(g, -offsetDays);
}

/// Gregorian date of Akhiri Chahar Shomba (the last Wednesday of Safar) in
/// Hijri year [hYear], honouring the moon-sighting offset.
DateTime lastWednesdayOfSafar(int hYear, int offsetDays) {
  final firstOfRabiulAwwal = gregorianForHijri(hYear, 3, 1, offsetDays);
  var d = addDays(firstOfRabiulAwwal, -1); // last day of Safar
  while (d.weekday != DateTime.wednesday) {
    d = addDays(d, -1);
  }
  return d;
}

/// Whether [date] is the last Wednesday of Safar (Akhiri Chahar Shomba).
bool isAkhiriChaharShomba(DateTime date, int offsetDays) {
  if (date.weekday != DateTime.wednesday) return false;
  if (hijriForDate(date, offsetDays).hMonth != 2) return false;
  return hijriForDate(addDays(date, 7), offsetDays).hMonth != 2;
}
