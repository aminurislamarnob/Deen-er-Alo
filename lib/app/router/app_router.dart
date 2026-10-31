import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dua/presentation/dua_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/ramadan_checklist_screen.dart';
import '../../features/prayer_times/presentation/prayer_times_screen.dart';
import '../../features/quran/presentation/quran_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'scaffold_with_nav_bar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

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
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/prayers',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: PrayerTimesScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/quran',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: QuranScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dua',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DuaScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/checklist',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RamadanChecklistScreen(),
    ),
  ],
);
