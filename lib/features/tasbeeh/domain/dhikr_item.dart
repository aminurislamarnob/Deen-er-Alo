class DhikrItem {
  final String id;
  final String arabicText;
  final String transliteration;
  final String bengaliMeaning;
  final int recommendedTarget;

  const DhikrItem({
    required this.id,
    required this.arabicText,
    required this.transliteration,
    required this.bengaliMeaning,
    required this.recommendedTarget,
  });

  static const List<DhikrItem> presets = [
    DhikrItem(
      id: 'subhanallah',
      arabicText: 'سُبْحَانَ اللَّهِ',
      transliteration: 'Subhanallah',
      bengaliMeaning: 'আল্লাহ অতি পবিত্র ও ত্রুটিমুক্ত',
      recommendedTarget: 33,
    ),
    DhikrItem(
      id: 'alhamdulillah',
      arabicText: 'الْحَمْدُ لِلَّهِ',
      transliteration: 'Alhamdulillah',
      bengaliMeaning: 'সমস্ত প্রশংসা একমাত্র আল্লাহর জন্য',
      recommendedTarget: 33,
    ),
    DhikrItem(
      id: 'allahuakbar',
      arabicText: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allahu Akbar',
      bengaliMeaning: 'আল্লাহ মহান ও সর্বশ্রেষ্ঠ',
      recommendedTarget: 34,
    ),
    DhikrItem(
      id: 'tahlil',
      arabicText: 'لَا إِلٰهَ إِلَّا اللَّهُ',
      transliteration: 'La ilaha illallah',
      bengaliMeaning: 'আল্লাহ ব্যতীত কোনো সত্য উপাস্য নেই',
      recommendedTarget: 100,
    ),
    DhikrItem(
      id: 'istighfar',
      arabicText: 'أَسْتَغْفِرُ اللَّهَ',
      transliteration: 'Astaghfirullah',
      bengaliMeaning: 'আমি আল্লাহর নিকট ক্ষমা প্রার্থনা করছি',
      recommendedTarget: 100,
    ),
    DhikrItem(
      id: 'salawat',
      arabicText: 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ',
      transliteration: 'Allahumma Salli Ala Muhammad',
      bengaliMeaning: 'হে আল্লাহ! হযরত মুহাম্মাদ (ﷺ)-এর ওপর শান্তি বর্ষণ করুন',
      recommendedTarget: 100,
    ),
    DhikrItem(
      id: 'hawqala',
      arabicText: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      transliteration: 'La Hawla wa la Quwwata illa billah',
      bengaliMeaning: 'আল্লাহর সাহায্য ছাড়া কোনো শক্তি বা সামর্থ্য নেই',
      recommendedTarget: 100,
    ),
    DhikrItem(
      id: 'custom',
      arabicText: 'ذِكْرٌ عُمُومِيٌّ',
      transliteration: 'Free Dhikr',
      bengaliMeaning: 'ইচ্ছামতো যেকোনো যিক্‌র বা তাসবীহ',
      recommendedTarget: 33,
    ),
  ];
}
