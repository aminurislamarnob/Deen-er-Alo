import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Thin wrapper over the Android `MainActivity` method channel for opening
/// system settings screens that affect alarm reliability.
class SystemSettingsService {
  SystemSettingsService._();
  static final SystemSettingsService instance = SystemSettingsService._();

  static const MethodChannel _channel =
      MethodChannel('com.deeneralo.deener_alo/system');

  Future<bool> _call(String method) async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } catch (e) {
      debugPrint('SystemSettingsService.$method failed: $e');
      return false;
    }
  }

  /// Whether the app is exempt from battery optimisation (Android).
  /// Non-Android platforms have no such restriction, so they report `true`.
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel
              .invokeMethod<bool>('isIgnoringBatteryOptimizations') ??
          true;
    } catch (_) {
      return true; // Unknown: don't nag the user.
    }
  }

  Future<bool> openBatteryOptimizationSettings() =>
      _call('openBatteryOptimizationSettings');

  Future<bool> openExactAlarmSettings() => _call('openExactAlarmSettings');

  Future<bool> openAppSettings() => _call('openAppSettings');
}
