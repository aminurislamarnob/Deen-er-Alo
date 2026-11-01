import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'system_sync.dart';
import 'theme/app_theme.dart';

class DeenerAloApp extends ConsumerStatefulWidget {
  const DeenerAloApp({super.key});

  @override
  ConsumerState<DeenerAloApp> createState() => _DeenerAloAppState();
}

class _DeenerAloAppState extends ConsumerState<DeenerAloApp> {
  @override
  void initState() {
    super.initState();
    // Alarms + widgets: schedule on start, resume, midnight and state changes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(systemSyncProvider).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Deener Alo (দ্বীনের আলো)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Default light theme with emerald accents
      routerConfig: appRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('bn', 'BD'),
      ],
    );
  }
}

