import '../../prayer_times/domain/prayer_model.dart';

enum PrayerStatus {
  notOffered('আদায় হয়নি', 0),
  alone('একাকী', 1),
  jamaat('জামাতে', 2),
  qaza('কাজা', 3);

  final String label;
  final int score;
  const PrayerStatus(this.label, this.score);
}

enum FastingStatus {
  notFasting('রোজা রাখা হয়নি'),
  ramadanFarz('রমজানের ফরজ রোজা'),
  nafl('নফল রোজা (সুন্নাত)'),
  qaza('কাজা রোজা');

  final String label;
  const FastingStatus(this.label);
}

class DailyHabitRecord {
  final String dateStr; // Format: YYYY-MM-DD
  final Map<PrayerType, PrayerStatus> prayers;
  final FastingStatus fasting;
  final bool readQuran;
  final bool morningEveningAdhkar;
  final bool tahajjudOrDuha;
  final bool gaveSadaqah;

  const DailyHabitRecord({
    required this.dateStr,
    required this.prayers,
    this.fasting = FastingStatus.notFasting,
    this.readQuran = false,
    this.morningEveningAdhkar = false,
    this.tahajjudOrDuha = false,
    this.gaveSadaqah = false,
  });

  factory DailyHabitRecord.empty(String dateStr) {
    return DailyHabitRecord(
      dateStr: dateStr,
      prayers: {
        PrayerType.fajr: PrayerStatus.notOffered,
        PrayerType.dhuhr: PrayerStatus.notOffered,
        PrayerType.asr: PrayerStatus.notOffered,
        PrayerType.maghrib: PrayerStatus.notOffered,
        PrayerType.isha: PrayerStatus.notOffered,
      },
    );
  }

  int get completedPrayerCount => prayers.values
      .where((s) => s == PrayerStatus.jamaat || s == PrayerStatus.alone)
      .length;

  DailyHabitRecord copyWith({
    String? dateStr,
    Map<PrayerType, PrayerStatus>? prayers,
    FastingStatus? fasting,
    bool? readQuran,
    bool? morningEveningAdhkar,
    bool? tahajjudOrDuha,
    bool? gaveSadaqah,
  }) {
    return DailyHabitRecord(
      dateStr: dateStr ?? this.dateStr,
      prayers: prayers ?? this.prayers,
      fasting: fasting ?? this.fasting,
      readQuran: readQuran ?? this.readQuran,
      morningEveningAdhkar: morningEveningAdhkar ?? this.morningEveningAdhkar,
      tahajjudOrDuha: tahajjudOrDuha ?? this.tahajjudOrDuha,
      gaveSadaqah: gaveSadaqah ?? this.gaveSadaqah,
    );
  }

  Map<String, dynamic> toJson() => {
        'dateStr': dateStr,
        'prayers': prayers.map((k, v) => MapEntry(k.name, v.name)),
        'fasting': fasting.name,
        'readQuran': readQuran,
        'morningEveningAdhkar': morningEveningAdhkar,
        'tahajjudOrDuha': tahajjudOrDuha,
        'gaveSadaqah': gaveSadaqah,
      };

  factory DailyHabitRecord.fromJson(Map<String, dynamic> json) {
    final prayersRaw = json['prayers'] as Map<String, dynamic>? ?? {};
    final Map<PrayerType, PrayerStatus> prayers = {};

    for (final type in PrayerType.values) {
      if (type == PrayerType.sunrise) continue;
      final valStr = prayersRaw[type.name] as String?;
      PrayerStatus status = PrayerStatus.notOffered;
      if (valStr != null) {
        try {
          status = PrayerStatus.values.byName(valStr);
        } catch (_) {}
      }
      prayers[type] = status;
    }

    FastingStatus fasting = FastingStatus.notFasting;
    if (json['fasting'] != null) {
      try {
        fasting = FastingStatus.values.byName(json['fasting'].toString());
      } catch (_) {}
    }

    return DailyHabitRecord(
      dateStr: json['dateStr'] as String? ?? '',
      prayers: prayers,
      fasting: fasting,
      readQuran: json['readQuran'] as bool? ?? false,
      morningEveningAdhkar: json['morningEveningAdhkar'] as bool? ?? false,
      tahajjudOrDuha: json['tahajjudOrDuha'] as bool? ?? false,
      gaveSadaqah: json['gaveSadaqah'] as bool? ?? false,
    );
  }
}

class HabitStreakSummary {
  final int streakDays;
  final int weeklyPrayersOffered;
  final int weeklyJamaatCount;
  final int monthlyFastingDays;
  final int qazaBalance;

  const HabitStreakSummary({
    required this.streakDays,
    required this.weeklyPrayersOffered,
    required this.weeklyJamaatCount,
    required this.monthlyFastingDays,
    required this.qazaBalance,
  });
}
