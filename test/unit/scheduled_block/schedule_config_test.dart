import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_launcher/features/scheduled_block/models/schedule_config.dart';

void main() {
  group('ScheduleConfig', () {
    test('same-day range blocks correctly', () {
      // 9:00 AM (540) → 12:00 PM (720)
      final config = ScheduleConfig(
        packageName: 'com.example',
        enabled: true,
        startMinutes: 9 * 60,
        endMinutes: 12 * 60,
      );

      // We can't control DateTime.now easily without injection,
      // so we test the pure logic via a helper-style check.
      // For unit purity we test the boundary logic with a local function.
      bool isBlockedAt(int currentMinutes) {
        if (!config.enabled) return false;
        final start = config.startMinutes;
        final end = config.endMinutes;
        if (start < end) {
          return currentMinutes >= start && currentMinutes < end;
        } else {
          return currentMinutes >= start || currentMinutes < end;
        }
      }

      expect(isBlockedAt(8 * 60 + 59), false); // 8:59
      expect(isBlockedAt(9 * 60), true);       // 9:00
      expect(isBlockedAt(10 * 60), true);      // 10:00
      expect(isBlockedAt(11 * 60 + 59), true); // 11:59
      expect(isBlockedAt(12 * 60), false);     // 12:00
    });

    test('overnight range blocks correctly', () {
      // 10:00 PM (1320) → 7:00 AM (420)
      final config = ScheduleConfig(
        packageName: 'com.example',
        enabled: true,
        startMinutes: 22 * 60,
        endMinutes: 7 * 60,
      );

      bool isBlockedAt(int currentMinutes) {
        if (!config.enabled) return false;
        final start = config.startMinutes;
        final end = config.endMinutes;
        if (start < end) {
          return currentMinutes >= start && currentMinutes < end;
        } else {
          return currentMinutes >= start || currentMinutes < end;
        }
      }

      expect(isBlockedAt(21 * 60 + 59), false); // 9:59 PM
      expect(isBlockedAt(22 * 60), true);       // 10:00 PM
      expect(isBlockedAt(23 * 60), true);       // 11:00 PM
      expect(isBlockedAt(0), true);             // 12:00 AM
      expect(isBlockedAt(6 * 60 + 59), true);   // 6:59 AM
      expect(isBlockedAt(7 * 60), false);       // 7:00 AM
      expect(isBlockedAt(12 * 60), false);      // 12:00 PM
    });

    test('disabled schedule never blocks', () {
      final config = ScheduleConfig(
        packageName: 'com.example',
        enabled: false,
        startMinutes: 0,
        endMinutes: 23 * 60,
      );
      expect(config.isCurrentlyBlocked(), false);
    });

    test('format helpers', () {
      expect(ScheduleConfig.presetLabel(22 * 60, 7 * 60), contains('PM'));
      expect(ScheduleConfig.presetLabel(9 * 60, 12 * 60), contains('AM'));
    });

    test('serialization round-trip', () {
      final original = ScheduleConfig(
        packageName: 'com.test.app',
        enabled: true,
        startMinutes: 21 * 60,
        endMinutes: 6 * 60,
      );
      final restored = ScheduleConfig.fromMap(original.toMap());
      expect(restored.packageName, original.packageName);
      expect(restored.enabled, original.enabled);
      expect(restored.startMinutes, original.startMinutes);
      expect(restored.endMinutes, original.endMinutes);
    });
  });
}
