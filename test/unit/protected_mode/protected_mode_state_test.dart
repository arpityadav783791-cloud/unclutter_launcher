import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_launcher/features/protected_mode/models/protected_mode_state.dart';

void main() {
  group('ProtectedModeState Model Tests', () {
    test('initial() sets expected default values', () {
      final state = ProtectedModeState.initial();
      expect(state.enabled, isFalse);
      expect(state.enabledAt, isNull);
      expect(state.deviceOwnerActive, isFalse);
      expect(state.defaultLauncherActive, isFalse);
    });

    test('fromMap and toMap round-trip accurately preserves data', () {
      final now = DateTime.now();
      final state = ProtectedModeState(
        enabled: true,
        enabledAt: now,
        deviceOwnerActive: true,
        defaultLauncherActive: true,
      );

      final map = state.toMap();
      final restored = ProtectedModeState.fromMap(map);

      expect(restored.enabled, isTrue);
      expect(restored.deviceOwnerActive, isTrue);
      expect(restored.defaultLauncherActive, isTrue);
      expect(
        restored.enabledAt?.millisecondsSinceEpoch,
        equals(now.millisecondsSinceEpoch),
      );
    });

    test('fromMap gracefully handles empty or null map', () {
      final state = ProtectedModeState.fromMap({});
      expect(state.enabled, isFalse);
      expect(state.enabledAt, isNull);
      expect(state.deviceOwnerActive, isFalse);
      expect(state.defaultLauncherActive, isFalse);
    });

    test('copyWith updates only target fields', () {
      final initial = ProtectedModeState.initial();
      final updated = initial.copyWith(
        enabled: true,
        deviceOwnerActive: true,
      );

      expect(updated.enabled, isTrue);
      expect(updated.deviceOwnerActive, isTrue);
      expect(updated.defaultLauncherActive, isFalse);
      expect(updated.enabledAt, isNull);
    });

    test('equality and hashCode work as expected', () {
      final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final state1 = ProtectedModeState(
        enabled: true,
        enabledAt: now,
        deviceOwnerActive: true,
        defaultLauncherActive: true,
      );
      final state2 = ProtectedModeState(
        enabled: true,
        enabledAt: now,
        deviceOwnerActive: true,
        defaultLauncherActive: true,
      );
      final state3 = ProtectedModeState(
        enabled: false,
        deviceOwnerActive: false,
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
      expect(state1, isNot(equals(state3)));
    });
  });
}
