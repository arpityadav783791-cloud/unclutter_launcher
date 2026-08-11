# Android build configuration (Flutter 3.44.6)

## Versions (compatible set)

| Component | Version |
|-----------|---------|
| Flutter   | 3.44.6  |
| AGP       | 8.7.3   |
| Gradle    | 8.9     |
| Kotlin    | 1.9.24  |
| JDK       | 17      |

These were upgraded **together**. Do not mix older AGP with newer Gradle (or the reverse).

## Compatibility properties

In `android/gradle.properties`:

```properties
android.newDsl=false
android.builtInKotlin=false
```

This keeps the classic Flutter/Kotlin plugin setup and avoids forcing AGP 9 built-in Kotlin migration.

## Verify

```bash
flutter clean
flutter pub get
flutter analyze
flutter analyze --suggestions
flutter run
```

Expected: no Gradle / AGP / KGP version errors.
