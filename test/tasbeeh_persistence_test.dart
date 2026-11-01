import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deener_alo/features/tasbeeh/domain/dhikr_item.dart';
import 'package:deener_alo/features/tasbeeh/presentation/tasbeeh_provider.dart';
import 'package:deener_alo/features/tasbeeh/presentation/tasbeeh_screen.dart';

String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tasbeeh merge-on-load', () {
    test(
      'tap before load completes adds to stored lifetime (no wipe)',
      () async {
        SharedPreferences.setMockInitialValues({
          TasbeehNotifier.keyLifetime: 5000,
          TasbeehNotifier.keyCycles: 3,
          TasbeehNotifier.keyCyclesDate: _key(DateTime.now()),
          TasbeehNotifier.keyHaptic: false,
          TasbeehNotifier.keySound: true,
        });
        final n = TasbeehNotifier(
          saveDebounce: const Duration(milliseconds: 10),
        );
        n.increment(); // before load has completed
        expect(n.isLoaded, isFalse);
        expect(n.state.lifetimeCount, 1);

        await n.ready;
        expect(n.state.lifetimeCount, 5001);
        expect(n.state.completedCycles, 3);
        expect(n.state.hapticEnabled, isFalse);
        expect(n.state.soundEnabled, isTrue);
        expect(n.state.currentCount, 1);

        await n.flush();
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt(TasbeehNotifier.keyLifetime), 5001);
        expect(prefs.getInt(TasbeehNotifier.keyCycles), 3);
        n.dispose();
      },
    );

    test(
      'cycles completed before load are added to stored daily cycles',
      () async {
        SharedPreferences.setMockInitialValues({
          TasbeehNotifier.keyLifetime: 100,
          TasbeehNotifier.keyCycles: 2,
          TasbeehNotifier.keyCyclesDate: _key(DateTime.now()),
        });
        final n = TasbeehNotifier();
        n.setTarget(1);
        n.increment(); // completes a cycle pre-load
        await n.ready;
        expect(n.state.completedCycles, 3);
        expect(n.state.lifetimeCount, 101);
        n.dispose();
      },
    );

    test(
      'toggle changed before load is kept; others come from storage',
      () async {
        SharedPreferences.setMockInitialValues({
          TasbeehNotifier.keyHaptic: false,
          TasbeehNotifier.keySound: false,
        });
        final n = TasbeehNotifier();
        n.toggleSound(); // user turned sound on before load
        await n.ready;
        expect(n.state.soundEnabled, isTrue);
        expect(n.state.hapticEnabled, isFalse);
        n.dispose();
      },
    );

    test('resets made before load override stored values', () async {
      SharedPreferences.setMockInitialValues({
        TasbeehNotifier.keyLifetime: 900,
        TasbeehNotifier.keyCycles: 4,
        TasbeehNotifier.keyCyclesDate: _key(DateTime.now()),
      });
      final n = TasbeehNotifier();
      n.resetAll();
      n.resetLifetime();
      n.increment();
      await n.ready;
      expect(n.state.completedCycles, 0);
      expect(n.state.lifetimeCount, 1);
      n.dispose();
    });

    test('dispose before load completes persists merged value', () async {
      SharedPreferences.setMockInitialValues({TasbeehNotifier.keyLifetime: 42});
      final n = TasbeehNotifier();
      n.increment();
      n.dispose();
      await n.ready;
      await n.pendingWrites;
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(TasbeehNotifier.keyLifetime), 43);
    });
  });

  group('Tasbeeh debounced persistence', () {
    test('rapid taps are written once after the debounce window', () async {
      SharedPreferences.setMockInitialValues({});
      final n = TasbeehNotifier(
        saveDebounce: const Duration(milliseconds: 150),
      );
      await n.ready;
      final prefs = await SharedPreferences.getInstance();

      for (var i = 0; i < 5; i++) {
        n.increment();
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(prefs.getInt(TasbeehNotifier.keyLifetime), isNull);

      await Future<void>.delayed(const Duration(milliseconds: 250));
      await n.pendingWrites;
      expect(prefs.getInt(TasbeehNotifier.keyLifetime), 5);
      n.dispose();
    });

    test('flush() writes pending state immediately', () async {
      SharedPreferences.setMockInitialValues({});
      final n = TasbeehNotifier(saveDebounce: const Duration(seconds: 30));
      await n.ready;
      n.increment();
      n.increment();
      await n.flush();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(TasbeehNotifier.keyLifetime), 2);
      n.dispose();
    });

    test('dispose flushes pending state', () async {
      SharedPreferences.setMockInitialValues({});
      final n = TasbeehNotifier(saveDebounce: const Duration(seconds: 30));
      await n.ready;
      n.increment();
      n.increment();
      n.increment();
      n.dispose();
      await n.pendingWrites;
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(TasbeehNotifier.keyLifetime), 3);
    });
  });

  group('Tasbeeh daily cycles', () {
    test('daily cycles reset when the day changes mid-session', () async {
      SharedPreferences.setMockInitialValues({});
      var now = DateTime(2026, 11, 1, 23, 59);
      final n = TasbeehNotifier(
        clock: () => now,
        saveDebounce: const Duration(seconds: 30),
      );
      await n.ready;
      n.setTarget(2);
      n.increment();
      n.increment();
      expect(n.state.completedCycles, 1);

      now = DateTime(2026, 11, 2, 0, 1);
      n.increment();
      expect(n.state.completedCycles, 0);
      expect(n.state.currentCount, 1);
      expect(n.state.lifetimeCount, 3);

      await n.flush();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(TasbeehNotifier.keyCycles), 0);
      expect(prefs.getString(TasbeehNotifier.keyCyclesDate), '2026-11-2');
      n.dispose();
    });

    test('stored cycles from a previous day load as 0', () async {
      SharedPreferences.setMockInitialValues({
        TasbeehNotifier.keyLifetime: 70,
        TasbeehNotifier.keyCycles: 5,
        TasbeehNotifier.keyCyclesDate: '2026-10-31',
      });
      final n = TasbeehNotifier(clock: () => DateTime(2026, 11, 1, 8));
      await n.ready;
      expect(n.state.completedCycles, 0);
      expect(n.state.lifetimeCount, 70);
      n.dispose();
    });
  });

  group('Tasbeeh UI helpers', () {
    test('target options include a non-standard preset target (34)', () {
      final n = TasbeehNotifier();
      final akbar = DhikrItem.presets.firstWhere((d) => d.id == 'allahuakbar');
      n.selectDhikr(akbar);
      final options = tasbeehTargetOptions(n.state);
      expect(options, [33, 34, 99, 100, 0]);
      expect(options.contains(n.state.targetCount), isTrue);
      n.dispose();
    });

    test('standard target options when preset target is standard', () {
      final n = TasbeehNotifier();
      expect(tasbeehTargetOptions(n.state), [33, 99, 100, 0]);
      n.dispose();
    });

    test('counter semantic label uses Bengali digits', () {
      final n = TasbeehNotifier();
      for (var i = 0; i < 10; i++) {
        n.increment();
      }
      expect(
        tasbeehCounterSemanticLabel(n.state),
        startsWith('তাসবীহ গণনা, ১০/৩৩'),
      );
      n.dispose();
    });
  });
}
