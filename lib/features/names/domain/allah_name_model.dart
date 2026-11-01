/// Represents one of the 99 Beautiful Names of Allah (Asmaul Husna).
class AllahName {
  final int id;
  final String nameArabic;
  final String transliteration;
  final String pronunciationBn;
  final String meaningEn;
  final String meaningBn;
  final String description;
  final String quranReference;
  final String hadithReference;

  const AllahName({
    required this.id,
    required this.nameArabic,
    required this.transliteration,
    required this.pronunciationBn,
    required this.meaningEn,
    required this.meaningBn,
    required this.description,
    this.quranReference = '',
    this.hadithReference = '',
  });

  factory AllahName.fromJson(Map<String, dynamic> json) {
    return AllahName(
      id: json['id'] as int? ?? 0,
      nameArabic: json['name_arabic'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      pronunciationBn: json['pronunciation_bn'] as String? ?? '',
      meaningEn: json['meaning_en'] as String? ?? '',
      meaningBn: json['meaning_bn'] as String? ?? '',
      description: json['description'] as String? ?? '',
      quranReference: json['quran_reference'] as String? ?? '',
      hadithReference: json['hadith_reference'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_arabic': nameArabic,
      'transliteration': transliteration,
      'pronunciation_bn': pronunciationBn,
      'meaning_en': meaningEn,
      'meaning_bn': meaningBn,
      'description': description,
      'quran_reference': quranReference,
      'hadith_reference': hadithReference,
    };
  }
}
