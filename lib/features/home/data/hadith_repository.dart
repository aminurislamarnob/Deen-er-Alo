import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HadithItem {
  final int id;
  final String title;
  final String text;

  const HadithItem({
    required this.id,
    required this.title,
    required this.text,
  });
}

class HadithRepository {
  List<HadithItem>? _cachedHadiths;

  Future<void> _loadHadiths() async {
    if (_cachedHadiths != null) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/selected_hadith.json');
      final data = json.decode(jsonStr) as List<dynamic>;
      _cachedHadiths = data.map((item) {
        final rawText = (item['data'] as String? ?? '').replaceAll('<br>', '\n');
        return HadithItem(
          id: item['id'] as int? ?? 1,
          title: item['title'] as String? ?? 'দৈনিক হাদীস',
          text: rawText,
        );
      }).toList();
    } catch (_) {
      _cachedHadiths = [];
    }
  }

  Future<HadithItem?> getDailyHadith() async {
    await _loadHadiths();
    if (_cachedHadiths == null || _cachedHadiths!.isEmpty) return null;
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final index = dayOfYear % _cachedHadiths!.length;
    return _cachedHadiths![index];
  }
}

final hadithRepositoryProvider = Provider<HadithRepository>((ref) {
  return HadithRepository();
});

final dailyHadithProvider = FutureProvider<HadithItem?>((ref) async {
  final repo = ref.watch(hadithRepositoryProvider);
  return repo.getDailyHadith();
});
