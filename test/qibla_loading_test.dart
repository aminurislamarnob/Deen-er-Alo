import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deener_alo/features/qibla/domain/qibla_compass_model.dart';
import 'package:deener_alo/features/qibla/presentation/qibla_providers.dart';

void main() {
  group('qiblaStateProvider loading state', () {
    test('reports isLoading (not a fake heading) before first event', () async {
      final controller = StreamController<double?>();
      addTearDown(controller.close);
      final container = ProviderContainer(
        overrides: [
          qiblaBearingProvider.overrideWithValue(277.6),
          compassEventsProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(qiblaStateProvider, (_, __) {});
      addTearDown(sub.close);

      final loading = container.read(qiblaStateProvider);
      expect(loading.isLoading, isTrue);
      expect(loading.hasSensor, isTrue);
      expect(loading.isAligned, isFalse);

      controller.add(277.0);
      await Future<void>.delayed(Duration.zero);
      final ready = container.read(qiblaStateProvider);
      expect(ready.isLoading, isFalse);
      expect(ready.userHeading, 277.0);
      expect(ready.isAligned, isTrue);
    });

    test('null heading means no sensor (not loading)', () async {
      final container = ProviderContainer(
        overrides: [
          qiblaBearingProvider.overrideWithValue(277.6),
          compassEventsProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(qiblaStateProvider, (_, __) {});
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(qiblaStateProvider);
      expect(state.isLoading, isFalse);
      expect(state.hasSensor, isFalse);
    });

    test('model never reports aligned while loading', () {
      const model = QiblaCompassModel(
        userHeading: 277.6,
        qiblaBearing: 277.6,
        hasSensor: true,
        isLoading: true,
      );
      expect(model.isAligned, isFalse);
    });
  });
}
