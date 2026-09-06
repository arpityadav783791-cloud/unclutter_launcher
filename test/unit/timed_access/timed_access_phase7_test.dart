import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/native_bridge.dart';
import 'package:minimal_launcher/core/services/storage_service.dart';
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
  Future<void> showExpiryDialog({
    required String sessionId,
    required String packageName,
  }) async {}

  @override
  Future<void> clearSession({required String sessionId}) async {
    lastClearedSessionId = sessionId;
  }

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
  String? terminatedSessionId;
  List<String>? setPackages;

  @override
  Future<bool> terminateTimedSession({required String sessionId}) async {
    terminatedSessionId = sessionId;
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

  group('Phase 7: Background, Lifecycle & Persistence Hardening', () {
    test('Background -> Foreground recalculates countdown strictly using expiresAt', () async {
      final controller = TimedAccessController(
        repository: repository,
        nativeService: mockNativeService,
        appLauncher: mockAppLauncher,
      );

      final now = DateTime.now();
      // Active session where 4 minutes have already elapsed in background
      final session = TimedAccessSession(
        id: 'session-bg-1',
        packageName: 'com.instagram.android',
        startedAt: now.subtract(const Duration(minutes: 4)),
        expiresAt: now.add(const Duration(minutes: 6)),
        status: TimedAccessStatus.active,
      );

      await repository.saveSession(session);
      await controller.restoreSession();

      expect(controller.status, TimedAccessStatus.active);
      expect(controller.remainingDuration.value.inSeconds, inInclusiveRange(350, 360));

      // Simulate app resuming from background
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(controller.status, TimedAccessStatus.active);
      expect(controller.remainingDuration.value.inSeconds, inInclusiveRange(350, 360));

      // Simulate returning after expiry has passed
      final pastSession = session.copyWith(
        expiresAt: DateTime.now().subtract(const Duration(seconds: 5)),
      );
      controller.setSession(pastSession);
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

      // Must transition to expiredWaitingForDecision, never ACTIVE
      expect(controller.status, TimedAccessStatus.expiredWaitingForDecision);
      expect(controller.remainingDuration.value, Duration.zero);

      controller.onClose();
    });

    test('Restoring valid session restores ACTIVE with same sessionId and resumes countdown', () async {
      final now = DateTime.now();
      final initialSession = TimedAccessSession(
        id: 'stable-session-id',
        packageName: 'com.google.android.youtube',
        startedAt: now,
        expiresAt: now.add(const Duration(minutes: 8)),
        status: TimedAccessStatus.active,
      );

      await repository.saveSession(initialSession);

      final controller = TimedAccessController(
        repository: repository,
        nativeService: mockNativeService,
        appLauncher: mockAppLauncher,
      );

      await controller.restoreSession(now);

      expect(controller.session?.id, 'stable-session-id');
      expect(controller.session?.packageName, 'com.google.android.youtube');
      expect(controller.status, TimedAccessStatus.active);
      expect(mockNativeService.lastStartedSessionId, 'stable-session-id');
      expect(controller.remainingDuration.value.inSeconds, inInclusiveRange(470, 480));

      controller.onClose();
    });

    test('Restoring expired session transitions to EXPIRED_WAITING_FOR_DECISION and never ACTIVE', () async {
      final now = DateTime.now();
      final expiredSession = TimedAccessSession(
        id: 'expired-session-id',
        packageName: 'com.reddit.frontpage',
        startedAt: now.subtract(const Duration(minutes: 15)),
        expiresAt: now.subtract(const Duration(minutes: 5)),
        status: TimedAccessStatus.active,
      );

      await repository.saveSession(expiredSession);

      final controller = TimedAccessController(
        repository: repository,
        nativeService: mockNativeService,
        appLauncher: mockAppLauncher,
      );

      await controller.restoreSession(now);

      // Must transition to expiredWaitingForDecision, not active
      expect(controller.status, TimedAccessStatus.expiredWaitingForDecision);
      expect(controller.remainingDuration.value, Duration.zero);
      // Native monitoring should NOT have started for expired session
      expect(mockNativeService.lastStartedSessionId, isNull);

      controller.onClose();
    });

    test('Corrupt or malformed persisted session safely recovers to NONE', () async {
      // Write malformed JSON into the storage key
      await storageService.setString('active_timed_access_session', '{invalid_json');

      final controller = TimedAccessController(
        repository: repository,
        nativeService: mockNativeService,
        appLauncher: mockAppLauncher,
      );

      await controller.restoreSession();

      expect(controller.session, isNull);
      expect(controller.status, TimedAccessStatus.none);
      expect(controller.remainingDuration.value, Duration.zero);

      // Verifies corrupt data was safely cleared
      final after = await repository.getActiveSession();
      expect(after, isNull);

      controller.onClose();
    });

    test('Stale alarm callback for replaced session is rejected', () async {
      final controller = TimedAccessController(
        repository: repository,
        nativeService: mockNativeService,
        appLauncher: mockAppLauncher,
      );

      final now = DateTime.now();
      final activeSession = TimedAccessSession(
        id: 'session-current',
        packageName: 'com.twitter.android',
        startedAt: now,
        expiresAt: now.add(const Duration(minutes: 10)),
        status: TimedAccessStatus.active,
      );
      await repository.saveSession(activeSession);
      await controller.restoreSession(now);

      expect(controller.session?.id, 'session-current');
      expect(controller.status, TimedAccessStatus.active);

      // Stale callback arrives for previous session 'session-old'
      mockNativeBridge.onTimedAccessExpired?.call('session-old', 'com.twitter.android');

      // Current session must remain ACTIVE and untouched
      expect(controller.session?.id, 'session-current');
      expect(controller.status, TimedAccessStatus.active);
      expect(controller.remainingDuration.value.inSeconds, inInclusiveRange(590, 600));

      controller.onClose();
    });

    test('Session extension preserves sessionId, updates expiresAt, and reschedules native monitoring', () async {
      final controller = TimedAccessController(
        repository: repository,
        nativeService: mockNativeService,
        appLauncher: mockAppLauncher,
      );

      final now = DateTime.now();
      final expiredSession = TimedAccessSession(
        id: 'session-ext-1',
        packageName: 'com.snapchat.android',
        startedAt: now.subtract(const Duration(minutes: 10)),
        expiresAt: now.subtract(const Duration(seconds: 5)),
        status: TimedAccessStatus.expiredWaitingForDecision,
      );
      await repository.saveSession(expiredSession);
      await controller.restoreSession(now);

      expect(controller.status, TimedAccessStatus.expiredWaitingForDecision);

      final extended = await controller.extendSession(const Duration(minutes: 5));
      expect(extended, isTrue);

      // Must preserve the exact same sessionId
      expect(controller.session?.id, 'session-ext-1');
      expect(controller.status, TimedAccessStatus.active);
      expect(mockNativeService.lastExtendedSessionId, 'session-ext-1');

      // Persisted session must have new expiresAt
      final persisted = await repository.getActiveSession();
      expect(persisted?.id, 'session-ext-1');
      expect(persisted?.expiresAt.isAfter(now), isTrue);

      controller.onClose();
    });

    test('Concurrency protection prevents restoreSession while startTimedAccess is running', () async {
      final controller = TimedAccessController(
        repository: repository,
        nativeService: mockNativeService,
        appLauncher: mockAppLauncher,
      );

      controller.isStarting.value = true;
      final now = DateTime.now();
      final session = TimedAccessSession(
        id: 'session-concurrent',
        packageName: 'com.concurrent.app',
        startedAt: now,
        expiresAt: now.add(const Duration(minutes: 5)),
        status: TimedAccessStatus.active,
      );
      await repository.saveSession(session);

      // restoreSession should abort early because isStarting is true
      await controller.restoreSession(now);
      expect(controller.session, isNull);

      controller.isStarting.value = false;
      controller.onClose();
    });
  });
}
