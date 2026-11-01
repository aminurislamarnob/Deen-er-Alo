import 'dart:convert';
import 'package:flutter/services.dart';
import '../../dua/domain/search_normalizer.dart';
import '../domain/allah_name_model.dart';

class NamesRepository {
  List<AllahName>? _cachedNames;

  Future<List<AllahName>> loadNames() async {
    if (_cachedNames != null) {
      return _cachedNames!;
    }

    try {
      final jsonStr = await rootBundle.loadString(
        'assets/data/names_data.json',
      );
      final dynamic decoded = json.decode(jsonStr);

      final List<dynamic> list;
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        list = decoded['data'] as List<dynamic>;
      } else if (decoded is List<dynamic>) {
        list = decoded;
      } else {
        list = [];
      }

      _cachedNames = list
          .map((item) => AllahName.fromJson(item as Map<String, dynamic>))
          .toList();
      return _cachedNames!;
    } catch (_) {
      return [];
    }
  }

  List<AllahName> searchNames(List<AllahName> source, String query) {
    final normalized = SearchNormalizer.normalize(query);
    if (normalized.isEmpty) return source;

    // Numeric search by id, accepting Bengali digits ("১২" -> 12).
    final asciiDigits = SearchNormalizer.bengaliDigitsToAscii(normalized);
    final numericId = RegExp(r'^\d+$').hasMatch(asciiDigits)
        ? int.tryParse(asciiDigits)
        : null;

    // A purely numeric query is an id lookup.
    if (numericId != null) {
      return source.where((name) => name.id == numericId).toList();
    }

    return source.where((name) {
      return SearchNormalizer.matchesAny(normalized, [
        name.transliteration,
        name.pronunciationBn,
        name.meaningBn,
        name.meaningEn,
        name.nameArabic,
      ]);
    }).toList();
  }
}
