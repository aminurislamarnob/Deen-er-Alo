import 'package:geolocator/geolocator.dart';

/// Why the last location lookup failed (null = success).
enum LocationFailure { serviceDisabled, denied, deniedForever, unavailable }

class LocationService {
  LocationFailure? lastFailure;

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  Future<Position?> getCurrentPosition() async {
    lastFailure = null;
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      lastFailure = LocationFailure.serviceDisabled;
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        lastFailure = LocationFailure.denied;
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      lastFailure = LocationFailure.deniedForever;
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) lastFailure = LocationFailure.unavailable;
      return last;
    }
  }
}

