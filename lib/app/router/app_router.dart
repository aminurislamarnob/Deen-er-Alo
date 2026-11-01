import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dua/presentation/dua_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/ramadan_checklist_screen.dart';
import '../../features/names/presentation/names_screen.dart';
import '../../features/prayer_times/presentation/prayer_times_screen.dart';
import '../../features/qibla/presentation/qibla_screen.dart';
import '../../features/quran/presentation/quran_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/tasbeeh/presentation/tasbeeh_screen.dart';
import 'scaffold_with_nav_bar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

CustomTransitionPage<void> _buildSlidePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);

      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: offsetAnimation, child: child),
      );
    },
  );
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/prayers',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: PrayerTimesScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/quran',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: QuranScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dua',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: DuaScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SettingsScreen()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/checklist',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildSlidePage(
        key: state.pageKey,
        child: const RamadanChecklistScreen(),
      ),
    ),
    GoRoute(
      path: '/qibla',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildSlidePage(
        key: state.pageKey,
        child: const QiblaScreen(),
      ),
    ),
    GoRoute(
      path: '/tasbeeh',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildSlidePage(
        key: state.pageKey,
        child: const TasbeehScreen(),
      ),
    ),
    GoRoute(
      path: '/names',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildSlidePage(
        key: state.pageKey,
        child: const NamesScreen(),
      ),
    ),
  ],
);
