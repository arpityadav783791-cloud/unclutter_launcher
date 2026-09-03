import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_launcher/features/timed_access/models/timed_app_session.dart';

void main() {
  group('TimedAppSession', () {
    test('session creation with correct start and expiry timestamps', () {
      final now = DateTime(2026, 9, 3, 12, 0, 0);
      final session = TimedAppSession.create(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        durationMinutes: 10,
        now: now,
      );

      expect(session.packageName, 'com.instagram.android');
      expect(session.appName, 'Instagram');
      expect(session.durationMinutes, 10);
      expect(session.startedAt, now);
      expect(session.expiresAt, now.add(const Duration(minutes: 10)));
    });

    test('expiry calculation', () {
      final past = DateTime.now().subtract(const Duration(minutes: 1));
      final expiredSession = TimedAppSession(
        packageName: 'com.test',
        appName: 'Test',
        startedAt: past.subtract(const Duration(minutes: 10)),
        expiresAt: past,
        durationMinutes: 10,
      );
      expect(expiredSession.isExpired, isTrue);
      expect(expiredSession.remainingDuration, Duration.zero);
      expect(expiredSession.remainingSeconds, 0);
      expect(expiredSession.remainingMinutes, 0);

      final future = DateTime.now().add(const Duration(minutes: 5, seconds: 30));
      final activeSession = TimedAppSession(
        packageName: 'com.test',
        appName: 'Test',
        startedAt: DateTime.now(),
        expiresAt: future,
        durationMinutes: 6,
      );
      expect(activeSession.isExpired, isFalse);
      expect(activeSession.remainingSeconds, greaterThan(300));
      expect(activeSession.remainingMinutes, 6);
    });

    test('serialization and deserialization round-trip', () {
      final now = DateTime.now();
      final original = TimedAppSession(
        packageName: 'com.google.android.youtube',
        appName: 'YouTube',
        startedAt: now,
        expiresAt: now.add(const Duration(minutes: 15)),
        durationMinutes: 15,
      );

      final map = original.toMap();
      final restored = TimedAppSession.fromMap(map);

      expect(restored.packageName, original.packageName);
      expect(restored.appName, original.appName);
      expect(restored.durationMinutes, original.durationMinutes);
      expect(
        restored.startedAt.millisecondsSinceEpoch ~/ 1000,
        original.startedAt.millisecondsSinceEpoch ~/ 1000,
      );
      expect(
        restored.expiresAt.millisecondsSinceEpoch ~/ 1000,
        original.expiresAt.millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('copyWith works correctly', () {
      final now = DateTime.now();
      final session = TimedAppSession(
        packageName: 'com.test',
        appName: 'Test',
        startedAt: now,
        expiresAt: now.add(const Duration(minutes: 5)),
        durationMinutes: 5,
      );

      final updated = session.copyWith(
        durationMinutes: 10,
        expiresAt: now.add(const Duration(minutes: 10)),
      );

      expect(updated.durationMinutes, 10);
      expect(updated.expiresAt, now.add(const Duration(minutes: 10)));
      expect(updated.packageName, 'com.test');
      expect(updated.appName, 'Test');
    });

    test('equality and hashCode', () {
      final now = DateTime(2026, 1, 1, 10, 0);
      final expiry = now.add(const Duration(minutes: 15));
      final session1 = TimedAppSession(
        packageName: 'com.test',
        appName: 'Test',
        startedAt: now,
        expiresAt: expiry,
        durationMinutes: 15,
      );
      final session2 = TimedAppSession(
        packageName: 'com.test',
        appName: 'Test',
        startedAt: now,
        expiresAt: expiry,
        durationMinutes: 15,
      );

      expect(session1, equals(session2));
      expect(session1.hashCode, equals(session2.hashCode));
    });
  });
}
