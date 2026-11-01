import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deener_alo/features/tasbeeh/domain/dhikr_item.dart';
import 'package:deener_alo/features/tasbeeh/presentation/tasbeeh_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Digital Tasbeeh Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial TasbeehState defaults correctly', () {
      final notifier = TasbeehNotifier();
      expect(notifier.state.currentCount, equals(0));
      expect(notifier.state.targetCount, equals(33));
      expect(notifier.state.completedCycles, equals(0));
      expect(notifier.state.hapticEnabled, isTrue);
      expect(notifier.state.soundEnabled, isFalse);
      expect(notifier.state.totalLifetimeCount, equals(0));
    });

    test('Increment counter rolls over upon reaching target', () {
      final notifier = TasbeehNotifier();
      notifier.setTarget(3);

      notifier.increment();
      expect(notifier.state.currentCount, equals(1));
      expect(notifier.state.lifetimeCount, equals(1));
      expect(notifier.state.completedCycles, equals(0));

      notifier.increment();
      expect(notifier.state.currentCount, equals(2));
      expect(notifier.state.lifetimeCount, equals(2));
      expect(notifier.state.completedCycles, equals(0));

      // Reaching target (3): shows the completed count (3/3).
      notifier.increment();
      expect(notifier.state.currentCount, equals(3));
      expect(notifier.state.isCycleComplete, isTrue);
      expect(notifier.state.progress, equals(1.0));
      expect(notifier.state.lifetimeCount, equals(3));
      expect(notifier.state.completedCycles, equals(1));

      // Next tap starts the new cycle at 1.
      notifier.increment();
      expect(notifier.state.currentCount, equals(1));
      expect(notifier.state.isCycleComplete, isFalse);
      expect(notifier.state.lifetimeCount, equals(4));
      expect(notifier.state.completedCycles, equals(1));
    });

    test('Unlimited mode (target = 0) does not reset on arbitrary counts', () {
      final notifier = TasbeehNotifier();
      notifier.setTarget(0);

      for (var i = 0; i < 50; i++) {
        notifier.increment();
      }

      expect(notifier.state.currentCount, equals(50));
      expect(notifier.state.completedCycles, equals(0));
    });

    test('Selecting preset updates dhikr and recommended target', () {
      final notifier = TasbeehNotifier();
      final tahlil = DhikrItem.presets.firstWhere((d) => d.id == 'tahlil');

      notifier.selectDhikr(tahlil);
      expect(notifier.state.currentDhikr.id, equals('tahlil'));
      expect(notifier.state.targetCount, equals(100));
      expect(notifier.state.currentCount, equals(0));
    });

    test('Reset current clears count but preserves lifetime count', () {
      final notifier = TasbeehNotifier();
      notifier.increment();
      notifier.increment();
      expect(notifier.state.currentCount, equals(2));
      expect(notifier.state.lifetimeCount, equals(2));

      notifier.resetCurrent();
      expect(notifier.state.currentCount, equals(0));
      expect(notifier.state.lifetimeCount, equals(2));
    });
  });
}
