# 🧭 Agent Handoff Guide — Deener Alo (দ্বীনের আলো)

> **Document Purpose**: Complete operational and architectural handoff for GitHub Copilot Agent (or incoming senior mobile engineers) to continue developing the **Deener Alo** Flutter application seamlessly.

---

## 1. 📱 Project Overview & Identity

* **App Name**: Deener Alo (`দ্বীনের আলো` — Light of Faith)
* **Application Purpose**: Modern, fast, authentic Islamic Daily Companion app tailored for Bangladesh and global Muslim users.
* **Repository**: [`https://github.com/aminurislamarnob/Deen-er-Alo.git`](https://github.com/aminurislamarnob/Deen-er-Alo.git)
* **Target Platforms**: Android (ARM64 / release APK / AAB) & iOS.
* **Package / Bundle ID**: `com.deeneralo.deener_alo`
* **Flutter Environment**: Flutter `^3.44.0` / Dart `^3.12.0` (Null-safety enabled).
* **Current Status**: **Phase 1 100% Completed, Verified Live on Android API 36, and Pushed to `main`**.

---

## 2. 🏛️ Architecture & Core Principles

The project follows a **Feature-First Clean Architecture** with **Riverpod**:

```
lib/
├── app/                        # App-level entry, routing & theme
│   ├── app.dart                # MaterialApp.router configuration
│   ├── router/                 # GoRouter with StatefulShellRoute bottom nav
│   │   ├── app_router.dart
│   │   └── scaffold_with_nav_bar.dart
│   └── theme/                  # Brand colors & typography
│       ├── app_colors.dart
│       └── app_theme.dart
├── core/                       # Shared utilities, services & registry
│   ├── constants/
│   │   └── app_icons.dart      # Unified registry for Lucide & SVG icons
│   ├── services/
│   │   └── location_service.dart # Geolocator wrapper + permissions
│   └── utils/
│       └── bangla_numbers.dart # English to Bengali digits & Hijri formatter
└── features/                   # Independent vertical slices
    ├── dua/                    # 130 Duas across 6 categories
    ├── home/                   # Dashboard, prayer tracker, Saom & daily Hadith
    ├── prayer_times/           # Adhan calculation + BD IFA schedule override
    ├── quran/                  # Surah index & recitation stub
    └── settings/               # App configuration, calculation methods, tools
```

### Key Technical Patterns
1. **Separation of Concerns**: Each feature directory contains `data/` (repositories, data sources), `domain/` (immutable models), and `presentation/` (Riverpod providers & widgets).
2. **Offline-First**: All astronomical prayer calculations, 131K world cities, 365-day Bangladesh Islamic Foundation timetables, Duas, and Hadiths are **100% offline** and bundled in `assets/data/`.
3. **Thread Safety**: Heavy JSON processing (such as searching 131,000 cities) MUST run inside background isolates via Flutter's `compute()` to maintain 60–120 FPS UI smoothness.
4. **Zero-Warning Bar**: Keep `flutter analyze` at **0 issues** and all unit/widget tests passing (`flutter test`).

---

## 3. 🎨 Design System & Visual Guidelines

* **Color Palette** (defined in `lib/app/theme/app_colors.dart`):
  * **Primary Deep Emerald**: `#072B1E` / `#0D3D2A` (Background headers, active pills)
  * **Golden Amber Accent**: `#F7B52C` / `#D97706` (Countdown progress, timeline dots, badges)
  * **Card Surface**: `#FFFFFF` with hairline border `#E2E8F0` (`0.8px`) and soft `6px` shadow.
  * **Light Canvas Background**: `#F8FAFC`.
* **Typography**:
  * English / Numbers: `GoogleFonts.plusJakartaSans` (clean modern geometric sans).
  * Bengali / Arabic: System fallback (`Noto Sans Bengali`, `SF Pro`).
* **Iconography**:
  * Core UI: **`lucide_icons_flutter: ^4.0.1`** (Consistent 2px-stroke geometric vector style).
  * Islamic Symbols: Centralized in `lib/core/constants/app_icons.dart` using dedicated 2px-line SVGs in `assets/icons/`:
    * `AppIcons.kaabaSvg` (`assets/icons/kaaba.svg`)
    * `AppIcons.tasbeehSvg` (`assets/icons/tasbeeh.svg`)
    * `AppIcons.handsPrayingSvg` (`assets/icons/hands_praying.svg`)
    * `AppIcons.mosqueSvg` (`assets/icons/mosque.svg`)
  * Always use `AppIcons.svg(...)` or `LucideIcons.<name>` rather than stock Material icons.
* **UI Spacing Standard**:
  * Standard section-to-section gap: `22px`.
  * Standard section title-to-content gap: `10px`.
  * Always pass `padding: EdgeInsets.zero` to any nested `GridView` or `ListView` inside scrollable screens to prevent rogue status-bar padding injection.

---

## 4. 📦 Bundled Datasets Reference

All bundled offline datasets reside in `assets/data/`:
* `ifa_times.json` (825 KB): Official Bangladesh Islamic Foundation 365-day permanent schedule for all 64 districts.
* `countries+cities.json` (10.7 MB): 131,508 global cities across 250 countries with coordinates and timezone offsets.
* `calculation_method_for_countries.json` (20 KB): Default Islamic calculation convention per country.
* `dua.json` (291 KB): 130 authentic Duas organized into 6 life categories with Arabic, transliteration, and Bengali translation.
* `names_data.json` (3.5 KB): 99 Names of Allah with meanings and Quranic references.
* `selected_hadith.json` (39 KB): Authenticated Hadiths for daily rotating reminders.

---

## 5. 🚀 Completed Features (Phase 1)

- [x] **Adhan Mathematical Engine**: Dynamic calculation using `adhan: ^2.0.0+1` for any coordinate worldwide.
- [x] **Bangladesh Islamic Foundation Engine**: Automatic 365-day schedule override whenever a user selects one of Bangladesh's 64 districts.
- [x] **Live 1-Second Countdown**: Real-time timer indicating exact time remaining until the next prayer.
- [x] **Arc Countdown Timer**: Circular progress widget on Prayer Times screen.
- [x] **Prohibited Prayer Times**: Automatic detection and bottom sheet for Sunrise, Zawal (Midday), and Sunset makruh prayer windows.
- [x] **City & District Picker**: Searchable modal bottom sheet with GPS auto-detection and isolate-based search.
- [x] **Daily 5-Prayer Tracker**: Check-in habit tracker with local SharedPreferences persistence.
- [x] **Saom / Fasting Tracker**: Daily fasting toggle and cumulative fasting day counter.
- [x] **Daily Rotating Hadith**: Dashboard card displaying daily authentic Hadiths.
- [x] **Audio Alarm Toggles**: Local state toggle for Azan alerts per prayer.

---

## 6. 🎯 Next Tasks (Phase 2 Roadmap for Copilot)

According to [`flutter-implementation-plan.md`](file:///Users/aiarnob/Herd/others/muslim-day/flutter-implementation-plan.md), the next priority is **Phase 2: Core Islamic Tools & Sensors**:

### Task 2.1: Qibla Compass Screen (`lib/features/qibla/`)
* **Package**: `flutter_compass: ^0.8.0` (already installed in `pubspec.yaml`).
* **Route**: `/qibla` (update routes in `app_router.dart` and link from Home tools grid).
* **Requirements**:
  1. Calculate Qibla bearing from current coordinates to the Kaaba (`21.4225° N, 39.8262° E`) using great-circle bearing formula.
  2. Smooth hardware compass stream with low-pass filter (avoid jitter).
  3. Interactive rotating compass dial with `AppIcons.svg(AppIcons.kaabaSvg)` at the exact target angle.
  4. Haptic vibration feedback (`HapticFeedback.mediumImpact`) when the device points directly within ±2° of the Qibla.
  5. Fallback warning UI if the device lacks a magnetometer sensor.

### Task 2.2: Digital Tasbeeh Counter (`lib/features/tasbeeh/`)
* **Route**: `/tasbeeh` (link from Home tools grid and More screen).
* **Requirements**:
  1. Full-screen tactile tap counter with customizable Dhikr selection (Subhanallah, Alhamdulillah, Allahu Akbar, Astaghfirullah, etc.).
  2. Lap / Target goals (33, 99, 100, or unlimited).
  3. Haptic feedback on each count (`HapticFeedback.lightImpact`) and stronger vibration on completing a target set (`HapticFeedback.vibrate`).
  4. Reset button with confirmation dialog.
  5. Persistence of cumulative daily counts in `SharedPreferences`.

### Task 2.3: 99 Names of Allah Screen (`lib/features/names/`)
* **Route**: `/names` (link from Home tools grid and Settings).
* **Requirements**:
  1. Grid/List view using `assets/data/names_data.json`.
  2. Beautiful calligraphy presentation, Bengali transliteration, Bengali meaning, and Quranic citations.
  3. Detail bottom sheet or dialog on tapping any name.

### Task 2.4: Enhanced Dua Drill-down & Bookmarking (`lib/features/dua/`)
* **Requirements**:
  1. Search filter inside `DuaScreen` to search across title, Arabic text, and Bengali meaning.
  2. Bookmark / Favorite button on each Dua card persisted to `SharedPreferences`.
  3. One-tap copy to clipboard with `Clipboard.setData` and snackbar confirmation.

---

## 7. ⚠️ Critical Guardrails & Development Gotchas

1. **Strictly No Competitor References**:
   * Do **NOT** mention competitor apps (*Muslims Day*, *The Oak Troop*, etc.) in code, comments, commit messages, or assets.
   * If adding third-party APIs or assets, ensure they are 100% open-source, permissive, or self-hosted.
2. **Isolates for Large Data**:
   * Never parse `countries+cities.json` on the main UI thread. Always use `compute()`.
3. **Timezone & Date Math**:
   * All prayer times calculations must use the device's selected city latitude, longitude, and local timezone offset.
4. **Verification Commands**:
   * Before committing, always run:
     ```bash
     flutter analyze
     flutter test
     ```
   * Both must pass with zero errors.

---

## 8. 🛠️ Handy Commands

| Action | Command |
| :--- | :--- |
| **Run Tests** | `flutter test` |
| **Analyze Code** | `flutter analyze` |
| **Install Packages** | `flutter pub get` |
| **Run on Emulator** | `flutter run -d emulator-5554 --target-platform android-arm64 --debug` |
| **Build Debug APK** | `flutter build apk --debug --target-platform android-arm64` |
| **Check Git Status** | `git status` |
