import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/allah_name_model.dart';

class NamesRepository {
  List<AllahName>? _cachedNames;

  Future<List<AllahName>> loadNames() async {
    if (_cachedNames != null) {
      return _cachedNames!;
    }

    try {
      final jsonStr = await rootBundle.loadString('assets/data/names_data.json');
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
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return source;

    return source.where((name) {
      return name.id.toString() == trimmed ||
          name.transliteration.toLowerCase().contains(trimmed) ||
          name.pronunciationBn.toLowerCase().contains(trimmed) ||
          name.meaningBn.toLowerCase().contains(trimmed) ||
          name.meaningEn.toLowerCase().contains(trimmed) ||
          name.nameArabic.contains(trimmed);
    }).toList();
  }
}
