import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/storage_service.dart';
import 'package:minimal_launcher/features/apps/models/app_info.dart';
import 'package:minimal_launcher/features/timed_access/controllers/timed_access_controller.dart';
import 'package:minimal_launcher/features/timed_access/data/repositories/timed_access_repository_impl.dart';
import 'package:minimal_launcher/features/timed_access/domain/entities/timed_access_session.dart';
import 'package:minimal_launcher/features/timed_access/domain/entities/timed_access_status.dart';
import 'package:minimal_launcher/features/timed_access/services/app_launcher.dart';
import 'package:minimal_launcher/features/timed_access/services/timed_access_native_service.dart';
import 'package:minimal_launcher/features/timed_access/widgets/timed_access_expiry_dialog.dart';
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
  bool startShouldFail = false;

  @override
  Future<void> startSession({
    required String sessionId,
    required String packageName,
    required DateTime expiresAt,
  }) async {
    if (startShouldFail) {
      throw Exception('Native monitoring registration failed');
    }
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
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 5: Expiry DialogBox & User Decision Flow', () {
    late StorageService storageService;
    late TimedAccessRepositoryImpl repository;
    late MockTimedAccessNativeService mockNativeService;
    late MockAppLauncher mockAppLauncher;
    late TimedAccessController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
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

    test('expiry transition triggers showExpiryDialog and sets isExpiryDialogVisible', () async {
      const app = AppInfo(name: 'YouTube', packageName: 'com.google.android.youtube');
      controller.selectedApp.value = app;
      controller.selectPresetDuration(5);

      final session = await controller.startTimedAccess();
      expect(session, isNotNull);
      expect(controller.status, TimedAccessStatus.active);
      expect(controller.isExpiryDialogVisible.value, isFalse);

      // Simulate expiry reached
      final expiredTime = session!.expiresAt.add(const Duration(seconds: 1));
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

      // Trigger expiry explicitly to simulate timer tick
      controller.restoreSession(expiredTime);
      await pumpEventQueue();

      expect(controller.status, TimedAccessStatus.expiredWaitingForDecision);
      expect(controller.isExpiryDialogVisible.value, isTrue);
    });

    test('duplicate expiry protection prevents multiple dialogs from stacking', () async {
      final initialSession = TimedAccessSession(
        id: 'session_duplicate_test',
        packageName: 'com.google.android.youtube',
        startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
        status: TimedAccessStatus.expiredWaitingForDecision,
      );
      await repository.saveSession(initialSession);
      controller.setSession(initialSession);

      // First trigger
      controller.showExpiryDialog();
      expect(controller.isExpiryDialogVisible.value, isTrue);

      // Second trigger (duplicate native or timer callback)
      controller.showExpiryDialog();
      expect(controller.isExpiryDialogVisible.value, isTrue);
    });

    test('Extend Flow recalculates expiresAt from now, preserves sessionId, and resumes countdown', () async {
      const testSessionId = 'session_extend_test_123';
      final expiredSession = TimedAccessSession(
        id: testSessionId,
        packageName: 'com.google.android.youtube',
        startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
        status: TimedAccessStatus.expiredWaitingForDecision,
      );
      await repository.saveSession(expiredSession);
      controller.setSession(expiredSession);
      controller.isExpiryDialogVisible.value = true;

      final beforeExtend = DateTime.now();
      final success = await controller.extendSession(const Duration(minutes: 10));

      expect(success, isTrue);
      expect(controller.status, TimedAccessStatus.active);
      expect(controller.hasActiveSession, isTrue);

      // Verify same sessionId preserved
      final currentSession = controller.session!;
      expect(currentSession.id, equals(testSessionId));
      expect(currentSession.packageName, equals('com.google.android.youtube'));

      // Verify expiresAt calculated from now (NOT old expired timestamp)
      final expectedMinExpiry = beforeExtend.add(const Duration(minutes: 9, seconds: 58));
      final expectedMaxExpiry = DateTime.now().add(const Duration(minutes: 10, seconds: 2));
      expect(currentSession.expiresAt.isAfter(expectedMinExpiry), isTrue);
      expect(currentSession.expiresAt.isBefore(expectedMaxExpiry), isTrue);

      // Verify native monitoring was updated for SAME sessionId
      expect(mockNativeService.lastExtendedSessionId, equals(testSessionId));
      expect(mockNativeService.lastStartedSessionId, equals(testSessionId));

      // Verify persisted in repository
      final persisted = await repository.getActiveSession();
      expect(persisted, isNotNull);
      expect(persisted!.id, equals(testSessionId));
      expect(persisted.status, TimedAccessStatus.active);

      // Verify dialog is closed
      expect(controller.isExpiryDialogVisible.value, isFalse);
    });

    test('Take Me Out of Here clears session and stops native monitoring without closing app', () async {
      const testSessionId = 'session_take_me_out_999';
      final expiredSession = TimedAccessSession(
        id: testSessionId,
        packageName: 'com.google.android.youtube',
        startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        status: TimedAccessStatus.expiredWaitingForDecision,
      );
      await repository.saveSession(expiredSession);
      controller.setSession(expiredSession);
      controller.isExpiryDialogVisible.value = true;

      await controller.takeMeOut();

      // Verify state becomes NONE
      expect(controller.status, TimedAccessStatus.none);
      expect(controller.session, isNull);
      expect(controller.hasActiveSession, isFalse);
      expect(controller.remainingDuration.value, Duration.zero);

      // Verify cleared from repository
      final persisted = await repository.getActiveSession();
      expect(persisted, isNull);

      // Verify native monitoring stopped
      expect(mockNativeService.lastClearedSessionId, equals(testSessionId));

      // Verify dialog dismissed
      expect(controller.isExpiryDialogVisible.value, isFalse);
    });

    test('Session restoration with expired timestamp transitions to expiredWaitingForDecision and triggers dialog', () async {
      final pastSession = TimedAccessSession(
        id: 'session_restored_expired',
        packageName: 'com.instagram.android',
        startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 10)),
        status: TimedAccessStatus.active,
      );
      await repository.saveSession(pastSession);

      await controller.restoreSession();

      expect(controller.status, TimedAccessStatus.expiredWaitingForDecision);
      expect(controller.isExpiryDialogVisible.value, isTrue);
    });

    testWidgets('TimedAccessExpiryDialog renders UI elements, selects extension and triggers Take Me Out', (tester) async {
      final testSession = TimedAccessSession(
        id: 'session_widget_test',
        packageName: 'com.google.android.youtube',
        startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        status: TimedAccessStatus.expiredWaitingForDecision,
      );
      controller.setSession(testSession);
      controller.selectedApp.value = const AppInfo(name: 'YouTube', packageName: 'com.google.android.youtube');

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: TimedAccessExpiryDialog(session: testSession),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & subtitle
      expect(find.text('Timed Access Ended'), findsOneWidget);
      expect(find.text('Time limit reached for YouTube.'), findsOneWidget);
      expect(find.text('Need more time?'), findsOneWidget);

      // Verify presets
      expect(find.text('5 m'), findsOneWidget);
      expect(find.text('10 m'), findsOneWidget);
      expect(find.text('15 m'), findsOneWidget);
      expect(find.text('30 m'), findsOneWidget);

      // Default selected is 5 min
      expect(find.text('Extend 5 min'), findsOneWidget);
      expect(find.text('Take Me Out of Here'), findsOneWidget);

      // Tap 15 m preset
      await tester.tap(find.text('15 m'));
      await tester.pumpAndSettle();

      expect(controller.selectedExtensionMinutes.value, 15);
      expect(find.text('Extend 15 min'), findsOneWidget);

      // Verify PopScope has canPop == false
      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);

      // Tap Take Me Out of Here
      await tester.tap(find.text('Take Me Out of Here'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.status, TimedAccessStatus.none);
    });
  });
}
