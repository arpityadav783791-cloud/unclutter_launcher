import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_launcher/features/daily_limits/models/daily_limit_config.dart';

void main() {
  group('DailyLimitConfig', () {
    test('effective limit without extension', () {
      final config = DailyLimitConfig(
        packageName: 'com.example',
        enabled: true,
        limitMinutes: 30,
      );
      expect(config.effectiveLimitMinutes('2026-08-11'), 30);
    });

    test('effective limit with same-day extension', () {
      final config = DailyLimitConfig(
        packageName: 'com.example',
        enabled: true,
        limitMinutes: 30,
        extensionMinutesToday: 5,
        extensionDate: '2026-08-11',
      );
      expect(config.effectiveLimitMinutes('2026-08-11'), 35);
      // Different day → extension ignored
      expect(config.effectiveLimitMinutes('2026-08-12'), 30);
    });

    test('formatMinutes', () {
      expect(DailyLimitConfig.formatMinutes(5), '5 min');
      expect(DailyLimitConfig.formatMinutes(60), '1 hour');
      expect(DailyLimitConfig.formatMinutes(90), '1h 30m');
      expect(DailyLimitConfig.formatMinutes(120), '2 hours');
    });

    test('serialization round-trip', () {
      final original = DailyLimitConfig(
        packageName: 'com.test',
        enabled: true,
        limitMinutes: 45,
        extensionMinutesToday: 5,
        extensionDate: '2026-08-11',
      );
      final restored = DailyLimitConfig.fromMap(original.toMap());
      expect(restored.packageName, original.packageName);
      expect(restored.enabled, true);
      expect(restored.limitMinutes, 45);
      expect(restored.extensionMinutesToday, 5);
      expect(restored.extensionDate, '2026-08-11');
    });
  });
}
