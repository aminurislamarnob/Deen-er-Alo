import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  // Channel IDs
  static const String channelPrayerAdhan = 'deener_alo_prayer_adhan';
  static const String channelPrayerChime = 'deener_alo_prayer_chime';
  static const String channelPrayerSilent = 'deener_alo_prayer_silent';
  static const String channelFasting = 'deener_alo_fasting';
  static const String channelAdhkar = 'deener_alo_adhkar';
  static const String channelEvents = 'deener_alo_events';

  Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Error initializing timezones: $e');
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification clicked with payload: ${response.payload}');
      },
    );

    await _createNotificationChannels();
    _initialized = true;
  }

  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    final channels = <AndroidNotificationChannel>[
      const AndroidNotificationChannel(
        channelPrayerAdhan,
        'নামাজের ওয়াক্ত ও আযান',
        description: 'ওয়াক্ত হলে আযান বা নোটিফিকেশন প্রদান করে',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        channelPrayerChime,
        'ওয়াক্ত রিমাইন্ডার (নরম সাউন্ড)',
        description: 'ওয়াক্ত শুরু বা শেষ হওয়ার পূর্বে নরম শব্দে অবহিত করে',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        channelPrayerSilent,
        'নীরব নোটিফিকেশন',
        description: 'সাউন্ড বা ভাইব্রেশন ব্যতীত শুধু স্ক্রিনে নোটিফিকেশন',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
      const AndroidNotificationChannel(
        channelFasting,
        'সাহরি ও ইফতার সতর্কবার্তা',
        description: 'সাহরির শেষ সময় এবং ইফতারের সতর্কবার্তা',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        channelAdhkar,
        'দৈনিক জিকির ও তাসবীহ',
        description: 'সকাল ও সন্ধ্যার জিকির, দরূদ ও ইস্তিগফারের স্মরণিকা',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        channelEvents,
        'ইসলামিক দিবস ও ক্যালেন্ডার',
        description: 'আইয়ামে বিজ ও গুরুত্বপূর্ণ ইসলামিক দিবসের পূর্ব সতর্কতা',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    ];

    for (final channel in channels) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  Future<bool> requestPermissions() async {
    bool granted = false;

    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final notifGranted =
            await androidPlugin.requestNotificationsPermission();
        final alarmGranted =
            await androidPlugin.requestExactAlarmsPermission();
        granted = (notifGranted ?? false) && (alarmGranted ?? true);
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final res = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = res ?? false;
      }
    }

    return granted;
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String channelId = channelPrayerAdhan,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      'ওয়াক্ত সতর্কতা',
      channelDescription: 'ওয়াক্ত সতর্কতা নোটিফিকেশন',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String channelId = channelPrayerAdhan,
    String? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'ওয়াক্ত সতর্কতা',
      channelDescription: 'ওয়াক্ত সতর্কতা নোটিফিকেশন',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final tzTime = tz.TZDateTime.from(scheduledDate, tz.local);
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to schedule exact alarm for $scheduledDate: $e');
    }
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
