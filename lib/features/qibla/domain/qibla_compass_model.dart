/// Immutable model representing the Qibla Compass state.
class QiblaCompassModel {
  static const double alignmentToleranceDegrees = 2.0;

  /// The device's current heading in degrees [0, 360).
  final double userHeading;

  /// The true bearing to the Kaaba from current coordinates [0, 360).
  final double qiblaBearing;

  /// Whether the hardware compass/magnetometer sensor is available.
  final bool hasSensor;

  /// Accuracy/calibration level if provided by sensor.
  final double? accuracy;

  const QiblaCompassModel({
    required this.userHeading,
    required this.qiblaBearing,
    required this.hasSensor,
    this.accuracy,
  });

  /// The difference in degrees between user's heading and Qibla direction.
  /// Normalized to [-180, 180].
  double get deltaAngle {
    double diff = (userHeading - qiblaBearing) % 360.0;
    if (diff > 180.0) diff -= 360.0;
    if (diff < -180.0) diff += 360.0;
    return diff;
  }

  /// Whether the user is pointed directly at the Kaaba (within +/- 2 degrees).
  bool get isAligned => deltaAngle.abs() <= alignmentToleranceDegrees;

  /// Cardinal direction string in Bengali.
  String get cardinalDirectionBn {
    final deg = (userHeading % 360 + 360) % 360;
    if (deg >= 337.5 || deg < 22.5) return 'উত্তর (N)';
    if (deg >= 22.5 && deg < 67.5) return 'উত্তর-পূর্ব (NE)';
    if (deg >= 67.5 && deg < 112.5) return 'পূর্ব (E)';
    if (deg >= 112.5 && deg < 157.5) return 'দক্ষিণ-পূর্ব (SE)';
    if (deg >= 157.5 && deg < 202.5) return 'দক্ষিণ (S)';
    if (deg >= 202.5 && deg < 247.5) return 'দক্ষিণ-পশ্চিম (SW)';
    if (deg >= 247.5 && deg < 292.5) return 'পশ্চিম (W)';
    return 'উত্তর-পশ্চিম (NW)';
  }
}
