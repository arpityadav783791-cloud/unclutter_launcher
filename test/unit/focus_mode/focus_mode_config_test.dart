import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_launcher/features/focus_mode/models/focus_mode_config.dart';

void main() {
  group('FocusModeConfig', () {
    test('inactive when not active', () {
      const config = FocusModeConfig(isActive: false);
      expect(config.isCurrentlyActive, false);
      expect(config.remaining, Duration.zero);
    });

    test('active with future endsAt', () {
      final endsAt = DateTime.now().add(const Duration(minutes: 30));
      final config = FocusModeConfig(isActive: true, endsAt: endsAt);
      expect(config.isCurrentlyActive, true);
      expect(config.remaining.inMinutes, greaterThanOrEqualTo(29));
    });

    test('expired when endsAt in the past', () {
      final endsAt = DateTime.now().subtract(const Duration(minutes: 5));
      final config = FocusModeConfig(isActive: true, endsAt: endsAt);
      expect(config.isCurrentlyActive, false);
      expect(config.remaining, Duration.zero);
    });

    test('formatDuration', () {
      expect(FocusModeConfig.formatDuration(Duration.zero), '0m');
      expect(
        FocusModeConfig.formatDuration(const Duration(minutes: 45)),
        '45m',
      );
      expect(
        FocusModeConfig.formatDuration(const Duration(hours: 1, minutes: 20)),
        '1h 20m',
      );
    });

    test('serialization round-trip', () {
      final endsAt = DateTime.now().add(const Duration(hours: 1));
      final original = FocusModeConfig(
        isActive: true,
        endsAt: endsAt,
        blockedPackages: ['com.a', 'com.b'],
      );
      final restored = FocusModeConfig.fromMap(original.toMap());
      expect(restored.isActive, true);
      expect(restored.blockedPackages, ['com.a', 'com.b']);
      expect(restored.endsAt?.toIso8601String(), endsAt.toIso8601String());
    });
  });
}
