import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:deener_alo/features/names/data/names_repository.dart';
import 'package:deener_alo/features/names/domain/allah_name_model.dart';

void main() {
  group('99 Names of Allah Tests', () {
    test('names_data.json contains 99 valid authentic names', () {
      final file = File('assets/data/names_data.json');
      expect(file.existsSync(), isTrue);

      final jsonStr = file.readAsStringSync();
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      final list = decoded['data'] as List<dynamic>;

      expect(list.length, equals(99));

      for (var i = 0; i < list.length; i++) {
        final item = list[i] as Map<String, dynamic>;
        final name = AllahName.fromJson(item);

        expect(name.id, equals(i + 1));
        expect(name.nameArabic.isNotEmpty, isTrue);
        expect(name.transliteration.isNotEmpty, isTrue);
        expect(name.pronunciationBn.isNotEmpty, isTrue);
        expect(name.meaningBn.isNotEmpty, isTrue);
        expect(name.meaningEn.isNotEmpty, isTrue);
        expect(name.description.isNotEmpty, isTrue);
        expect(name.quranReference.isNotEmpty, isTrue);
        expect(name.hadithReference.isNotEmpty, isTrue);
      }
    });

    test('NamesRepository search filters correctly', () {
      final repo = NamesRepository();
      final sampleNames = [
        const AllahName(
          id: 1,
          nameArabic: 'الله',
          transliteration: 'Allah',
          pronunciationBn: 'আল্লাহ',
          meaningEn: 'The Greatest Name',
          meaningBn: 'একমাত্র উপাস্য',
          description: 'সৃষ্টিকর্তা',
        ),
        const AllahName(
          id: 2,
          nameArabic: 'الرَّحْمَنُ',
          transliteration: 'Ar-Rahman',
          pronunciationBn: 'আর-রহমান',
          meaningEn: 'The Most Gracious',
          meaningBn: 'পরম দয়ালু',
          description: 'অনন্ত করুণাময়',
        ),
        const AllahName(
          id: 3,
          nameArabic: 'الْمَلِكُ',
          transliteration: 'Al-Malik',
          pronunciationBn: 'আল-মালিক',
          meaningEn: 'The King',
          meaningBn: 'সার্বভৌম মালিক',
          description: 'রাজাধিরাজ',
        ),
      ];

      // Search by Bengali pronunciation
      final resultBn = repo.searchNames(sampleNames, 'রহমান');
      expect(resultBn.length, equals(1));
      expect(resultBn.first.id, equals(2));

      // Search by English transliteration
      final resultEn = repo.searchNames(sampleNames, 'malik');
      expect(resultEn.length, equals(1));
      expect(resultEn.first.id, equals(3));

      // Search by Arabic
      final resultAr = repo.searchNames(sampleNames, 'الله');
      expect(resultAr.length, equals(1));
      expect(resultAr.first.id, equals(1));

      // Search by ID
      final resultId = repo.searchNames(sampleNames, '3');
      expect(resultId.length, equals(1));
      expect(resultId.first.transliteration, equals('Al-Malik'));
    });
  });
}
