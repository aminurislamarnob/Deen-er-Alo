enum NotificationAlarmTone {
  adhan('আযান', 'deener_alo_prayer_adhan'),
  chime('নরম চিম/টোন', 'deener_alo_prayer_chime'),
  silent('নীরব নোটিফিকেশন', 'deener_alo_prayer_silent'),
  off('বন্ধ', '');

  final String label;
  final String channelId;
  const NotificationAlarmTone(this.label, this.channelId);
}

class NotificationSettings {
  final bool masterEnabled;
  final NotificationAlarmTone fajrTone;
  final NotificationAlarmTone dhuhrTone;
  final NotificationAlarmTone asrTone;
  final NotificationAlarmTone maghribTone;
  final NotificationAlarmTone ishaTone;
  final bool sunriseReminder;
  final bool tahajjudReminder;
  final bool duhaReminder;
  final bool sehriWarning;
  final bool iftarReminder;
  final bool dailyAdhkarReminder;
  final int advanceMinutes;

  const NotificationSettings({
    this.masterEnabled = true,
    this.fajrTone = NotificationAlarmTone.adhan,
    this.dhuhrTone = NotificationAlarmTone.adhan,
    this.asrTone = NotificationAlarmTone.adhan,
    this.maghribTone = NotificationAlarmTone.adhan,
    this.ishaTone = NotificationAlarmTone.adhan,
    this.sunriseReminder = false,
    this.tahajjudReminder = false,
    this.duhaReminder = false,
    this.sehriWarning = true,
    this.iftarReminder = true,
    this.dailyAdhkarReminder = true,
    this.advanceMinutes = 0,
  });

  NotificationSettings copyWith({
    bool? masterEnabled,
    NotificationAlarmTone? fajrTone,
    NotificationAlarmTone? dhuhrTone,
    NotificationAlarmTone? asrTone,
    NotificationAlarmTone? maghribTone,
    NotificationAlarmTone? ishaTone,
    bool? sunriseReminder,
    bool? tahajjudReminder,
    bool? duhaReminder,
    bool? sehriWarning,
    bool? iftarReminder,
    bool? dailyAdhkarReminder,
    int? advanceMinutes,
  }) {
    return NotificationSettings(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      fajrTone: fajrTone ?? this.fajrTone,
      dhuhrTone: dhuhrTone ?? this.dhuhrTone,
      asrTone: asrTone ?? this.asrTone,
      maghribTone: maghribTone ?? this.maghribTone,
      ishaTone: ishaTone ?? this.ishaTone,
      sunriseReminder: sunriseReminder ?? this.sunriseReminder,
      tahajjudReminder: tahajjudReminder ?? this.tahajjudReminder,
      duhaReminder: duhaReminder ?? this.duhaReminder,
      sehriWarning: sehriWarning ?? this.sehriWarning,
      iftarReminder: iftarReminder ?? this.iftarReminder,
      dailyAdhkarReminder: dailyAdhkarReminder ?? this.dailyAdhkarReminder,
      advanceMinutes: advanceMinutes ?? this.advanceMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'masterEnabled': masterEnabled,
        'fajrTone': fajrTone.name,
        'dhuhrTone': dhuhrTone.name,
        'asrTone': asrTone.name,
        'maghribTone': maghribTone.name,
        'ishaTone': ishaTone.name,
        'sunriseReminder': sunriseReminder,
        'tahajjudReminder': tahajjudReminder,
        'duhaReminder': duhaReminder,
        'sehriWarning': sehriWarning,
        'iftarReminder': iftarReminder,
        'dailyAdhkarReminder': dailyAdhkarReminder,
        'advanceMinutes': advanceMinutes,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    NotificationAlarmTone parseTone(dynamic val, NotificationAlarmTone fallback) {
      if (val == null) return fallback;
      try {
        return NotificationAlarmTone.values.byName(val.toString());
      } catch (_) {
        return fallback;
      }
    }

    return NotificationSettings(
      masterEnabled: json['masterEnabled'] as bool? ?? true,
      fajrTone: parseTone(json['fajrTone'], NotificationAlarmTone.adhan),
      dhuhrTone: parseTone(json['dhuhrTone'], NotificationAlarmTone.adhan),
      asrTone: parseTone(json['asrTone'], NotificationAlarmTone.adhan),
      maghribTone: parseTone(json['maghribTone'], NotificationAlarmTone.adhan),
      ishaTone: parseTone(json['ishaTone'], NotificationAlarmTone.adhan),
      sunriseReminder: json['sunriseReminder'] as bool? ?? false,
      tahajjudReminder: json['tahajjudReminder'] as bool? ?? false,
      duhaReminder: json['duhaReminder'] as bool? ?? false,
      sehriWarning: json['sehriWarning'] as bool? ?? true,
      iftarReminder: json['iftarReminder'] as bool? ?? true,
      dailyAdhkarReminder: json['dailyAdhkarReminder'] as bool? ?? true,
      advanceMinutes: json['advanceMinutes'] as int? ?? 0,
    );
  }
}
