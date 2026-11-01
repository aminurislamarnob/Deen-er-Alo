import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deener_alo/features/qibla/domain/qibla_compass_model.dart';

void main() {
  group('Qibla Compass Tests', () {
    test('Adhan Qibla direction calculates accurately for Dhaka', () {
      // Dhaka coordinates: 23.8103, 90.4125
      final qibla = Qibla(Coordinates(23.8103, 90.4125));
      final direction = qibla.direction;

      // Great-circle bearing from Dhaka to Mecca is approx 277.6 degrees
      expect(direction, closeTo(277.6, 0.5));
    });

    test('Adhan Qibla direction calculates accurately for London', () {
      // London coordinates: 51.5074, -0.1278
      final qibla = Qibla(Coordinates(51.5074, -0.1278));
      final direction = qibla.direction;

      // Bearing from London to Mecca is approx 119 degrees
      expect(direction, closeTo(118.9, 0.5));
    });

    test('QiblaCompassModel deltaAngle and alignment logic', () {
      const qiblaBearing = 268.5;

      // Directly aligned
      final modelAligned = QiblaCompassModel(
        userHeading: 269.0,
        qiblaBearing: qiblaBearing,
        hasSensor: true,
      );
      expect(modelAligned.deltaAngle, closeTo(0.5, 0.01));
      expect(modelAligned.isAligned, isTrue);

      // Boundary aligned (+3.0 deg)
      final modelBoundary = QiblaCompassModel(
        userHeading: 271.4,
        qiblaBearing: qiblaBearing,
        hasSensor: true,
      );
      expect(modelBoundary.isAligned, isTrue);

      // Not aligned (40 deg off)
      final modelUnaligned = QiblaCompassModel(
        userHeading: 310.0,
        qiblaBearing: qiblaBearing,
        hasSensor: true,
      );
      expect(modelUnaligned.deltaAngle, closeTo(41.5, 0.01));
      expect(modelUnaligned.isAligned, isFalse);
    });

    test('Cardinal direction Bengali strings', () {
      expect(
        const QiblaCompassModel(
          userHeading: 0.0,
          qiblaBearing: 268.5,
          hasSensor: true,
        ).cardinalDirectionBn,
        equals('উত্তর (N)'),
      );

      expect(
        const QiblaCompassModel(
          userHeading: 90.0,
          qiblaBearing: 268.5,
          hasSensor: true,
        ).cardinalDirectionBn,
        equals('পূর্ব (E)'),
      );

      expect(
        const QiblaCompassModel(
          userHeading: 180.0,
          qiblaBearing: 268.5,
          hasSensor: true,
        ).cardinalDirectionBn,
        equals('দক্ষিণ (S)'),
      );

      expect(
        const QiblaCompassModel(
          userHeading: 270.0,
          qiblaBearing: 268.5,
          hasSensor: true,
        ).cardinalDirectionBn,
        equals('পশ্চিম (W)'),
      );
    });
  });
}
