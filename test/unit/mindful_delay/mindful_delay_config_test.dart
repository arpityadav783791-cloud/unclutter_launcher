import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_launcher/features/mindful_delay/models/mindful_delay_config.dart';

void main() {
  group('MindfulDelayConfig', () {
    test('available durations are expected', () {
      expect(MindfulDelayConfig.availableDurations, contains(5));
      expect(MindfulDelayConfig.availableDurations, contains(60));
      expect(MindfulDelayConfig.availableDurations, contains(600));
    });

    test('formatDuration', () {
      expect(MindfulDelayConfig.formatDuration(5), '5 seconds');
      expect(MindfulDelayConfig.formatDuration(30), '30 seconds');
      expect(MindfulDelayConfig.formatDuration(60), '1 minute');
      expect(MindfulDelayConfig.formatDuration(300), '5 minutes');
      expect(MindfulDelayConfig.formatDuration(600), '10 minutes');
    });

    test('serialization round-trip', () {
      final original = MindfulDelayConfig(
        packageName: 'com.instagram.android',
        enabled: true,
        durationSeconds: 15,
      );
      final restored = MindfulDelayConfig.fromMap(original.toMap());
      expect(restored.packageName, original.packageName);
      expect(restored.enabled, true);
      expect(restored.durationSeconds, 15);
    });

    test('copyWith', () {
      final base = MindfulDelayConfig(
        packageName: 'com.test',
        enabled: false,
        durationSeconds: 5,
      );
      final updated = base.copyWith(enabled: true, durationSeconds: 30);
      expect(updated.enabled, true);
      expect(updated.durationSeconds, 30);
      expect(updated.packageName, 'com.test');
    });
  });
}
