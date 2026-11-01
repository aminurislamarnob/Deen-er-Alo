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

/// Stream provider for compass events smoothed across the 0/360 degree seam.
final compassEventsProvider = StreamProvider.autoDispose<double?>((ref) {
  final events = FlutterCompass.events;
  if (events == null) {
    return Stream.value(null);
  }

  double? previousHeading;
  return events.map((event) {
    final heading = event.heading;
    if (heading == null) {
      previousHeading = null;
      return null;
    }

    final normalized = (heading % 360.0 + 360.0) % 360.0;
    if (previousHeading == null) {
      previousHeading = normalized;
    } else {
      var delta = normalized - previousHeading!;
      if (delta > 180) delta -= 360;
      if (delta < -180) delta += 360;
      previousHeading = (previousHeading! + delta * 0.2 + 360.0) % 360.0;
    }

    return previousHeading;
  });
});

/// Combined state provider for the Qibla Compass.
final qiblaStateProvider = Provider.autoDispose<QiblaCompassModel>((ref) {
  final qiblaBearing = ref.watch(qiblaBearingProvider);
  final compassEventAsync = ref.watch(compassEventsProvider);

  return compassEventAsync.when(
    data: (event) {
      if (event == null) {
        // Device lacks hardware compass or simulator mode
        return QiblaCompassModel(
          userHeading: 0.0,
          qiblaBearing: qiblaBearing,
          hasSensor: false,
        );
      }

      // Smooth heading (positive 0 - 360)
      return QiblaCompassModel(
        userHeading: event,
        qiblaBearing: qiblaBearing,
        hasSensor: true,
      );
    },
    // No real heading yet: report a loading state instead of a fake 0°.
    loading: () => QiblaCompassModel(
      userHeading: 0.0,
      qiblaBearing: qiblaBearing,
      hasSensor: true,
      isLoading: true,
    ),
    error: (_, __) => QiblaCompassModel(
      userHeading: 0.0,
      qiblaBearing: qiblaBearing,
      hasSensor: false,
    ),
  );
});
