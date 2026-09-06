import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/native_bridge.dart';
import 'package:minimal_launcher/core/services/storage_service.dart';
import 'package:minimal_launcher/features/apps/services/app_config_service.dart';
import 'package:minimal_launcher/features/distraction_apps/services/distraction_app_service.dart';
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
  String? lastStartedSessionId;
  String? lastStartedPackageName;
  DateTime? lastStartedExpiresAt;

  String? lastExtendedSessionId;
  DateTime? lastExtendedExpiresAt;

  String? lastClearedSessionId;
  String? lastTerminatedSessionId;
  String? lastTerminatedPackageName;

  @override
  Future<void> startSession({
    required String sessionId,
    required String packageName,
    required DateTime expiresAt,
  }) async {
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
    lastExtendedSessionId = sessionId;
    lastExtendedExpiresAt = expiresAt;
    await startSession(
      sessionId: sessionId,
      packageName: packageName,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> clearSession({required String sessionId}) async {
    lastClearedSessionId = sessionId;
  }

  @override
  Future<void> showExpiryDialog({
    required String sessionId,
    required String packageName,
  }) async {}

  @override
  Future<void> takeMeOut({
    required String sessionId,
    required String packageName,
  }) async {
    lastTerminatedSessionId = sessionId;
    lastTerminatedPackageName = packageName;
  }
}

class MockNativeBridge extends NativeBridge {
  List<String>? lastSetDistractionPackages;
  String? lastTerminatedSessionId;

  @override
  Future<void> setDistractionPackages(List<String> packages) async {
    lastSetDistractionPackages = packages;
  }

  @override
  Future<bool> terminateTimedSession({required String sessionId}) async {
    lastTerminatedSessionId = sessionId;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 6: Android Enforcement + Take Me Out of Here', () {
    late StorageService storageService;
    late TimedAccessRepositoryImpl repository;
    late MockTimedAccessNativeService mockNativeService;
    late MockAppLauncher mockAppLauncher;
    late MockNativeBridge mockNativeBridge;
    late TimedAccessController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      storageService = await StorageService().init();
      Get.put<StorageService>(storageService);
      repository = TimedAccessRepositoryImpl(storageService: storageService);
      mockNativeService = MockTimedAccessNativeService();
      mockAppLauncher = MockAppLauncher();
      mockNativeBridge = MockNativeBridge();
      Get.put<NativeBridge>(mockNativeBridge);

      final appConfigService = AppConfigService();
      Get.put<AppConfigService>(appConfigService);
      final distractionAppService = DistractionAppService();
      Get.put<DistractionAppService>(distractionAppService);

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

    test('Take Me Out of Here invokes native authoritative termination sequence and clears session', () async {
      const sessionId = 'session_take_me_out_p6';
      const packageName = 'com.google.android.youtube';

      final activeSession = TimedAccessSession(
        id: sessionId,
        packageName: packageName,
        startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        expiresAt: DateTime.now().subtract(const Duration(seconds: 10)),
        status: TimedAccessStatus.expiredWaitingForDecision,
      );
      await repository.saveSession(activeSession);
      controller.setSession(activeSession);
      controller.isExpiryDialogVisible.value = true;

      await controller.takeMeOut();

      // Verify native termination sequence was invoked with exact sessionId & packageName
      expect(mockNativeService.lastTerminatedSessionId, equals(sessionId));
      expect(mockNativeService.lastTerminatedPackageName, equals(packageName));
      expect(mockNativeService.lastClearedSessionId, equals(sessionId));

      // Verify session cleared from repository
      final persisted = await repository.getActiveSession();
      expect(persisted, isNull);

      // Verify controller state is NONE
      expect(controller.status, TimedAccessStatus.none);
      expect(controller.session, isNull);
      expect(controller.hasActiveSession, isFalse);
      expect(controller.remainingDuration.value, Duration.zero);

      // Verify dialog dismissed
      expect(controller.isExpiryDialogVisible.value, isFalse);
    });

    test('Stale native session termination callback ignores mismatched session ID', () async {
      const currentSessionId = 'session_current_active';
      final currentSession = TimedAccessSession(
        id: currentSessionId,
        packageName: 'com.instagram.android',
        startedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        status: TimedAccessStatus.active,
      );
      await repository.saveSession(currentSession);
      controller.setSession(currentSession);

      // Simulate stale callback from old session
      mockNativeBridge.onSessionTerminated?.call('old_session_123', 'com.instagram.android');

      // Verify current active session was NOT terminated
      expect(controller.hasActiveSession, isTrue);
      expect(controller.session?.id, equals(currentSessionId));
    });

    test('Native session termination callback terminates matching active session', () async {
      const currentSessionId = 'session_current_terminate';
      final currentSession = TimedAccessSession(
        id: currentSessionId,
        packageName: 'com.google.android.youtube',
        startedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        status: TimedAccessStatus.active,
      );
      await repository.saveSession(currentSession);
      controller.setSession(currentSession);

      // Callback matching current session ID arrives from native
      mockNativeBridge.onSessionTerminated?.call(currentSessionId, 'com.google.android.youtube');

      expect(controller.status, TimedAccessStatus.none);
      expect(controller.session, isNull);
      expect(controller.remainingDuration.value, Duration.zero);
    });

    test('Interception of distraction app without valid session sets selectedApp for Timed Access flow', () async {
      const packageName = 'com.google.android.youtube';

      // Verify no active session
      expect(controller.hasActiveSession, isFalse);

      // Simulate accessibility interception callback from native
      mockNativeBridge.onDistractionIntercepted?.call(packageName);

      expect(controller.selectedApp.value, isNotNull);
      expect(controller.selectedApp.value!.packageName, equals(packageName));
    });

    test('Interception callback for currently active session is ignored', () async {
      const packageName = 'com.google.android.youtube';
      final activeSession = TimedAccessSession(
        id: 'session_active_allow',
        packageName: packageName,
        startedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        status: TimedAccessStatus.active,
      );
      await repository.saveSession(activeSession);
      controller.setSession(activeSession);

      controller.selectedApp.value = null;

      // Accessibility event arrives while session is active
      mockNativeBridge.onDistractionIntercepted?.call(packageName);

      // Should not re-set selectedApp or re-prompt
      expect(controller.selectedApp.value, isNull);
    });

    test('Distraction packages sync with native bridge on startup', () async {
      await controller.syncDistractionPackages();
      expect(mockNativeBridge.lastSetDistractionPackages, isNotNull);
    });
  });
}
