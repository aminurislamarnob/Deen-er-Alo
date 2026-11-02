import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/theme/app_fonts.dart';
import 'core/services/notification_service.dart';
import 'core/utils/city_clock.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bundled fonts' OFL licences on the licence page.
  AppFonts.registerLicenses();

  // Time zone database for city-local prayer times.
  CityClock.ensureInitialized();

  // Initialize notification channels and timezone data
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('NotificationService init error: $e');
  }

  // Set immersive status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: DeenerAloApp(),
    ),
  );
}
