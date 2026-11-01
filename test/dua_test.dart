import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deener_alo/features/dua/presentation/dua_bookmark_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dua Bookmarks Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial bookmarks set is empty', () {
      final notifier = DuaBookmarkNotifier();
      expect(notifier.state.isEmpty, isTrue);
    });

    test('Toggling bookmarks adds and removes dua IDs', () {
      final notifier = DuaBookmarkNotifier();

      // Add dua 42
      notifier.toggleBookmark(42);
      expect(notifier.isBookmarked(42), isTrue);
      expect(notifier.state.contains(42), isTrue);

      // Add dua 88
      notifier.toggleBookmark(88);
      expect(notifier.isBookmarked(88), isTrue);
      expect(notifier.state.length, equals(2));

      // Remove dua 42
      notifier.toggleBookmark(42);
      expect(notifier.isBookmarked(42), isFalse);
      expect(notifier.state.contains(42), isFalse);
      expect(notifier.state.length, equals(1));
    });
  });
}
