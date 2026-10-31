import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/city_model.dart';

class CityRepository {
  static const String _prefKeySelectedCity = 'pref_selected_city_json';

  List<CityModel>? _cachedCities;
  List<CityModel>? _cachedBddistricts;

  Future<void> _ensureLoaded() async {
    if (_cachedCities != null) return;

    final jsonString =
        await rootBundle.loadString('assets/data/countries+cities.json');
    final List<dynamic> countriesJson = json.decode(jsonString);

    final List<CityModel> allCities = [];
    final List<CityModel> bdCities = [];

    for (final country in countriesJson) {
      final countryName = country['nm'] as String? ?? '';
      final countryEmoji = country['emoji'] as String? ?? '🌍';
      final bool isBd = countryName.toLowerCase() == 'bangladesh';

      final cities = country['cities'] as List<dynamic>? ?? [];
      for (final c in cities) {
        final city = CityModel(
          id: c['id'] as int,
          name: c['nm'] as String,
          countryName: countryName,
          countryEmoji: countryEmoji,
          latitude: (c['lt'] as num).toDouble(),
          longitude: (c['ln'] as num).toDouble(),
          isBangladeshDistrict: isBd,
        );
        allCities.add(city);
        if (isBd) {
          bdCities.add(city);
        }
      }
    }

    _cachedCities = allCities;
    _cachedBddistricts = bdCities;
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

    final matches = <CityModel>[];
    for (final city in _cachedCities!) {
      if (city.name.toLowerCase().contains(cleanQuery) ||
          city.countryName.toLowerCase().contains(cleanQuery)) {
        matches.add(city);
        if (matches.length >= limit) break;
      }
    }
    return matches;
  }

  Future<CityModel> findNearestCity(double lat, double lng) async {
    await _ensureLoaded();
    if (_cachedCities == null || _cachedCities!.isEmpty) {
      return CityModel.dhakaDefault();
    }

    CityModel? nearest;
    double minDistance = double.infinity;

    for (final city in _cachedCities!) {
      final dLat = city.latitude - lat;
      final dLng = city.longitude - lng;
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
        return CityModel.fromJson(decoded);
      } catch (_) {}
    }
    return CityModel.dhakaDefault();
  }

  Future<void> saveSelectedCity(CityModel city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeySelectedCity, json.encode(city.toJson()));
  }
}
