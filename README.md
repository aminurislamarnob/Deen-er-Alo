# Deen-er-Alo (দ্বীনের আলো)

> A modern, elegant, and authentic Islamic Daily Companion app built with Flutter, Riverpod, and Clean Architecture.

---

## ✨ Key Features

- 🕋 **Accurate Prayer Times**: Astronomical calculation via `adhan` engine with global calculation methods (Karachi, MWL, ISNA, Umm al-Qura, etc.).
- 🇧🇩 **Bangladesh Islamic Foundation Schedule**: Built-in 365-day permanent district-wise schedule for all 64 districts of Bangladesh.
- ⏳ **Real-time Countdown & Arc Timer**: Live 1-second countdown to the next prayer with an intuitive circular arc indicator.
- 🚫 **Prohibited Prayer Times**: Real-time alerts for the 3 daily prohibited/makruh prayer times (Sunrise, Zawal/Midday, Sunset).
- 📍 **Offline Global Search**: Fast isolate-based search over 131,000+ cities across 250 countries, with GPS auto-detection.
- 📿 **Islamic Tools & Trackers**:
  - Daily 5-prayer check-in habit tracker
  - Saom / Fasting status and days counter
  - Daily authentic Hadith with citations
  - 130+ categorized Duas & Adhkar
- 🎨 **Modern Design System**:
  - Deep emerald green and golden amber visual branding
  - Crisp, modern Lucide Icons with dedicated 2px-stroke Islamic vector assets
  - Clean feature-first Clean Architecture

---

## 🛠️ Architecture & Tech Stack

- **Framework**: Flutter 3.44+ / Dart 3.12+
- **State Management**: `flutter_riverpod` (v2.6.1)
- **Routing**: `go_router` (v14.6+)
- **Calculations**: `adhan` (v2.0.0+1), `hijri` (v3.0.0)
- **Location**: `geolocator`, `flutter_compass`
- **Iconography**: `lucide_icons_flutter` + custom SVG vector set
- **Local Storage**: `shared_preferences`

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.44.0` or later
- Dart SDK `^3.12.0` or later

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/aminurislamarnob/Deen-er-Alo.git
   cd Deen-er-Alo
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run tests**:
   ```bash
   flutter test
   ```

4. **Launch the application**:
   ```bash
   flutter run
   ```

---

## 📄 License
This project is open-source and available under the MIT License.
