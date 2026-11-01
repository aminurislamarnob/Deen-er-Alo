# 🧭 Agent Handoff Guide — Deener Alo (দ্বীনের আলো)

> **Document Purpose**: Complete operational and architectural handoff for GitHub Copilot Agent (or incoming senior mobile engineers) to continue developing the **Deener Alo** Flutter application seamlessly.

---

## 1. 📱 Project Overview & Identity

- **App Name**: Deener Alo (`দ্বীনের আলো` — Light of Faith)
- **Application Purpose**: Modern, fast, authentic Islamic Daily Companion app tailored for Bangladesh and global Muslim users.
- **Repository**: [`https://github.com/aminurislamarnob/Deen-er-Alo.git`](https://github.com/aminurislamarnob/Deen-er-Alo.git)
- **Target Platforms**: Android (ARM64 / release APK / AAB) & iOS.
- **Package / Bundle ID**: `com.deeneralo.deener_alo`
- **Flutter Environment**: Flutter `^3.44.0` / Dart `^3.12.0` (Null-safety enabled).
- **Current Status**: **Phase 1 & Phase 2 100% Completed, Verified Live on Android API 36, and Pushed to `main`**.

---

## 2. 🏛️ Architecture & Core Principles

The project follows a **Feature-First Clean Architecture** with **Riverpod**:

```
lib/
├── app/                        # App-level entry, routing & theme
│   ├── app.dart                # MaterialApp.router configuration
│   ├── router/                 # GoRouter with StatefulShellRoute bottom nav & modal routes
│   │   ├── app_router.dart     # Routes: /home, /prayers, /quran, /dua, /settings, /qibla, /tasbeeh, /names, /checklist
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
    ├── dua/                    # 130 Duas across 6 categories + Bookmarks + Search + Copy
    ├── home/                   # Dashboard, prayer tracker, Saom & daily Hadith
    ├── names/                  # 99 Names of Allah (Asmaul Husna) + Search + Detail Bottom Sheet
    ├── prayer_times/           # Adhan calculation + BD IFA schedule override
    ├── qibla/                  # Real-time Qibla Compass + Adhan Great-Circle Bearing + Fallback
    ├── quran/                  # Surah index & recitation stub
    ├── settings/               # App configuration, calculation methods, tools navigation
    └── tasbeeh/                # Digital Tasbeeh with tactile radial counter + cycle tracking
```

### Key Technical Patterns

1. **Separation of Concerns**: Each feature directory contains `data/` (repositories, data sources), `domain/` (immutable models), and `presentation/` (Riverpod providers & widgets).
2. **Offline-First**: All astronomical prayer calculations, 131K world cities, 365-day Bangladesh Islamic Foundation timetables, 99 Names of Allah, Duas, and Hadiths are **100% offline** and bundled in `assets/data/`.
3. **Thread Safety**: Heavy JSON processing (such as searching 131,000 cities) MUST run inside background isolates via Flutter's `compute()` to maintain 60–120 FPS UI smoothness.
4. **Zero-Warning Bar**: Keep `flutter analyze` at **0 issues** and all unit/widget tests passing (`flutter test`).

---

## 3. 🎨 Design System & Visual Guidelines

- **Color Palette** (defined in `lib/app/theme/app_colors.dart`):
  - **Primary Deep Emerald**: `#072B1E` / `#0D3D2A` (Background headers, active pills)
  - **Golden Amber Accent**: `#F7B52C` / `#D97706` (Countdown progress, timeline dots, badges, ring accents)
  - **Card Surface**: `#FFFFFF` with hairline border `#E2E8F0` (`0.8px`) and soft `6px` shadow.
  - **Light Canvas Background**: `#F8FAFC`.
- **Typography**:
  - English / Numbers: `GoogleFonts.plusJakartaSans` (clean modern geometric sans).
  - Bengali / Arabic: System fallback (`Noto Sans Bengali`, `SF Pro`, `Amiri`).
- **Iconography**:
  - Core UI: **`lucide_icons_flutter: ^4.0.1`** (Consistent 2px-stroke geometric vector style).
  - Islamic Symbols: Centralized in `lib/core/constants/app_icons.dart` using dedicated 2px-line SVGs in `assets/icons/`:
    - `AppIcons.kaabaSvg` (`assets/icons/kaaba.svg`)
    - `AppIcons.tasbeehSvg` (`assets/icons/tasbeeh.svg`)
    - `AppIcons.handsPrayingSvg` (`assets/icons/hands_praying.svg`)
    - `AppIcons.mosqueSvg` (`assets/icons/mosque.svg`)
  - Always use `AppIcons.svg(...)` or `LucideIcons.<name>` rather than stock Material icons.
- **UI Spacing Standard**:
  - Standard section-to-section gap: `22px`.
  - Standard section title-to-content gap: `10px`.
  - Always pass `padding: EdgeInsets.zero` to any nested `GridView` or `ListView` inside scrollable screens to prevent rogue status-bar padding injection.

---

## 4. 📦 Bundled Datasets Reference

All bundled offline datasets reside in `assets/data/`:

- `ifa_times.json` (825 KB): Official Bangladesh Islamic Foundation 365-day permanent schedule for all 64 districts.
- `countries+cities.json` (10.7 MB): 131,508 global cities across 250 countries with coordinates and timezone offsets.
- `calculation_method_for_countries.json` (20 KB): Default Islamic calculation convention per country.
- `dua.json` (291 KB): 130 authentic Duas organized into 6 life categories with Arabic, transliteration, and Bengali translation.
- `names_data.json` (58 KB): Complete authentic 99 Names of Allah (Asmaul Husna) with Arabic script, transliteration, Bengali pronunciation, meanings, and theological descriptions.
- `selected_hadith.json` (39 KB): Authenticated Hadiths for daily rotating reminders.

---

## 5. 🚀 Completed Features (Phase 1 & Phase 2)

### Phase 1: Core Daily Foundations
- [x] **Adhan Mathematical Engine**: Dynamic calculation using `adhan: ^2.0.0+1` for any coordinate worldwide.
- [x] **Bangladesh Islamic Foundation Engine**: Automatic 365-day schedule override whenever a user selects one of Bangladesh's 64 districts.
- [x] **Live 1-Second Countdown**: Real-time timer indicating exact time remaining until the next prayer.
- [x] **Arc Countdown Timer**: Circular progress widget on Prayer Times screen.
- [x] **Prohibited Prayer Times**: Automatic detection and bottom sheet for Sunrise, Zawal (Midday), and Sunset makruh prayer windows.
- [x] **City & District Picker**: Searchable modal bottom sheet with GPS auto-detection and isolate-based search across 131K cities.
- [x] **Daily 5-Prayer Tracker**: Check-in habit tracker with local SharedPreferences persistence.
- [x] **Saom / Fasting Tracker**: Daily fasting toggle and cumulative fasting day counter.
- [x] **Daily Rotating Hadith**: Dashboard card displaying daily authentic Hadiths.
- [x] **Audio Alarm Toggles**: Local state toggle for Azan alerts per prayer.

### Phase 2: Islamic Content & Companion Tools
- [x] **Qibla Compass with Sensors (`lib/features/qibla/`)**:
  - Real-time Great-Circle Kaaba bearing calculation via `adhan` (`277.6°` from Dhaka).
  - Hardware magnetometer streaming via `flutter_compass` with 0°/360° seam low-pass smoothing filter.
  - Custom rotating compass dial with cardinal markers (`N, E, S, W`), Kaaba pointer beam, and center Kaaba medallion (`AppIcons.kaabaSvg`).
  - Strict alignment tolerance ($\pm 2.0^\circ$) with tactile alignment lock (`mediumImpact`).
  - Comprehensive calibration instructions and manual bearing angle fallback for devices lacking magnetometers.
- [x] **Digital Tasbeeh Counter (`lib/features/tasbeeh/`)**:
  - Horizontal preset Dhikr selector (Subhanallah, Alhamdulillah, Allahu Akbar, La ilaha illallah, Astaghfirullah, Salawat, Hawqala, Custom).
  - Tactile radial tap button with animated spring scale transition and circular progress ring.
  - Cycle targets (33, 99, 100, $\infty$) with auto cycle rollover and haptic celebration feedback (`heavyImpact`).
  - Audio click sound support (`SystemSoundType.click`) with AppBar toggle button.
  - Daily cycle auto-reset tracking based on calendar date.
  - Cumulative lifetime count persisted in `SharedPreferences` with sequential save queue protection.
  - Reset confirmation dialog and haptic toggles.
- [x] **99 Names of Allah (`lib/features/names/`)**:
  - Complete 99 Names of Allah database in `assets/data/names_data.json` with Arabic calligraphy, Bengali pronunciation, English transliteration, Bengali & English meanings, virtues, and Quran & Hadith citations.
  - 2-column responsive grid with golden amber badges.
  - Real-time search across Arabic, English, and Bengali names or meanings.
  - Modal bottom sheet (`NameDetailSheet`) showing full calligraphy, virtues, Quran/Hadith references card, and one-tap copy button.
- [x] **Enhanced Dua & Adhkar (`lib/features/dua/`)**:
  - HTML cleanup parser stripping tags and decoding entities for all 130 Duas.
  - Real-time search across all 130 Duas in all categories.
  - Bookmarking system (`DuaBookmarkNotifier`) with sequential save queue and persistent `SharedPreferences` storage.
  - Dedicated "সংরক্ষিত (Saved)" category tab.
  - One-tap copy to clipboard with floating SnackBar notification and native system sharing via `share_plus`.
- [x] **Navigation & Integration**:
  - Added `/qibla`, `/tasbeeh`, `/names` routes in `app_router.dart` with custom slide transitions.
  - Robust back navigation fallback (`context.canPop() ? context.pop() : context.go('/home')`) across all feature app bars.
  - Linked all tools from Home dashboard tools grid and Settings & More screen.

---

## 6. 🎯 Next Roadmap (Phase 3: Al-Quran & Audio Engine)

According to [`flutter-implementation-plan.md`](file:///Users/aiarnob/Herd/others/muslim-day/flutter-implementation-plan.md), the next priority is **Phase 3: Al-Quran & Audio Engine**:

### Task 3.1: Surah Index & Reader (`lib/features/quran/`)
- Display all 114 Surahs with Arabic script, Bengali meaning, Ayah count, and Revelation place (Makkah/Madinah).
- Offline Ayah reader with Bengali translation and transliteration.
- Last read bookmarking.

### Task 3.2: Audio Recitation & Adhan Alerts
- Background audio player for Quranic recitation.
- Audio player for Adhan alarms when prayer times trigger.

---

## 7. ⚠️ Critical Guardrails & Development Gotchas

1. **Strictly No Competitor References**:
   - Do **NOT** mention competitor apps in code, comments, commit messages, or assets.
   - If adding third-party APIs or assets, ensure they are 100% open-source, permissive, or self-hosted.
2. **Isolates for Large Data**:
   - Never parse `countries+cities.json` on the main UI thread. Always use `compute()`.
3. **Timezone & Date Math**:
   - All prayer times calculations must use the device's selected city latitude, longitude, and local timezone offset.
4. **Verification Commands**:
   - Before committing, always run:
     ```bash
     flutter analyze
     flutter test
     ```
   - Both must pass with zero errors.

---

## 8. 🛠️ Handy Commands

| Action               | Command                                                                |
| :------------------- | :--------------------------------------------------------------------- |
| **Run Tests**        | `flutter test`                                                         |
| **Analyze Code**     | `flutter analyze`                                                      |
| **Install Packages** | `flutter pub get`                                                      |
| **Run on Emulator**  | `flutter run -d emulator-5554 --target-platform android-arm64 --debug` |
| **Build Debug APK**  | `flutter build apk --debug --target-platform android-arm64`            |
| **Check Git Status** | `git status`                                                           |
