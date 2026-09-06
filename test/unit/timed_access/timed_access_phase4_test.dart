import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/native_bridge.dart';
import 'package:minimal_launcher/core/services/storage_service.dart';
import 'package:minimal_launcher/features/apps/models/app_info.dart';
import 'package:minimal_launcher/features/timed_access/controllers/timed_access_controller.dart';
import 'package:minimal_launcher/features/timed_access/data/repositories/timed_access_repository_impl.dart';
import 'package:minimal_launcher/features/timed_access/domain/entities/timed_access_session.dart';
import 'package:minimal_launcher/features/timed_access/domain/entities/timed_access_status.dart';
import 'package:minimal_launcher/features/timed_access/services/app_launcher.dart';
import 'package:minimal_launcher/features/timed_access/services/timed_access_native_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockNativeBridge extends NativeBridge {}

class MockTimedAccessNativeService implements TimedAccessNativeService {
  bool shouldFailStart = false;
  String? lastStartedSessionId;
  String? lastStartedPackage;
  DateTime? lastExpiresAt;
  String? lastClearedSessionId;

  @override
  Future<void> startSession({
    required String sessionId,
    required String packageName,
    required DateTime expiresAt,
  }) async {
    if (shouldFailStart) {
      throw Exception('Native monitoring registration failed');
    }
    lastStartedSessionId = sessionId;
    lastStartedPackage = packageName;
    lastExpiresAt = expiresAt;
  }

  @override
  Future<void> clearSession({required String sessionId}) async {
    lastClearedSessionId = sessionId;
  }

  @override
  Future<void> extendSession({
    required String sessionId,
    required String packageName,
    required DateTime expiresAt,
  }) async {}

  @override
  Future<void> showExpiryDialog({
    required String sessionId,
    required String packageName,
  }) async {}

  @override
  Future<void> takeMeOut({
    required String sessionId,
    required String packageName,
  }) async {}
}

class MockAppLauncher implements AppLauncher {
  bool shouldFailLaunch = false;
  String? lastLaunchedPackage;
  int launchCallCount = 0;

  @override
  Future<bool> launch(String packageName) async {
    launchCallCount++;
    if (shouldFailLaunch) {
      return false;
    }
    lastLaunchedPackage = packageName;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 4: Start Order & App Launch Flow', () {
    late StorageService storageService;
    late TimedAccessRepositoryImpl repository;
    late MockTimedAccessNativeService mockNativeService;
    late MockAppLauncher mockAppLauncher;
    late TimedAccessController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      Get.put<NativeBridge>(MockNativeBridge());
      storageService = await StorageService().init();
      Get.put<StorageService>(storageService);
      repository = TimedAccessRepositoryImpl(storageService: storageService);
      mockNativeService = MockTimedAccessNativeService();
      mockAppLauncher = MockAppLauncher();

      controller = TimedAccessController(
        repository: repository,
        nativeService: mockNativeService,
        appLauncher: mockAppLauncher,
      );
      Get.put<TimedAccessController>(controller);
    });

    tearDown(() {
      controller.onClose();
    });

    test('successful Start persists session, registers native monitoring, and launches target app', () async {
      const app = AppInfo(name: 'YouTube', packageName: 'com.google.android.youtube');
      controller.selectedApp.value = app;
      controller.selectPresetDuration(10);

      final session = await controller.startTimedAccess();

      // 1. Valid session returned
      expect(session, isNotNull);
      expect(session!.packageName, 'com.google.android.youtube');
      expect(controller.status, TimedAccessStatus.active);
      expect(controller.hasActiveSession, isTrue);

      // 2. Persisted in repository
      final inStorage = await repository.getActiveSession();
      expect(inStorage, isNotNull);
      expect(inStorage!.id, session.id);

      // 3. Registered with native monitoring
      expect(mockNativeService.lastStartedSessionId, session.id);
      expect(mockNativeService.lastStartedPackage, 'com.google.android.youtube');
      expect(mockNativeService.lastExpiresAt, session.expiresAt);

      // 4. Launched target app
      expect(mockAppLauncher.lastLaunchedPackage, 'com.google.android.youtube');
      expect(mockAppLauncher.launchCallCount, 1);

      // 5. Countdown running
      expect(controller.remainingDuration.value.inMinutes, greaterThanOrEqualTo(9));
      expect(controller.formattedRemainingTime, isNotEmpty);
    });

    test('persistence rollback when native monitoring registration fails', () async {
      mockNativeService.shouldFailStart = true;
      const app = AppInfo(name: 'Instagram', packageName: 'com.instagram.android');
      controller.selectedApp.value = app;

      final session = await controller.startTimedAccess();

      // Start fails
      expect(session, isNull);
      expect(controller.hasActiveSession, isFalse);

      // App was NOT launched
      expect(mockAppLauncher.launchCallCount, 0);

      // Persisted session was rolled back
      expect(await repository.getActiveSession(), isNull);
    });

    test('rollback when target app launch fails', () async {
      mockAppLauncher.shouldFailLaunch = true;
      const app = AppInfo(name: 'Instagram', packageName: 'com.instagram.android');
      controller.selectedApp.value = app;

      final session = await controller.startTimedAccess();

      // Start fails
      expect(session, isNull);
      expect(controller.hasActiveSession, isFalse);

      // Native monitoring was stopped
      expect(mockNativeService.lastClearedSessionId, isNotNull);

      // Persisted session was cleared (no phantom ACTIVE session)
      expect(await repository.getActiveSession(), isNull);
    });
  });

  group('Phase 4: Countdown Engine & Expiry Transition', () {
    late StorageService storageService;
    late TimedAccessRepositoryImpl repository;
    late MockTimedAccessNativeService mockNativeService;
    late MockAppLauncher mockAppLauncher;
    late TimedAccessController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      Get.put<NativeBridge>(MockNativeBridge());
      storageService = await StorageService().init();
      Get.put<StorageService>(storageService);
      repository = TimedAccessRepositoryImpl(storageService: storageService);
      mockNativeService = MockTimedAccessNativeService();
      mockAppLauncher = MockAppLauncher();

      controller = TimedAccessController(
        repository: repository,
        nativeService: mockNativeService,
        appLauncher: mockAppLauncher,
      );
      Get.put<TimedAccessController>(controller);
    });

    tearDown(() {
      controller.onClose();
    });

    test('recalculates countdown on resume and transitions to expired if time passed', () async {
      final now = DateTime.now();
      final expiredTime = now.subtract(const Duration(minutes: 1));

      // Active session whose expiry was in the past
      final session = TimedAccessSession(
        id: 'session_expired_past',
        packageName: 'com.reddit.frontpage',
        startedAt: expiredTime.subtract(const Duration(minutes: 10)),
        expiresAt: expiredTime,
        status: TimedAccessStatus.active,
      );
      controller.setSession(session);

      // Trigger app resumed
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

      // Target app remains open, state transitions to EXPIRED_WAITING_FOR_DECISION
      expect(controller.status, TimedAccessStatus.expiredWaitingForDecision);
      expect(controller.hasActiveSession, isFalse);
      expect(controller.remainingDuration.value, Duration.zero);

      final inStorage = await repository.getActiveSession();
      expect(inStorage!.status, TimedAccessStatus.expiredWaitingForDecision);
    });

    test('stale callback protection ignores callbacks from previous sessions', () async {
      const app = AppInfo(name: 'YouTube', packageName: 'com.google.android.youtube');
      controller.selectedApp.value = app;
      final sessionB = await controller.startTimedAccess();
      expect(sessionB, isNotNull);
      expect(controller.status, TimedAccessStatus.active);

      // Simulate an old callback arriving for session A
      // (sessionId = 'old_session_A')
      final bridge = Get.find<NativeBridge>();
      bridge.onTimedAccessExpired?.call('old_session_A', 'com.google.android.youtube');

      // Session B must NOT be modified
      expect(controller.session!.id, sessionB!.id);
      expect(controller.status, TimedAccessStatus.active);
      expect(controller.hasActiveSession, isTrue);
    });

    test('restoring ACTIVE session re-registers native monitoring with correct remaining time', () async {
      final now = DateTime.now();
      final future = now.add(const Duration(minutes: 7, seconds: 30));

      final activeSession = TimedAccessSession(
        id: 'restored_session_99',
        packageName: 'com.twitter.android',
        startedAt: now.subtract(const Duration(minutes: 2, seconds: 30)),
        expiresAt: future,
        status: TimedAccessStatus.active,
      );
      await repository.saveSession(activeSession);

      // Restart controller / restore
      await controller.restoreSession(now);

      expect(controller.status, TimedAccessStatus.active);
      expect(controller.session!.id, 'restored_session_99');
      expect(mockNativeService.lastStartedSessionId, 'restored_session_99');
      expect(
        mockNativeService.lastExpiresAt!.millisecondsSinceEpoch,
        future.millisecondsSinceEpoch,
      );
      // Countdown resumed with remaining time (~7m 30s), NOT reset to 10m
      expect(controller.remainingDuration.value.inMinutes, 7);
    });
  });
}
