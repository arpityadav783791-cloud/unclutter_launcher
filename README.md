# Minimal Launcher

A production-oriented minimalist Android launcher built with Flutter.

**Philosophy:** *Your phone should help you do things, not encourage you to keep looking at it.*

Text-first · Distraction-free · Intentional

---

## Features

| Area | Capabilities |
|------|----------------|
| **Home** | Text-only app list, clock, date, favorites |
| **Search** | Instant, swipe-up |
| **Apps** | Rename, hide, favorites + reorder |
| **Mindful Delay** | Forced countdown before opening selected apps |
| **Daily Limits** | Per-app usage caps + short extensions |
| **Focus Mode** | Block selected apps for a duration |
| **Scheduled Blocks** | Time-window blocking (incl. overnight) |
| **Screen Time** | UsageStats-based dashboard |
| **Settings** | Theme, clock/date toggle, text size |

---

## Requirements

- Flutter 3.22+ (stable)
- Android SDK 24+
- Physical device or emulator for launcher testing

---

## Setup

```bash
cd minimal_launcher
flutter pub get
```

### Set as default launcher

After install:

1. Press the **Home** button, or  
2. **Settings → Apps → Default apps → Home app** → choose **Minimal Launcher**

Grant **Usage access** when prompted (needed for Screen Time / Daily Limits).

---

## Development

```bash
flutter run
flutter analyze
flutter test
```

---

## Production build (Phase 18)

### 1. Create a keystore (once)

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

### 2. Configure signing

```bash
cp android/key.properties.example android/key.properties
# Edit android/key.properties with your passwords and path
```

Place `upload-keystore.jks` where `storeFile` points (e.g. `android/upload-keystore.jks`).

### 3. Release APK

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

### 4. Release App Bundle (Play Store)

```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

### 5. Install release APK on device

```bash
flutter install --release
# or
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Release notes

- `minifyEnabled` + `shrinkResources` enabled for release
- ProGuard rules included for Flutter + MethodChannel
- `applicationId`: `com.minimal.launcher`
- `minSdk`: 24
- Version: `1.0.0+1` (update in `pubspec.yaml`)

---

## Architecture

```
lib/
  core/          theme, routes, storage, widgets
  features/
    launcher/    home screen
    apps/        PackageManager bridge + config
    search/
    favorites/
    mindful_delay/
    daily_limits/
    focus_mode/
    scheduled_block/
    screen_time/
    settings/
    productivity/   centralized launch rules
```

**Launch decision order**

1. Focus Mode  
2. Scheduled Block  
3. Daily Limit  
4. Mindful Delay  
5. Launch  

---

## Gestures

| Gesture | Action |
|---------|--------|
| Tap app | Launch (with rules) |
| Long-press app | Options |
| Swipe up | Search |
| Long-press clock | Screen Time / Settings / Focus Mode |

---

## License

Use and modify freely for personal or commercial projects.
