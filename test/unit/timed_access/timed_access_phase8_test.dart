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

class MockAppLauncher implements AppLauncher {
  bool launchResult = true;
  String? lastLaunchedPackage;

  @override
  Future<bool> launch(String packageName) async {
    lastLaunchedPackage = packageName;
    return launchResult;
  }
}

class MockTimedAccessNativeService implements TimedAccessNativeService {
  bool shouldFailStart = false;
  bool shouldFailExtend = false;
  bool shouldFailTerminate = false;

  int startCount = 0;
  int extendCount = 0;
  int terminateCount = 0;

  String? lastStartedSessionId;
  String? lastStartedPackageName;
  DateTime? lastStartedExpiresAt;

  @override
  Future<void> startSession({
    required String sessionId,
    required String packageName,
    required DateTime expiresAt,
  }) async {
    if (shouldFailStart) {
      throw Exception('Native start failed');
    }
    startCount++;
    lastStartedSessionId = sessionId;
    lastStartedPackageName = packageName;
    lastStartedExpiresAt = expiresAt;
  }

  @override
  Future<void> extendSession({
    required String sessionId,
    required String packageName,
    required DateTime expiresAt,
  }) async {
    if (shouldFailExtend) {
      throw Exception('Native extend failed');
    }
    extendCount++;
    await startSession(
      sessionId: sessionId,
      packageName: packageName,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> showExpiryDialog({
    required String sessionId,
    required String packageName,
  }) async {}

  @override
  Future<void> clearSession({required String sessionId}) async {}

  @override
  Future<void> takeMeOut({
    required String sessionId,
    required String packageName,
  }) async {
    if (shouldFailTerminate) {
      throw Exception('Native termination failed');
    }
    terminateCount++;
  }
}

class MockNativeBridge extends NativeBridge {
  String? lastTerminatedSessionId;
  List<String>? setPackages;

  @override
  Future<bool> terminateTimedSession({required String sessionId}) async {
    lastTerminatedSessionId = sessionId;
    return true;
  }

  @override
  Future<bool> setDistractionPackages(List<String> packages) async {
    setPackages = packages;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late TimedAccessRepositoryImpl repository;
  late MockTimedAccessNativeService mockNativeService;
  late MockAppLauncher mockAppLauncher;
  late MockNativeBridge mockNativeBridge;

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    storageService = StorageService();
    await storageService.init();
    Get.put<StorageService>(storageService);

    repository = TimedAccessRepositoryImpl(storageService: storageService);
    mockNativeService = MockTimedAccessNativeService();
    mockAppLauncher = MockAppLauncher();
    mockNativeBridge = MockNativeBridge();

    Get.put<NativeBridge>(mockNativeBridge);
  });

  tearDown(() {
    Get.reset();
  });

  group('Phase 8: Edge Cases & Failure-Safety Hardening', () {
    test('Rapid tap deduplication: double/triple takeMeOut executes native termination once', () async {
      final controller = TimedAccessController(
        repository: repository,
        nativeService: mockNativeService,
        appLauncher: mockAppLauncher,
      );

      final now = DateTime.now();
      final expiredSession = TimedAccessSession(
        id: 'session-dup-term',
        packageName: 'com.tiktok.android',
        startedAt: now.subtract(const Duration(minutes: 10)),
        expiresAt: now.subtract(const Duration(seconds: 1)),
        status: TimedAccessStatus.expiredWaitingForDecision,
      );
      await repository.saveSession(expiredSession);
      await controller.restoreSession(now);

      expect(controller.status, TimedAccessStatus.expiredWaitingForDecision);

      // Fire multiple concurrent takeMeOut requests
      await Future.wait([
        controller.takeMeOut(),
        controller.takeMeOut(),
        controller.takeMeOut(),
      ]);

      // Exactly one native termination must have executed
      expect(mockNativeService.terminateCount, 1);
      expect(controller.session, isNull);
      expect(controller.status, TimedAccessStatus.none);

      controller.onClose();
    });

    test('Rapid tap deduplication: double/triple extendSession executes extension once', () async {
      final controller = TimedAccessController(
        repository: repository,
        nativeService: mockNativeService,
        appLauncher: mockAppLauncher,
      );

      final now = DateTime.now();
      final expiredSession = TimedAccessSession(
        id: 'session-dup-ext',
        packageName: 'com.tiktok.android',
        startedAt: now.subtract(const Duration(minutes: 10)),
        expiresAt: now.subtract(const Duration(seconds: 1)),
        status: TimedAccessStatus.expiredWaitingForDecision,
      );
      await repository.saveSession(expiredSession);
      await controller.restoreSession(now);

      expect(controller.status, TimedAccessStatus.expiredWaitingForDecision);

      // Fire multiple concurrent extendSession requests
      final results = await Future.wait([
        controller.extendSession(const Duration(minutes: 5)),
        controller.extendSession(const Duration(minutes: 5)),
        controller.extendSession(const Duration(minutes: 5)),
      ]);

      // Exactly one should succeed, others must be rejected
      final successCount = results.where((r) => r == true).length;
      expect(successCount, 1);
      expect(mockNativeService.extendCount, 1);
      expect(controller.status, TimedAccessStatus.active);

      controller.onClose();
    });

    test('Extend vs Terminate race: when takeMeOut starts, extendSession is rejected', () async {
      final controller = TimedAccessController(
        repository: repository,
        nativeService: mockNativeService,
        appLauncher: mockAppLauncher,
      );

      final now = DateTime.now();
      final expiredSession = TimedAccessSession(
        id: 'session-race-1',
        packageName: 'com.snapchat.android',
        startedAt: now.subtract(const Duration(minutes: 10)),
        expiresAt: now.subtract(const Duration(seconds: 1)),
        status: TimedAccessStatus.expiredWaitingForDecision,
      );
      await repository.saveSession(expiredSession);
      await controller.restoreSession(now);

      // Simulate termination already in progress
      controller.isTerminating.value = true;

      // Extend should immediately return false
      final extended = await controller.extendSession(const Duration(minutes: 5));
      expect(extended, isFalse);
      expect(mockNativeService.extendCount, 0);

      controller.isTerminating.value = false;
      controller.onClose();
    });

    test('Extend vs Terminate race: when extendSession starts, takeMeOut is rejected', () async {
      final controller = TimedAccessController(
        repository: repository,
        nativeService: mockNativeService,
        appLauncher: mockAppLauncher,
      );

      final now = DateTime.now();
      final expiredSession = TimedAccessSession(
        id: 'session-race-2',
        packageName: 'com.snapchat.android',
        startedAt: now.subtract(const Duration(minutes: 10)),
        expiresAt: now.subtract(const Duration(seconds: 1)),
        status: TimedAccessStatus.expiredWaitingForDecision,
      );
      await repository.saveSession(expiredSession);
      await controller.restoreSession(now);

      // Simulate extension already in progress
      controller.isExtending.value = true;

      // takeMeOut should abort and not execute termination
      await controller.takeMeOut();
      expect(mockNativeService.terminateCount, 0);
      expect(controller.session, isNotNull);

      controller.isExtending.value = false;
      controller.onClose();
    });

    test('Illegal state transitions are rejected', () async {
      final controller = TimedAccessController(
        repository: repository,
        nativeService: mockNativeService,
        appLauncher: mockAppLauncher,
      );

      // 1. Cannot extend when state is NONE
      expect(controller.status, TimedAccessStatus.none);
      final extendOnNone = await controller.extendSession(const Duration(minutes: 5));
      expect(extendOnNone, isFalse);

      // 2. Cannot extend when state is ACTIVE (not expired)
      final now = DateTime.now();
      final activeSession = TimedAccessSession(
        id: 'session-active',
        packageName: 'com.twitter.android',
        startedAt: now,
        expiresAt: now.add(const Duration(minutes: 10)),
        status: TimedAccessStatus.active,
      );
      await repository.saveSession(activeSession);
      await controller.restoreSession(now);

      expect(controller.status, TimedAccessStatus.active);
      final extendOnActive = await controller.extendSession(const Duration(minutes: 5));
      expect(extendOnActive, isFalse);
      expect(mockNativeService.extendCount, 0);

      controller.onClose();
    });

    test('MethodChannel start failure rolls back repository cleanly without crashing', () async {
      mockNativeService.shouldFailStart = true;

      final controller = TimedAccessController(
        repository: repository,
        nativeService: mockNativeService,
        appLauncher: mockAppLauncher,
      );

      controller.selectedApp.value = const AppInfo(
        name: 'Instagram',
        packageName: 'com.instagram.android',
      );
      controller.selectPresetDuration(5);

      final session = await controller.startTimedAccess();

      // Must fail cleanly
      expect(session, isNull);
      expect(controller.status, TimedAccessStatus.none);
      expect(controller.hasActiveSession, isFalse);

      // Repository must have rolled back
      final persisted = await repository.getActiveSession();
      expect(persisted, isNull);

      controller.onClose();
    });

    test('MethodChannel takeMeOut failure tears down local session safely', () async {
      mockNativeService.shouldFailTerminate = true;

      final controller = TimedAccessController(
        repository: repository,
        nativeService: mockNativeService,
        appLauncher: mockAppLauncher,
      );

      final now = DateTime.now();
      final expiredSession = TimedAccessSession(
        id: 'session-term-fail',
        packageName: 'com.instagram.android',
        startedAt: now.subtract(const Duration(minutes: 10)),
        expiresAt: now.subtract(const Duration(seconds: 1)),
        status: TimedAccessStatus.expiredWaitingForDecision,
      );
      await repository.saveSession(expiredSession);
      await controller.restoreSession(now);

      // Even if native call fails, local session is torn down to prevent user being trapped
      await controller.takeMeOut();

      expect(controller.session, isNull);
      expect(controller.status, TimedAccessStatus.none);
      expect(await repository.getActiveSession(), isNull);

      controller.onClose();
    });
  });
}
