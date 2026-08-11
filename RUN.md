# Run checklist — Minimal Launcher

## Prerequisites
- Flutter **3.44.6+** on PATH
- Android SDK + platform-tools
- JDK **17**
- A physical device or emulator (API 24+)

## First-time setup (required)

```bash
cd minimal_launcher

# Regenerate any missing platform glue Flutter expects (safe; keeps lib/)
flutter create . --platforms=android --project-name minimal_launcher --org com.minimal

flutter clean
flutter pub get
flutter analyze
```

> `flutter create .` only fills missing Android host files.  
> Your `lib/`, custom `MainActivity.kt`, icons, and manifests are kept.

## Run

```bash
flutter run
```

## Set as default Home app
1. Install/run the app  
2. Press **Home** → choose **Minimal Launcher**  
   or: Settings → Apps → Default apps → Home app  

## Usage Access (Screen Time / Daily Limits)
Settings → Apps → Special app access → Usage access → enable for Minimal Launcher  

## Build status of this package

| Check | Status |
|-------|--------|
| AGP 8.7.3 + Gradle 8.9 + Kotlin 1.9.24 | ✅ |
| `ic_launcher` all densities + adaptive | ✅ |
| HOME / DEFAULT intent-filters | ✅ |
| MethodChannel + MainActivity | ✅ |
| gradlew + wrapper jar | ✅ |
| Debug/Profile INTERNET manifests | ✅ |
| Namespace / applicationId match | ✅ |
| Dart launcher code (Phases 1–18) | ✅ |

Cannot guarantee 100% without executing `flutter run` on your machine  
(no Flutter SDK in the build environment that produced this zip).  
After the steps above, a normal Android device should build and launch.
