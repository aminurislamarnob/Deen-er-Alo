# 🧭 Agent Handoff Guide — Deener Alo (দ্বীনের আলো)

> **Document Purpose**: Complete operational and architectural handoff for incoming AI agents and mobile engineers to continue developing the **Deener Alo** Flutter application seamlessly.

---

## 1. 📱 Project Overview & Identity

- **App Name**: Deener Alo (`দ্বীনের আলো` — Light of Faith)
- **Application Purpose**: Modern, fast, authentic Islamic Daily Companion app tailored for Bangladesh and global Muslim users.
- **Repository**: [`https://github.com/aminurislamarnob/Deen-er-Alo.git`](https://github.com/aminurislamarnob/Deen-er-Alo.git)
- **Active Git Branch**: `main` (Clean working tree, synced with origin)
- **Workspace Path**: `/Users/aiarnob/Herd/others/Deen-er-Alo` *(Renamed from `muslim-day` to match repository name)*
- **Target Platforms**: Android (ARM64 / release APK / AAB) & iOS.
- **Package / Bundle ID**: `com.deeneralo.deener_alo`
- **Flutter Environment**: Flutter `^3.44.0` / Dart `^3.12.0` (Null-safety enabled).
- **Current Quality Status**:
  - `flutter analyze`: **0 issues found**
  - `flutter test`: **27/27 unit tests passed**
  - Live verified on Android emulator (`emulator-5554`, Pixel 10 API 37)

---

## 2. 🏛️ Architecture & Core Principles

The project follows a **Feature-First Clean Architecture** with **Riverpod**:

```
lib/
├── app/                        # App-level entry, routing & theme
│   ├── app.dart                # MaterialApp.router configuration
│   ├── router/                 # GoRouter with StatefulShellRoute bottom nav & modal routes
│   │   ├── app_router.dart     # Routes: /home, /prayers, /dua, /settings, /qibla, /tasbeeh, /names, /checklist
│   │   └── scaffold_with_nav_bar.dart
│   └── theme/                  # Brand colors & typography
│       ├── app_colors.dart
│       └── app_theme.dart
├── core/                       # Shared utilities, widgets & registry
│   ├── constants/
│   │   └── app_icons.dart      # Unified registry for Lucide & SVG icons
│   ├── services/
│   │   └── location_service.dart # Geolocator wrapper + permissions
│   ├── utils/
│   │   └── bangla_numbers.dart # English to Bengali digits & Hijri formatter
│   └── widgets/
│       └── app_back_button.dart# Unified circular back button (Prayer screen style)
└── features/                   # Independent vertical slices
    ├── dua/                    # 130 Duas across 6 categories + Bookmarks + Search + Copy
    ├── home/                   # Dashboard, prayer tracker, Saom & daily Hadith
    ├── names/                  # 99 Names of Allah (Asmaul Husna) + Search + Detail Bottom Sheet
    ├── prayer_times/           # Adhan calculation + BD IFA schedule override
    ├── qibla/                  # Real-time Qibla Compass + Adhan Great-Circle Bearing + Fallback
    ├── quran/                  # Surah index & recitation stub (Temporarily unrouted)
    ├── settings/               # App configuration, calculation methods, tools navigation
    └── tasbeeh/                # Digital Tasbeeh with tactile radial counter + cycle tracking
```

---

## 3. 🎯 Recent Changes & Updates

1. **Workspace Folder Name**:
   - Directory renamed to match repository name: `/Users/aiarnob/Herd/others/Deen-er-Alo`.
2. **Quran Module Temporary Deactivation**:
   - Removed `/quran` from the active bottom navigation bar (`app_router.dart`, `scaffold_with_nav_bar.dart`).
   - Bottom navigation now has **4 active tabs**: `Home` (0), `Prayers` (1), `Dua` (2), `More` (3).
   - Home screen `আল-কুরআন` tile has a "শীঘ্রই আসছে" badge and triggers a floating SnackBar.
   - All files under `lib/features/quran/` remain intact for future Phase 3 activation.
3. **Unified Circular Back Button**:
   - Replaced raw back arrows with `AppBackButton` (`lib/core/widgets/app_back_button.dart`) across all screens (`Prayer Times`, `Tasbeeh`, `Qibla`, `99 Names`, `Dua`, `Settings`).

---

## 4. 📋 Next Phase: Phase 2 Islamic Content Roadmap

Reference implementation plan: [`flutter-implementation-plan.md`](file:///Users/aiarnob/Herd/others/Deen-er-Alo/flutter-implementation-plan.md) and approved artifact `phase_2_islamic_content_plan.md`.

- **Step 2.1**: Dua Details & Category Filter extensions (search, favorite persistence, audio hook).
- **Step 2.2**: Hadith of the Day expanded viewer (authentic Bukhari / Muslim / Nawawi references).
- **Step 2.3**: Ramadan Calendar & Fasting tracker enhancements.

---

## 5. 🚀 Phase 4: System Integration (Completed)

1. **Exact Prayer Alarms & Notifications (`lib/core/services/notification_service.dart`, `prayer_alarm_scheduler.dart`)**:
   - 48-hour rolling exact alarm scheduler for Fajr, Dhuhr, Asr, Maghrib, Isha, Sunrise, Tahajjud, and Duha.
   - Advance reminders for Sehri end warning (15 min) & Iftar preparation (10 min).
   - Daily Adhkar reminder channels (Morning & Evening Adhkar).
   - Granular UI in [`NotificationSettingsScreen`](file:///Users/aiarnob/Herd/others/Deen-er-Alo/lib/features/settings/presentation/notification_settings_screen.dart) with modal tone pickers (Adhan, Chime, Silent, Off) and battery optimization help guide.
   - Core library desugaring enabled in `build.gradle.kts`.

2. **Android Home Screen Widgets (`lib/core/services/widget_sync_service.dart`)**:
   - Three native AppWidget layouts:
     - `SaomTimerWidgetProvider`: Dedicated fasting widget (Sehri & Iftar live countdown).
     - `DaySummaryWidgetProvider`: Today's Islamic date, current Waqt, and next prayer countdown.
     - `PrayerListWidgetProvider`: Full 5-prayer timetable with highlighted active Waqt.
   - Background Flutter-to-native sync bridge via `home_widget`.

3. **Daily Habit & Prayer Tracker (`lib/features/tracker/`)**:
   - 5 daily prayer logging with 4 statuses: `জামাতে`, `একাকী`, `কাজা`, `আদায় হয়নি`.
   - Fasting tracker (রমজানের ফরজ, নফল রোজা, কাজা).
   - Sunnah checklist: কুরআন তিলাওয়াত, সকাল-সন্ধ্যার জিকির, তাহাজ্জুদ ও দুহা, সাদাকাহ.
   - Multi-day history, streak engine (`🔥 ধারাবাহিক আমল`), and Qaza prayer calculator balance.

4. **Islamic Hijri Calendar & Key Dates (`lib/features/calendar/`)**:
   - Monthly dual Gregorian-Hijri calendar grid with Friday (Jummah) and Ayyam al-Beed (13, 14, 15 Hijri white fasts) badges.
   - Moon-sighting adjustment sheet (±2 days offset).
   - Interactive day inspector: tap any date to instantly compute its exact prayer timetable and view Islamic historical milestones.

---

## 6. 🛠️ Quality & Verification Checklist

Before pushing or creating pull requests:
- Run `flutter analyze` — ensure **0 warnings, 0 errors**.
- Run `flutter test` — ensure **all unit tests pass**.
- Verify responsive layout on Android emulator without `RenderFlex` overflows.
