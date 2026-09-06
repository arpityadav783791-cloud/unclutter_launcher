import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/storage_service.dart';
import 'package:minimal_launcher/features/apps/models/app_info.dart';
import 'package:minimal_launcher/features/timed_access/controllers/timed_access_controller.dart';
import 'package:minimal_launcher/features/timed_access/data/models/timed_access_session_model.dart';
import 'package:minimal_launcher/features/timed_access/data/repositories/timed_access_repository_impl.dart';
import 'package:minimal_launcher/features/timed_access/domain/entities/timed_access_session.dart';
import 'package:minimal_launcher/features/timed_access/domain/entities/timed_access_status.dart';
import 'package:minimal_launcher/features/timed_access/widgets/timed_access_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimedAccessSession Entity & Model', () {
    test('TimedAccessSession.create creates valid active session with future expiry', () {
      final now = DateTime(2026, 9, 5, 12, 0);
      final session = TimedAccessSession.create(
        packageName: 'com.google.android.youtube',
        duration: const Duration(minutes: 15),
        now: now,
      );

      expect(session.packageName, 'com.google.android.youtube');
      expect(session.status, TimedAccessStatus.active);
      expect(session.startedAt, now);
      expect(session.expiresAt, now.add(const Duration(minutes: 15)));
      expect(session.id, contains('com.google.android.youtube'));
    });

    test('TimedAccessSessionModel serialization round-trip', () {
      final now = DateTime.now();
      final session = TimedAccessSession(
        id: 'test_session_1',
        packageName: 'com.instagram.android',
        startedAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
        status: TimedAccessStatus.active,
      );

      final model = TimedAccessSessionModel.fromEntity(session);
      final map = model.toMap();
      final restored = TimedAccessSessionModel.fromMap(map);

      expect(restored.id, session.id);
      expect(restored.packageName, session.packageName);
      expect(restored.status, session.status);
      expect(
        restored.startedAt.millisecondsSinceEpoch ~/ 1000,
        session.startedAt.millisecondsSinceEpoch ~/ 1000,
      );
      expect(
        restored.expiresAt.millisecondsSinceEpoch ~/ 1000,
        session.expiresAt.millisecondsSinceEpoch ~/ 1000,
      );
    });
  });

  group('TimedAccessRepositoryImpl', () {
    late StorageService storageService;
    late TimedAccessRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      storageService = await StorageService().init();
      Get.put<StorageService>(storageService);
      repository = TimedAccessRepositoryImpl(storageService: storageService);
    });

    test('saveSession, getActiveSession, and clearSession work correctly', () async {
      expect(await repository.getActiveSession(), isNull);

      final session = TimedAccessSession.create(
        packageName: 'com.twitter.android',
        duration: const Duration(minutes: 10),
      );

      await repository.saveSession(session);

      final fetched = await repository.getActiveSession();
      expect(fetched, isNotNull);
      expect(fetched!.packageName, 'com.twitter.android');
      expect(fetched.status, TimedAccessStatus.active);

      await repository.clearSession();
      expect(await repository.getActiveSession(), isNull);
    });
  });

  group('TimedAccessController', () {
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

    test('default state has 5 minutes selected and no active session', () {
      expect(controller.selectedDurationMinutes.value, 5);
      expect(controller.isCustom.value, isFalse);
      expect(controller.hasActiveSession, isFalse);
      expect(controller.status, TimedAccessStatus.none);
    });

    test('selectPresetDuration updates duration for valid presets only', () {
      controller.selectPresetDuration(15);
      expect(controller.selectedDurationMinutes.value, 15);
      expect(controller.isCustom.value, isFalse);

      controller.selectPresetDuration(30);
      expect(controller.selectedDurationMinutes.value, 30);

      // Invalid preset ignored
      controller.selectPresetDuration(99);
      expect(controller.selectedDurationMinutes.value, 30);
    });

    test('setCustomDuration validates bounds (1 to 120 minutes)', () {
      expect(controller.setCustomDuration(0), isFalse);
      expect(controller.setCustomDuration(-5), isFalse);
      expect(controller.setCustomDuration(121), isFalse);

      expect(controller.setCustomDuration(45), isTrue);
      expect(controller.isCustom.value, isTrue);
      expect(controller.customDurationMinutes.value, 45);
      expect(controller.effectiveDurationMinutes, 45);
    });

    test('startTimedAccess creates and persists session when app is selected', () async {
      const app = AppInfo(name: 'YouTube', packageName: 'com.google.android.youtube');
      controller.selectedApp.value = app;
      controller.selectPresetDuration(10);

      final session = await controller.startTimedAccess();

      expect(session, isNotNull);
      expect(session!.packageName, 'com.google.android.youtube');
      expect(controller.session, equals(session));
      expect(controller.hasActiveSession, isTrue);

      // Verify persisted in repository
      final persisted = await repository.getActiveSession();
      expect(persisted, isNotNull);
      expect(persisted!.packageName, 'com.google.android.youtube');
    });

    test('startTimedAccess returns null if no app is selected', () async {
      controller.selectedApp.value = null;
      final session = await controller.startTimedAccess();
      expect(session, isNull);
    });

    test('handleDistractionLaunch returns true when active session already exists for package', () async {
      const app = AppInfo(name: 'YouTube', packageName: 'com.google.android.youtube');
      controller.selectedApp.value = app;
      await controller.startTimedAccess();
      expect(controller.hasActiveSession, isTrue);

      final allowed = await controller.handleDistractionLaunch(app: app);
      expect(allowed, isTrue);
    });

    test('handleDistractionLaunch returns false when no active session exists', () async {
      const app = AppInfo(name: 'YouTube', packageName: 'com.google.android.youtube');
      final allowed = await controller.handleDistractionLaunch(app: app);
      expect(allowed, isFalse);
    });

    test('startSessionAndLaunch creates session and launches app', () async {
      const app = AppInfo(name: 'YouTube', packageName: 'com.google.android.youtube');
      final session = await controller.startSessionAndLaunch(
        app: app,
        durationMinutes: 15,
      );
      expect(session, isNotNull);
      expect(session!.packageName, 'com.google.android.youtube');
      expect(controller.hasActiveSession, isTrue);
      expect(controller.effectiveDurationMinutes, 15);
    });
  });

  group('TimedAccessBottomSheet Widget', () {
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

    testWidgets('renders presets and selects duration', (tester) async {
      const app = AppInfo(name: 'Instagram', packageName: 'com.instagram.android');
      controller.selectedApp.value = app;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: TimedAccessBottomSheet(app: app),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Timed Access'), findsOneWidget);
      expect(find.text('How long do you need?'), findsOneWidget);
      expect(find.text('5 m'), findsOneWidget);
      expect(find.text('10 m'), findsOneWidget);
      expect(find.text('15 m'), findsOneWidget);
      expect(find.text('30 m'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Selected: 5 minutes'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);

      // Tap 15 m preset
      await tester.tap(find.text('15 m'));
      await tester.pumpAndSettle();

      expect(find.text('Selected: 15 minutes'), findsOneWidget);
      expect(controller.effectiveDurationMinutes, 15);

      // Tap Start
      await tester.tap(find.text('Start'));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(controller.hasActiveSession, isTrue);
      expect(controller.session!.packageName, 'com.instagram.android');

      controller.onClose();
    });
  });
}
