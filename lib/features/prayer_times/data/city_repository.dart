import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/city_model.dart';

/// Picks the most plausible IANA zone for a city inside a country.
///
/// Single-zone countries use their only zone. For multi-zone countries the
/// zone whose standard offset is closest to the city's solar offset
/// (longitude / 15°) is chosen — a good approximation in the absence of
/// per-city zone data.
String? pickZoneForCity(List<dynamic>? zones, double longitude) {
  if (zones == null || zones.isEmpty) return null;
  if (zones.length == 1) return zones.first['znm'] as String?;
  final solarOffsetSeconds = longitude * 240.0;
  String? best;
  double bestDiff = double.infinity;
  for (final z in zones) {
    final offset = (z['gmtOffset'] as num?)?.toDouble();
    final name = z['znm'] as String?;
    if (offset == null || name == null) continue;
    final diff = (offset - solarOffsetSeconds).abs();
    if (diff < bestDiff) {
      bestDiff = diff;
      best = name;
    }
  }
  return best ?? zones.first['znm'] as String?;
}

List<CityModel> _parseCitiesIsolate(String jsonString) {
  final List<dynamic> countriesJson = json.decode(jsonString);
  final List<CityModel> allCities = [];

  for (final country in countriesJson) {
    final countryName = country['nm'] as String? ?? '';
    final countryEmoji = country['emoji'] as String? ?? '🌍';
    final bool isBd = countryName.toLowerCase() == 'bangladesh';
    final zones = country['tzs'] as List<dynamic>?;

    final cities = country['cities'] as List<dynamic>? ?? [];
    for (final c in cities) {
      final lng = (c['ln'] as num).toDouble();
      allCities.add(CityModel(
        id: c['id'] as int,
        name: c['nm'] as String,
        countryName: countryName,
        countryEmoji: countryEmoji,
        latitude: (c['lt'] as num).toDouble(),
        longitude: lng,
        isBangladeshDistrict: isBd,
        timeZone: isBd ? 'Asia/Dhaka' : pickZoneForCity(zones, lng),
      ));
    }
  }
  return allCities;
}

class CityRepository {
  static const String _prefKeySelectedCity = 'pref_selected_city_json';

  List<CityModel>? _cachedCities;
  List<CityModel>? _cachedBddistricts;
  List<String>? _searchKeys;

  Future<void> _ensureLoaded() async {
    if (_cachedCities != null) return;

    final jsonString =
        await rootBundle.loadString('assets/data/countries+cities.json');
    _cachedCities = await compute(_parseCitiesIsolate, jsonString);
    _cachedBddistricts =
        _cachedCities!.where((c) => c.isBangladeshDistrict).toList();
    // Pre-lowercased search keys avoid allocating ~150k strings per keystroke.
    _searchKeys = _cachedCities!
        .map((c) => '${c.name.toLowerCase()}|${c.countryName.toLowerCase()}')
        .toList(growable: false);
  }

  Future<List<CityModel>> getBangladeshDistricts() async {
    await _ensureLoaded();
    return _cachedBddistricts ?? [];
  }

  Future<List<CityModel>> searchCities(String query, {int limit = 30}) async {
    await _ensureLoaded();
    if (_cachedCities == null || _cachedCities!.isEmpty) return [];

    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return _cachedBddistricts?.take(limit).toList() ?? [];
    }

    // Prefer Bangladesh districts and name-prefix matches, then the rest.
    final prefix = <CityModel>[];
    final contains = <CityModel>[];
    final keys = _searchKeys!;
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      if (!key.contains(cleanQuery)) continue;
      final city = _cachedCities![i];
      if (key.startsWith(cleanQuery)) {
        if (city.isBangladeshDistrict) {
          prefix.insert(0, city);
        } else {
          prefix.add(city);
        }
      } else {
        contains.add(city);
      }
      if (prefix.length >= limit) break;
    }
    return [...prefix, ...contains].take(limit).toList();
  }

  Future<CityModel> findNearestCity(double lat, double lng) async {
    await _ensureLoaded();
    if (_cachedCities == null || _cachedCities!.isEmpty) {
      return CityModel.dhakaDefault();
    }

    CityModel? nearest;
    double minDistance = double.infinity;

    // Equirectangular approximation: scale longitude by cos(latitude) so
    // east-west degrees are not over-weighted away from the equator.
    final cosLat = math.cos(lat * math.pi / 180.0);
    for (final city in _cachedCities!) {
      final dLat = city.latitude - lat;
      var dLng = (city.longitude - lng).abs();
      if (dLng > 180) dLng = 360 - dLng;
      dLng *= cosLat;
      final distSquared = dLat * dLat + dLng * dLng;
      if (distSquared < minDistance) {
        minDistance = distSquared;
        nearest = city;
      }
    }

    return nearest ?? CityModel.dhakaDefault();
  }

  Future<CityModel> getSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKeySelectedCity);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        final city = CityModel.fromJson(decoded);
        if (city.effectiveTimeZone == null) {
          // Saved before time zones were tracked: resolve and persist once.
          final resolved = await _resolveTimeZone(city);
          if (resolved.timeZone != null) await saveSelectedCity(resolved);
          return resolved;
        }
        return city;
      } catch (_) {}
    }
    return CityModel.dhakaDefault();
  }

  Future<void> saveSelectedCity(CityModel city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeySelectedCity, json.encode(city.toJson()));
  }

  Future<CityModel> _resolveTimeZone(CityModel city) async {
    try {
      await _ensureLoaded();
      for (final c in _cachedCities!) {
        if (c.id == city.id) return city.copyWith(timeZone: c.timeZone);
      }
    } catch (_) {}
    return city;
  }
}
