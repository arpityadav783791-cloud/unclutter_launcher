# Production checklist

## Before release

- [ ] Update `version` in `pubspec.yaml` (e.g. `1.0.0+1`)
- [ ] Create keystore and fill `android/key.properties`
- [ ] Run `flutter analyze` — fix issues
- [ ] Run `flutter test`
- [ ] Test on a real device as **default Home app**
- [ ] Grant Usage Access and verify Screen Time / Daily Limits
- [ ] Verify Focus Mode, Mindful Delay, Scheduled Blocks
- [ ] Test light / dark / system theme
- [ ] Remove any temporary debug UI (none left by design)

## Build commands

```bash
# APK
flutter build apk --release

# Play Store bundle
flutter build appbundle --release

# Split per-ABI APKs (smaller downloads)
flutter build apk --release --split-per-abi
```

## Optional: obfuscation

```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols
```

Keep the `build/symbols` folder for crash deobfuscation.

## Store listing tips

- Screenshots of the text-only home screen work well
- Emphasize: no icons, mindful delay, focus mode, low distraction
- Privacy: all data stays on-device (SharedPreferences); no accounts, no analytics by default
