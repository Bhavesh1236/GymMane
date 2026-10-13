# 🏋️‍♂️ Gym AI (GymMane) — Comprehensive Project Overview

> **Version:** 1.3.0+4  
> **Type:** Mobile Application (Android / iOS / Wear OS)  
> **Framework:** Flutter (Dart SDK ^3.11.5)  
> **Design Philosophy:** Offline-First, Modern Sleek Dark & Glassmorphism  

---

## 📖 1. Project Summary

**Gym AI (GymMane)** is a high-performance, offline-first, intelligent workout and gym log application. Designed with zero cloud lock-in and no subscription walls, it empowers lifters and athletes with detailed session tracking, 1RM calculators, muscle distribution heatmaps, progression charts, custom routines, home screen widgets, and interactive AI coaching tools.

---

## 🎨 2. Design System & Aesthetics

The application uses a **Modern Sleek Dark Glassmorphic Design System**:

- **Color Palette**:
  - **Background Base**: Obsidian Dark (`#070A10` / `#0B1019`)
  - **Surface Elevations**: Deep Slate Raised Surfaces (`#121927` / `#192336`)
  - **Primary Accents**: Electric Neon Cyan (`#00E5FF`) & Mint Emerald (`#00F5B8`)
  - **Typography & High Contrast**: Slate White (`#F8FAFC`) with hierarchical secondary text (`#94A3B8`)
- **Visual Effects**:
  - **Glass Surfaces**: Frosted glass containers (`BackdropFilter.grouped` + custom fragment shaders `edge_fade.frag` and `medal.frag`).
  - **Liquid Nav Pill**: Floating interactive capsule dock with smooth inertia physics, active neon glow, and tactile haptics.
  - **Elevation & Specular Highlights**: Dual-layer top borders (`Colors.white.withValues(alpha: 0.12)`) and ambient glow shadows for actionable widgets.

---

## 📱 3. Core Modules & Screen Architecture

```
lib/
├── app/              # Application lifecycle, navigation shell, and root routing
├── catalog/          # Pre-packaged exercise library, animations, and muscle taxonomy
├── l10n/             # Multi-language localization and translation files
├── models/           # Data models (Exercise, Routine, Session, SetKind, Profile, etc.)
├── screens/          # Core feature screens (29 full screens & sheets)
├── services/         # Storage, database, audio, alarms, background bridges, and media
├── state/            # Central reactive state engine (`fit_state.dart`)
├── theme/            # Color extensions, palettes, and typography presets
├── wear/             # Dedicated Wear OS companion app UI and sync handlers
└── widgets/          # Reusable glassmorphic UI components, charts, and animations
```

### 🌟 Key Screens & Capabilities

| Screen / Feature | Description |
| :--- | :--- |
| **Home Dashboard** (`home_screen.dart`) | Daily focus/routine hero card, streak counter, weekly consistency tracker, weekly volume stats, and activity heatmap. |
| **Active Session** (`session_screen.dart`) | Real-time workout logger, rest timer with sound/voice alerts, plate math calculator, RPE/RIR tracking, and superset grouping. |
| **Exercise Library** (`exercises_screen.dart`) | 200+ illustrated exercises with muscle filters, video tutorials, form guides, and personal record tracking. |
| **Progress & Analytics** (`progress_screen.dart`) | 1RM estimation charts, weekly/monthly volume progression, muscle radar charts, and interactive body maps. |
| **Routines Hub** (`routines_screen.dart`) | Custom workout split builder, export/import via JSON or sharing links, and folder organization. |
| **Smart AI Coach** (`smart_ai_coach_screen.dart`) | Generates intelligent training splits, 1RM training zones, and barbell plate math. |
| **Veo Animate** (`veo_animate_screen.dart`) | Visual animation generation from images for exercise demonstration. |
| **Gym Tools** (`tools_screen.dart`) | Plate calculator, 1RM percentage charts, warm-up generator, and Wilks / DOTS score calculators. |
| **Journal & Notes** (`notes_screen.dart`) | Workout diary with photo attachments and progress photo comparisons. |
| **Wear OS Companion** (`wear_app.dart`) | Standalone watch interface for logging sets and checking rest timers right from the wrist. |

---

## ⚙️ 4. Technical Architecture

### 🗄️ State Management & Persistence
- **Single Source of Truth**: Centralized `FitState` (`fit_state.dart`) managing all routines, active workouts, historical sessions, and user preferences.
- **Offline Storage**: Ultra-fast local JSON and SQLite caching with automatic serialization, backup export (`.zip`), and FitNotes database compatibility.
- **Audio & Haptics**: Native sound effects and localized text-to-speech cues for rest intervals and countdowns (`audioplayers`).

### 📱 Android & Home Widgets
- **AppWidget Integration**: Powered by `home_widget` with 5 custom Android home screen widgets:
  - **Heatmap Widget**: Visual 7x12 activity grid on the desktop.
  - **Weekly Summary Widget**: Weekly session target progress and volume.
  - **Today's Plan Widget**: Dynamic card displaying today's scheduled workout.
  - **Body Status Widget**: Visual overview of recently trained muscle groups.
  - **Stats Widget**: Quick volume and personal record counters.

---

## 🛠️ 5. Development & Running

### Requirements
- **Flutter SDK**: `>= 3.11.5`
- **Dart SDK**: Compatible with Flutter 3.x
- **Android SDK**: `minSdkVersion 24`, `targetSdkVersion 36`, `compileSdkVersion 36`
- **Java / JDK**: Version 17

### Useful Commands

```bash
# 1. Install & resolve dependencies
flutter pub get

# 2. Run code analysis
flutter analyze

# 3. Execute test suite
flutter test

# 4. Launch on connected Android device
flutter run -d <DEVICE_ID> --no-enable-impeller

# 5. Build release APK
flutter build apk --release
```

---

## 🔒 6. Privacy & Data Ownership
- **Zero Telemetry / Trackers**: Gym AI operates completely offline without ads or external tracking.
- **Portable Backups**: Users can export full ZIP archives of their workout history and import backups from competitors like FitNotes and Strong.
