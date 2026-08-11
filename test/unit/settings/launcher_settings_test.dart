import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_launcher/features/settings/models/launcher_settings.dart';

void main() {
  group('LauncherSettings', () {
    test('defaults', () {
      const s = LauncherSettings();
      expect(s.showClock, true);
      expect(s.showDate, true);
      expect(s.textScale, 1.0);
      expect(s.themeMode, 'system');
    });

    test('serialization round-trip', () {
      const original = LauncherSettings(
        showClock: false,
        showDate: true,
        textScale: 1.15,
        themeMode: 'dark',
      );
      final restored = LauncherSettings.fromMap(original.toMap());
      expect(restored.showClock, false);
      expect(restored.showDate, true);
      expect(restored.textScale, 1.15);
      expect(restored.themeMode, 'dark');
    });

    test('copyWith', () {
      const base = LauncherSettings();
      final updated = base.copyWith(themeMode: 'light', textScale: 0.9);
      expect(updated.themeMode, 'light');
      expect(updated.textScale, 0.9);
      expect(updated.showClock, true);
    });
  });
}
