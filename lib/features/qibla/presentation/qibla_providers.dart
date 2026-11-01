import 'package:adhan/adhan.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../prayer_times/presentation/prayer_providers.dart';
import '../domain/qibla_compass_model.dart';

/// Provider for calculating the true Qibla bearing for the selected city.
final qiblaBearingProvider = Provider<double>((ref) {
  final cityAsync = ref.watch(selectedCityProvider);
  final city = cityAsync.value;

  final lat = city?.latitude ?? 23.8103;
  final lng = city?.longitude ?? 90.4125;

  final qibla = Qibla(Coordinates(lat, lng));
  return qibla.direction;
});

/// Stream provider for raw hardware compass events.
final compassEventsProvider = StreamProvider.autoDispose<CompassEvent?>((ref) {
  final events = FlutterCompass.events;
  if (events == null) {
    return Stream.value(null);
  }
  return events;
});

/// Combined state provider for the Qibla Compass.
final qiblaStateProvider = Provider.autoDispose<QiblaCompassModel>((ref) {
  final qiblaBearing = ref.watch(qiblaBearingProvider);
  final compassEventAsync = ref.watch(compassEventsProvider);

  return compassEventAsync.when(
    data: (event) {
      if (event == null || event.heading == null) {
        // Device lacks hardware compass or simulator mode
        return QiblaCompassModel(
          userHeading: 0.0,
          qiblaBearing: qiblaBearing,
          hasSensor: false,
        );
      }

      // Smooth heading (positive 0 - 360)
      final heading = (event.heading! % 360.0 + 360.0) % 360.0;
      return QiblaCompassModel(
        userHeading: heading,
        qiblaBearing: qiblaBearing,
        hasSensor: true,
        accuracy: event.accuracy,
      );
    },
    loading: () => QiblaCompassModel(
      userHeading: 0.0,
      qiblaBearing: qiblaBearing,
      hasSensor: true,
    ),
    error: (_, __) => QiblaCompassModel(
      userHeading: 0.0,
      qiblaBearing: qiblaBearing,
      hasSensor: false,
    ),
  );
});
