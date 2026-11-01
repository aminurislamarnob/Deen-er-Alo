class IslamicEvent {
  final int hijriMonth;
  final int hijriDay;
  final String titleBn;
  final String titleEn;
  final String descriptionBn;
  final bool isMajor;
  final bool isFastingRecommended;

  const IslamicEvent({
    required this.hijriMonth,
    required this.hijriDay,
    required this.titleBn,
    required this.titleEn,
    required this.descriptionBn,
    this.isMajor = false,
    this.isFastingRecommended = false,
  });
}
