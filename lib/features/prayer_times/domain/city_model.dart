class CityModel {
  final int id;
  final String name;
  final String countryName;
  final String countryEmoji;
  final double latitude;
  final double longitude;
  final bool isBangladeshDistrict;

  /// IANA time zone of the city (e.g. `Asia/Dhaka`). Prayer times are always
  /// computed and displayed on this city's wall clock. `null` means unknown,
  /// in which case the device's local time zone is used.
  final String? timeZone;

  const CityModel({
    required this.id,
    required this.name,
    required this.countryName,
    required this.countryEmoji,
    required this.latitude,
    required this.longitude,
    this.isBangladeshDistrict = false,
    this.timeZone,
  });

  /// Time zone to use for this city, with a safe default for Bangladesh.
  String? get effectiveTimeZone =>
      timeZone ??
      ((isBangladeshDistrict || countryName.toLowerCase() == 'bangladesh')
          ? 'Asia/Dhaka'
          : null);

  CityModel copyWith({String? timeZone}) => CityModel(
        id: id,
        name: name,
        countryName: countryName,
        countryEmoji: countryEmoji,
        latitude: latitude,
        longitude: longitude,
        isBangladeshDistrict: isBangladeshDistrict,
        timeZone: timeZone ?? this.timeZone,
      );

  factory CityModel.dhakaDefault() {
    return const CityModel(
      id: 8486,
      name: 'Dhaka',
      countryName: 'Bangladesh',
      countryEmoji: '🇧🇩',
      latitude: 23.778714,
      longitude: 90.397965,
      isBangladeshDistrict: true,
      timeZone: 'Asia/Dhaka',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'countryName': countryName,
        'countryEmoji': countryEmoji,
        'latitude': latitude,
        'longitude': longitude,
        'isBangladeshDistrict': isBangladeshDistrict,
        if (timeZone != null) 'timeZone': timeZone,
      };

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as int,
      name: json['name'] as String,
      countryName: json['countryName'] as String,
      countryEmoji: (json['countryEmoji'] as String?) ?? '🌍',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isBangladeshDistrict: (json['isBangladeshDistrict'] as bool?) ?? false,
      timeZone: json['timeZone'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CityModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          countryName == other.countryName;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ countryName.hashCode;
}

