enum PrayerCalculationSource {
  ifb,
  karachi;

  String get displayName {
    switch (this) {
      case PrayerCalculationSource.ifb:
        return 'ইসলামিক ফাউন্ডেশন বাংলাদেশ';
      case PrayerCalculationSource.karachi:
        return 'জ্যোতির্বিজ্ঞান ভিত্তিক (করাচি পদ্ধতি)';
    }
  }

  String get shortName {
    switch (this) {
      case PrayerCalculationSource.ifb:
        return 'ইসলামিক ফাউন্ডেশন';
      case PrayerCalculationSource.karachi:
        return 'করাচি পদ্ধতি';
    }
  }

  String get description {
    switch (this) {
      case PrayerCalculationSource.ifb:
        return 'সরকারি স্থায়ী ক্যালেন্ডারের সময়সূচি অনুযায়ী';
      case PrayerCalculationSource.karachi:
        return 'করাচি ১৮°/১৮° ও হানাফি আসর কোণ অনুযায়ী';
    }
  }
}
