import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/prayer_source.dart';

class PrayerSourceNotifier extends StateNotifier<PrayerCalculationSource> {
  static const _prefKey = 'deener_alo_prayer_source_v1';
  final Completer<void> _loaded = Completer<void>();

  PrayerSourceNotifier() : super(PrayerCalculationSource.ifb) {
    _load();
  }

  /// Completes once the saved source has been loaded from storage.
  Future<void> get ready => _loaded.future;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null) {
        if (saved == PrayerCalculationSource.karachi.name) {
          if (mounted) state = PrayerCalculationSource.karachi;
        } else {
          if (mounted) state = PrayerCalculationSource.ifb;
        }
      }
    } catch (_) {
      // Keep default (ifb)
    } finally {
      if (!_loaded.isCompleted) _loaded.complete();
    }
  }

  Future<void> setSource(PrayerCalculationSource source) async {
    await ready;
    if (state == source) return;
    state = source;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, source.name);
    } catch (_) {}
  }
}

final prayerSourceProvider =
    StateNotifierProvider<PrayerSourceNotifier, PrayerCalculationSource>((ref) {
  return PrayerSourceNotifier();
});
