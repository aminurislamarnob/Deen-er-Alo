import '../../prayer_times/domain/prayer_model.dart';

enum PrayerStatus {
  /// Not logged yet (default for every prayer of a fresh day).
  none('চিহ্নিত নয়', 0),

  /// Explicitly marked as missed ("আদায় হয়নি"). Adds one to the qaza balance.
  notOffered('আদায় হয়নি', 0),
  alone('একাকী', 1),
  jamaat('জামাতে', 2),

  /// Missed on time but made up later (qaza performed).
  qaza('কাজা', 3);

  final String label;
  final int score;
  const PrayerStatus(this.label, this.score);

  /// True when the prayer was actually performed (on time or made up).
  bool get countsAsPrayed =>
      this == PrayerStatus.jamaat ||
      this == PrayerStatus.alone ||
      this == PrayerStatus.qaza;

  /// How many outstanding qaza prayers this status represents.
  int get qazaContribution => this == PrayerStatus.notOffered ? 1 : 0;
}

/// Change to the qaza balance when a prayer's status moves from [from] to [to].
///
/// Entering "missed" adds one, leaving "missed" removes one. Because the delta
/// is derived purely from the old and new status, toggling back and forth can
/// never double count.
int qazaDeltaFor(PrayerStatus from, PrayerStatus to) =>
    to.qazaContribution - from.qazaContribution;

/// Approximate number of missed fard prayers for a backlog period
/// (5 prayers per day; a year counts as 365 days and a month as 30 days).
int qazaBacklogPrayers({int years = 0, int months = 0, int days = 0}) {
  final totalDays = years * 365 + months * 30 + days;
  return totalDays <= 0 ? 0 : totalDays * 5;
}

/// The five fard prayers tracked per day.
const List<PrayerType> fardPrayerTypes = [
  PrayerType.fajr,
  PrayerType.dhuhr,
  PrayerType.asr,
  PrayerType.maghrib,
  PrayerType.isha,
];

enum FastingStatus {
  notFasting('রোজা রাখা হয়নি'),
  ramadanFarz('রমজানের ফরজ রোজা'),
  nafl('নফল রোজা (সুন্নাত)'),
  qaza('কাজা রোজা');

  final String label;
  const FastingStatus(this.label);
}

class DailyHabitRecord {
  /// Version 2 introduced [PrayerStatus.none]. Version 1 records used
  /// `notOffered` as the untouched default, so it is read back as `none`.
  static const int schemaVersion = 2;

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
      prayers: {for (final type in fardPrayerTypes) type: PrayerStatus.none},
    );
  }

  /// Prayers performed on time (jama'at or alone).
  int get completedPrayerCount => prayers.values
      .where((s) => s == PrayerStatus.jamaat || s == PrayerStatus.alone)
      .length;

  /// Prayers performed at all (on time or made up as qaza).
  int get prayedCount => prayers.values.where((s) => s.countsAsPrayed).length;

  /// A day is complete when all five fard prayers were performed.
  bool get isAllFardPrayed => fardPrayerTypes.every(
    (t) => (prayers[t] ?? PrayerStatus.none).countsAsPrayed,
  );

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
    'v': schemaVersion,
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
    final version = (json['v'] as num?)?.toInt() ?? 1;
    final Map<PrayerType, PrayerStatus> prayers = {};

    for (final type in fardPrayerTypes) {
      final valStr = prayersRaw[type.name] as String?;
      PrayerStatus status = PrayerStatus.none;
      if (valStr != null) {
        try {
          status = PrayerStatus.values.byName(valStr);
        } catch (_) {}
      }
      if (version < 2 && status == PrayerStatus.notOffered) {
        // Legacy default: "not offered" meant "not logged yet".
        status = PrayerStatus.none;
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
