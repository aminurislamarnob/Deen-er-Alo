import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Converts between real instants and a city's *wall clock*.
///
/// Prayer times are computed and displayed on the selected city's wall clock,
/// represented as plain (non-UTC) [DateTime] values whose fields equal the
/// clock reading in that city. This keeps every `DateFormat`, comparison and
/// countdown consistent even when the device's own time zone differs from the
/// city's (e.g. a user abroad who selects Dhaka).
///
/// When the city's zone is unknown (`null`), the device's local zone is used,
/// so wall-clock values are ordinary local [DateTime]s.
class CityClock {
  CityClock._();

  static bool _initialized = false;

  /// Loads the IANA time zone database (idempotent, cheap after first call).
  static void ensureInitialized() {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
    } catch (e) {
      debugPrint('CityClock: time zone init failed: $e');
    }
    _initialized = true;
  }

  static tz.Location? _location(String? zone) {
    if (zone == null || zone.isEmpty) return null;
    ensureInitialized();
    try {
      return tz.getLocation(zone);
    } catch (_) {
      return null;
    }
  }

  /// Whether [zone] is a known IANA zone name.
  static bool isValidZone(String? zone) => _location(zone) != null;

  /// UTC offset of [zone] at the given [instant]. Falls back to the device's
  /// offset when the zone is unknown.
  static Duration offsetAt(String? zone, DateTime instant) {
    final loc = _location(zone);
    if (loc == null) return instant.toLocal().timeZoneOffset;
    return Duration(
      milliseconds: loc.timeZone(instant.toUtc().millisecondsSinceEpoch).offset,
    );
  }

  /// Wall-clock reading in [zone] at [instant].
  static DateTime toWall(DateTime instant, String? zone) {
    if (_location(zone) == null) return instant.toLocal();
    final shifted = instant.toUtc().add(offsetAt(zone, instant));
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
    );
  }

  /// Current wall-clock time in [zone].
  static DateTime now(String? zone) => toWall(DateTime.now(), zone);

  /// Converts a wall-clock reading in [zone] back to a real instant (UTC).
  static DateTime toInstant(DateTime wall, String? zone) {
    if (_location(zone) == null) {
      // Wall values are device-local already.
      return DateTime(
        wall.year,
        wall.month,
        wall.day,
        wall.hour,
        wall.minute,
        wall.second,
        wall.millisecond,
      ).toUtc();
    }
    final asUtc = DateTime.utc(
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
      wall.second,
      wall.millisecond,
    );
    // Two passes resolve the offset correctly around DST transitions.
    var guess = asUtc.subtract(offsetAt(zone, asUtc));
    guess = asUtc.subtract(offsetAt(zone, guess));
    return guess;
  }

  /// Converts a value carrying UTC-shifted fields (as returned by `adhan` when
  /// given a `utcOffset`) into a plain wall-clock [DateTime].
  static DateTime stripUtcFlag(DateTime shifted) => DateTime(
        shifted.year,
        shifted.month,
        shifted.day,
        shifted.hour,
        shifted.minute,
        shifted.second,
        shifted.millisecond,
      );

  /// Date-only (midnight) of a wall-clock value.
  static DateTime dateOnly(DateTime wall) =>
      DateTime(wall.year, wall.month, wall.day);
}
