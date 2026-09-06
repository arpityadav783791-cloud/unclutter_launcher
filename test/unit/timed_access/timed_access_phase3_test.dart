import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/storage_service.dart';
import 'package:minimal_launcher/features/apps/models/app_info.dart';
import 'package:minimal_launcher/features/timed_access/controllers/timed_access_controller.dart';
import 'package:minimal_launcher/features/timed_access/data/repositories/timed_access_repository_impl.dart';
import 'package:minimal_launcher/features/timed_access/domain/entities/timed_access_session.dart';
import 'package:minimal_launcher/features/timed_access/domain/entities/timed_access_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3: TimedAccessSession Domain & Unique ID', () {
    test('every newly created session receives a distinct, unique sessionId', () {
      final session1 = TimedAccessSession.create(
        packageName: 'com.google.android.youtube',
        duration: const Duration(minutes: 10),
      );
      final session2 = TimedAccessSession.create(
        packageName: 'com.google.android.youtube',
        duration: const Duration(minutes: 10),
      );

      expect(session1.id, isNotEmpty);
      expect(session2.id, isNotEmpty);
      expect(session1.id, isNot(equals(session2.id)));
    });

    test('centralized validity rule correctly identifies active vs expired sessions', () {
      final baseTime = DateTime(2026, 9, 5, 12, 0, 0);

      final activeSession = TimedAccessSession(
        id: 'active_1',
        packageName: 'com.instagram.android',
        startedAt: baseTime,
        expiresAt: baseTime.add(const Duration(minutes: 15)),
        status: TimedAccessStatus.active,
      );

      // Before expiry: valid
      final checkBefore = baseTime.add(const Duration(minutes: 5));
      expect(activeSession.isValid(checkBefore), isTrue);
      expect(activeSession.isExpiredAt(checkBefore), isFalse);
      expect(
        activeSession.remainingDuration(checkBefore),
        const Duration(minutes: 10),
      );

      // Exactly at expiry: expired
      final checkAtExpiry = baseTime.add(const Duration(minutes: 15));
      expect(activeSession.isValid(checkAtExpiry), isFalse);
      expect(activeSession.isExpiredAt(checkAtExpiry), isTrue);
      expect(activeSession.remainingDuration(checkAtExpiry), Duration.zero);

      // Past expiry: expired
      final checkAfter = baseTime.add(const Duration(minutes: 20));
      expect(activeSession.isValid(checkAfter), isFalse);
      expect(activeSession.isExpiredAt(checkAfter), isTrue);
      expect(activeSession.remainingDuration(checkAfter), Duration.zero);

      // If status is not active, invalid regardless of time
      final terminatingSession = activeSession.copyWith(
        status: TimedAccessStatus.terminating,
      );
      expect(terminatingSession.isValid(checkBefore), isFalse);
    });
  });

  group('Phase 3: Repository Persistence & Corrupt Recovery', () {
    late StorageService storageService;
    late TimedAccessRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      storageService = await StorageService().init();
      Get.put<StorageService>(storageService);
      repository = TimedAccessRepositoryImpl(storageService: storageService);
    });

    test('updateSession persists modifications', () async {
      final initial = TimedAccessSession.create(
        packageName: 'com.reddit.frontpage',
        duration: const Duration(minutes: 5),
      );
      await repository.saveSession(initial);

      final updated = initial.copyWith(
        status: TimedAccessStatus.expiredWaitingForDecision,
      );
      await repository.updateSession(updated);

      final retrieved = await repository.getActiveSession();
      expect(retrieved, isNotNull);
      expect(retrieved!.status, TimedAccessStatus.expiredWaitingForDecision);
    });

    test('corrupt JSON or invalid fields safely discarded without crash', () async {
      // Write malformed JSON directly into storage
      await storageService.setString('active_timed_access_session', '{not valid json');
      final retrieved1 = await repository.getActiveSession();
      expect(retrieved1, isNull);

      // Write valid JSON with missing essential fields
      final invalidMap = {'packageName': 'com.test', 'status': 'active'};
      await storageService.setString(
        'active_timed_access_session',
        jsonEncode(invalidMap),
      );
      final retrieved2 = await repository.getActiveSession();
      expect(retrieved2, isNull);
    });
  });

  group('Phase 3: Session Engine Restoration & Single Session Rule', () {
    late StorageService storageService;
    late TimedAccessRepositoryImpl repository;
    late TimedAccessController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      storageService = await StorageService().init();
      Get.put<StorageService>(storageService);
      repository = TimedAccessRepositoryImpl(storageService: storageService);
      controller = TimedAccessController(repository: repository);
      Get.put<TimedAccessController>(controller);
    });

    test('restoration Case A: No stored session restores status none', () async {
      await controller.restoreSession();
      expect(controller.session, isNull);
      expect(controller.status, TimedAccessStatus.none);
      expect(controller.hasActiveSession, isFalse);
    });

    test('restoration Case B: Stored session with expiresAt > now restores ACTIVE', () async {
      final now = DateTime.now();
      final futureExpiry = now.add(const Duration(minutes: 10));

      final activeSession = TimedAccessSession(
        id: 'active_session_101',
        packageName: 'com.google.android.youtube',
        startedAt: now.subtract(const Duration(minutes: 5)),
        expiresAt: futureExpiry,
        status: TimedAccessStatus.active,
      );
      await repository.saveSession(activeSession);

      // Restore session evaluated at now (expiresAt > now)
      await controller.restoreSession(now);

      expect(controller.session, isNotNull);
      expect(controller.session!.packageName, 'com.google.android.youtube');
      expect(controller.status, TimedAccessStatus.active);
      expect(controller.hasActiveSession, isTrue);
    });

    test('restoration Case C: Stored session with expiresAt <= now restores EXPIRED_WAITING_FOR_DECISION without app termination', () async {
      final now = DateTime.now();
      final pastStart = now.subtract(const Duration(minutes: 20));
      final pastExpiry = now.subtract(const Duration(minutes: 5));

      // Even if storage had status "active", timestamp proves it is expired
      final storedExpired = TimedAccessSession(
        id: 'expired_session_102',
        packageName: 'com.google.android.youtube',
        startedAt: pastStart,
        expiresAt: pastExpiry,
        status: TimedAccessStatus.active,
      );
      await repository.saveSession(storedExpired);

      await controller.restoreSession(now);

      expect(controller.session, isNotNull);
      expect(controller.status, TimedAccessStatus.expiredWaitingForDecision);
      expect(controller.hasActiveSession, isFalse);

      // Verify repository updated to reflect expiredWaitingForDecision
      final inStorage = await repository.getActiveSession();
      expect(inStorage!.status, TimedAccessStatus.expiredWaitingForDecision);
    });

    test('never trust persisted status alone: timestamp determines real-time status', () {
      final pastExpiry = DateTime.now().subtract(const Duration(seconds: 10));
      final sessionWithStaleStatus = TimedAccessSession(
        id: 'stale_103',
        packageName: 'com.twitter.android',
        startedAt: pastExpiry.subtract(const Duration(minutes: 15)),
        expiresAt: pastExpiry,
        status: TimedAccessStatus.active,
      );

      controller.setSession(sessionWithStaleStatus);

      // Controller status overrides stale active metadata
      expect(controller.status, TimedAccessStatus.expiredWaitingForDecision);
      expect(controller.hasActiveSession, isFalse);
    });

    test('Single Session Rule: cannot create second session while one is active', () async {
      const app1 = AppInfo(name: 'YouTube', packageName: 'com.google.android.youtube');
      const app2 = AppInfo(name: 'Instagram', packageName: 'com.instagram.android');

      // 1. Start session for YouTube
      controller.selectedApp.value = app1;
      controller.selectPresetDuration(10);
      final session1 = await controller.startTimedAccess();
      expect(session1, isNotNull);
      expect(controller.hasActiveSession, isTrue);

      // 2. Try to start second session for Instagram
      controller.selectedApp.value = app2;
      controller.selectPresetDuration(15);
      final session2 = await controller.startTimedAccess();

      // Second session must be rejected
      expect(session2, isNull);
      expect(controller.session!.packageName, 'com.google.android.youtube');
      expect(controller.session!.id, session1!.id);
    });

    test('Single Session Rule: openDurationSheet blocks if session is active', () {
      const app1 = AppInfo(name: 'YouTube', packageName: 'com.google.android.youtube');
      final activeSession = TimedAccessSession.create(
        packageName: app1.packageName,
        duration: const Duration(minutes: 10),
      );
      controller.setSession(activeSession);
      expect(controller.hasActiveSession, isTrue);

      const app2 = AppInfo(name: 'Instagram', packageName: 'com.instagram.android');
      controller.openDurationSheet(app2);

      // selectedApp was NOT overwritten because an active session was running
      expect(controller.selectedApp.value?.packageName, isNot(equals(app2.packageName)));
    });

    test('clearSession clears both in-memory state and repository', () async {
      const app = AppInfo(name: 'YouTube', packageName: 'com.google.android.youtube');
      controller.selectedApp.value = app;
      await controller.startTimedAccess();
      expect(controller.hasActiveSession, isTrue);

      await controller.clearSession();
      expect(controller.session, isNull);
      expect(controller.status, TimedAccessStatus.none);
      expect(controller.hasActiveSession, isFalse);
      expect(await repository.getActiveSession(), isNull);
    });
  });
}
