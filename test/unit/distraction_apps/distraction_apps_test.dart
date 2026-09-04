import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/native_bridge.dart';
import 'package:minimal_launcher/core/services/storage_service.dart';
import 'package:minimal_launcher/features/apps/models/app_info.dart';
import 'package:minimal_launcher/features/apps/services/app_config_service.dart';
import 'package:minimal_launcher/features/apps/services/native_app_service.dart';
import 'package:minimal_launcher/features/distraction_apps/services/distraction_app_service.dart';
import 'package:minimal_launcher/features/distraction_apps/services/distraction_classifier.dart';
import 'package:minimal_launcher/features/timed_access/controllers/timed_access_controller.dart';
import 'package:minimal_launcher/features/timed_access/models/timed_app_session.dart';
import 'package:minimal_launcher/features/timed_access/services/timed_access_service.dart';
import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('com.minimal.launcher/native');
  final List<String> launchedPackages = [];
  final List<Map<String, dynamic>> timedSessionCalls = [];
  int cancelCalls = 0;
  int returnToLauncherCalls = 0;

  setUp(() async {
    Get.reset();
    launchedPackages.clear();
    timedSessionCalls.clear();
    cancelCalls = 0;
    returnToLauncherCalls = 0;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'launchApp':
          launchedPackages.add(call.arguments['packageName'] as String);
          return true;
        case 'startTimedSession':
          timedSessionCalls
              .add(Map<String, dynamic>.from(call.arguments as Map));
          return null;
        case 'cancelTimedSession':
          cancelCalls++;
          return null;
        case 'returnToLauncher':
          returnToLauncherCalls++;
          return null;
        default:
          return null;
      }
    });

    await setupTestStorage();
    await Get.putAsync(() => StorageService().init());
    Get.put(NativeBridge());
    Get.put(NativeAppService());
    Get.put(AppConfigService());
    Get.put(DistractionAppService());
    Get.put(TimedAccessService());
    Get.put(TimedAccessController());
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    Get.reset();
  });

  group('Requirement 23 Tests - Timed Distraction App Access', () {
    // 1. Automatic social-media detection
    test('1. Automatic social-media detection', () {
      const instagram = AppInfo(
        name: 'Instagram',
        packageName: 'com.instagram.android',
        category: 4, // CATEGORY_SOCIAL
      );
      const tiktok = AppInfo(
        name: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
      );
      const reddit = AppInfo(
        name: 'Reddit',
        packageName: 'com.reddit.frontpage',
        category: 4,
      );

      expect(DistractionClassifier.isDistraction(instagram), isTrue);
      expect(DistractionClassifier.isDistraction(tiktok), isTrue);
      expect(DistractionClassifier.isDistraction(reddit), isTrue);
      expect(DistractionClassifier.getCategoryLabel(instagram), 'Social Media');
    });

    // 2. Automatic game detection
    test('2. Automatic game detection', () {
      const pubg = AppInfo(
        name: 'PUBG MOBILE',
        packageName: 'com.pubg.imobile',
        isGame: true,
      );
      const candyCrush = AppInfo(
        name: 'Candy Crush',
        packageName: 'com.king.candycrushsaga',
        category: 0, // CATEGORY_GAME
      );
      const genericGame = AppInfo(
        name: 'Retro Arcade Game',
        packageName: 'com.example.retrogame',
      );

      expect(DistractionClassifier.isDistraction(pubg), isTrue);
      expect(DistractionClassifier.isDistraction(candyCrush), isTrue);
      expect(DistractionClassifier.isDistraction(genericGame), isTrue);
      expect(DistractionClassifier.getCategoryLabel(pubg), 'Games');
    });

    // 3. User disabling an automatically detected app
    test('3. User disabling an automatically detected app', () async {
      final distractionService = Get.find<DistractionAppService>();
      const instagram = AppInfo(
        name: 'Instagram',
        packageName: 'com.instagram.android',
        category: 4,
      );

      await distractionService.autoDetectDistractions([instagram]);
      expect(distractionService.isDistraction(instagram.packageName), isTrue);

      // User disables Instagram
      await distractionService.toggleDistraction(instagram.packageName,
          enable: false);
      expect(distractionService.isDistraction(instagram.packageName), isFalse);
      expect(distractionService.settings.excludedPackages,
          contains(instagram.packageName));
    });

    // 4. User manually adding an app
    test('4. User manually adding an app', () async {
      final distractionService = Get.find<DistractionAppService>();
      const customApp = AppInfo(
        name: 'Work Chat',
        packageName: 'com.custom.workchat',
      );

      // Not detected automatically
      expect(DistractionClassifier.isDistraction(customApp), isFalse);

      // User manually adds it
      await distractionService.addManualDistraction(customApp.packageName);
      expect(distractionService.isDistraction(customApp.packageName), isTrue);
      expect(distractionService.settings.manuallyAddedPackages,
          contains(customApp.packageName));
    });

    // 5. User override persistence
    test('5. User override persistence', () async {
      final distractionService = Get.find<DistractionAppService>();
      await distractionService.toggleDistraction('com.instagram.android',
          enable: false);
      await distractionService.addManualDistraction('com.custom.news');

      // Create a fresh service instance reading from storage
      final reloaded = DistractionAppService();
      reloaded.onInit();

      expect(reloaded.isDistraction('com.instagram.android'), isFalse);
      expect(reloaded.isDistraction('com.custom.news'), isTrue);
    });

    // 6. 5-minute session
    test('6. 5-minute session creation and launch', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(name: 'Instagram', packageName: 'com.instagram.android');

      final success = await controller.startSessionAndLaunch(
        app: app,
        displayName: 'Instagram',
        durationMinutes: 5,
      );

      expect(success, isTrue);
      expect(controller.currentSession.value, isNotNull);
      expect(controller.currentSession.value!.durationMinutes, 5);
      expect(timedSessionCalls, isNotEmpty);
      expect(timedSessionCalls.first['durationSeconds'], 300);
      expect(launchedPackages, contains('com.instagram.android'));
    });

    // 7. 10-minute session
    test('7. 10-minute session creation and launch', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(name: 'YouTube', packageName: 'com.google.android.youtube');

      final success = await controller.startSessionAndLaunch(
        app: app,
        displayName: 'YouTube',
        durationMinutes: 10,
      );

      expect(success, isTrue);
      expect(controller.currentSession.value!.durationMinutes, 10);
      expect(timedSessionCalls.first['durationSeconds'], 600);
    });

    // 8. 15-minute session
    test('8. 15-minute session creation and launch', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(name: 'Reddit', packageName: 'com.reddit.frontpage');

      final success = await controller.startSessionAndLaunch(
        app: app,
        displayName: 'Reddit',
        durationMinutes: 15,
      );

      expect(success, isTrue);
      expect(controller.currentSession.value!.durationMinutes, 15);
      expect(timedSessionCalls.first['durationSeconds'], 900);
    });

    // 9. Custom session
    test('9. Custom session creation (e.g. 25 min)', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(name: 'PUBG', packageName: 'com.pubg.imobile');

      final success = await controller.startSessionAndLaunch(
        app: app,
        displayName: 'PUBG',
        durationMinutes: 25,
      );

      expect(success, isTrue);
      expect(controller.currentSession.value!.durationMinutes, 25);
      expect(timedSessionCalls.first['durationSeconds'], 1500);
    });

    // 10. Custom >60 minutes rejected / clamped
    test('10. Custom >60 minutes rejected / clamped to max 60', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(name: 'Game', packageName: 'com.game.test');

      await controller.startSessionAndLaunch(
        app: app,
        displayName: 'Game',
        durationMinutes: 999, // exceeds 60 min limit
      );

      expect(controller.currentSession.value!.durationMinutes, 60);
      expect(timedSessionCalls.first['durationSeconds'], 3600);
    });

    // 11. Active session restoration
    test('11. Active session restoration on restart', () async {
      final service = Get.find<TimedAccessService>();
      await service.startSession(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        durationMinutes: 20,
      );

      // Create new service representing launcher cold start
      final reloadedService = TimedAccessService();
      reloadedService.onInit();

      expect(reloadedService.hasActiveSession, isTrue);
      expect(reloadedService.activeSession!.packageName, 'com.instagram.android');
      expect(reloadedService.activeSession!.durationMinutes, 20);
    });

    // 12. Reopening during active session
    test('12. Reopening during active session allows immediate access without re-prompt', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(name: 'Instagram', packageName: 'com.instagram.android');

      await controller.startSessionAndLaunch(
        app: app,
        displayName: 'Instagram',
        durationMinutes: 15,
      );

      // Checking session validity for reopening
      expect(controller.hasActiveSessionFor(app.packageName), isTrue);
    });

    // 13. Expired session detection
    test('13. Expired session detection', () {
      final pastStart = DateTime.now().subtract(const Duration(minutes: 20));
      final expiredSession = TimedAppSession(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        startedAt: pastStart,
        expiresAt: pastStart.add(const Duration(minutes: 15)),
        durationMinutes: 15,
      );

      expect(expiredSession.isExpired, isTrue);
      expect(expiredSession.remainingSeconds, 0);
      expect(expiredSession.remainingDuration, Duration.zero);
    });

    // 14. Requesting additional time creates a fresh new session
    test('14. Requesting additional time creates a fresh new session', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(name: 'Instagram', packageName: 'com.instagram.android');

      await controller.startSessionAndLaunch(
        app: app,
        displayName: 'Instagram',
        durationMinutes: 15,
      );

      // Simulate expiration
      controller.handleSessionExpired(expiredPackage: app.packageName);
      expect(controller.currentSession.value, isNull);
      expect(controller.isExpired.value, isTrue);

      // Request additional time: 10 minutes
      await controller.startSessionAndLaunch(
        app: app,
        displayName: 'Instagram',
        durationMinutes: 10,
      );

      expect(controller.currentSession.value, isNotNull);
      expect(controller.currentSession.value!.durationMinutes, 10);
      expect(controller.isExpired.value, isFalse);
    });

    // 15. Cancel/Done after expiration
    test('15. Cancel/Done after expiration resets session and state', () async {
      final controller = Get.find<TimedAccessController>();
      controller.handleSessionExpired(expiredPackage: 'com.instagram.android');

      expect(controller.isExpired.value, isTrue);
      controller.dismissExpiredSession();

      expect(controller.isExpired.value, isFalse);
      expect(controller.currentSession.value, isNull);
    });

    // 16. Normal apps launch without timer
    test('16. Normal apps launch without timer', () {
      const calculator = AppInfo(
        name: 'Calculator',
        packageName: 'com.google.android.calculator',
      );
      const calendar = AppInfo(
        name: 'Calendar',
        packageName: 'com.google.android.calendar',
      );

      expect(DistractionClassifier.isDistraction(calculator), isFalse);
      expect(DistractionClassifier.isDistraction(calendar), isFalse);
    });

    // 17. Distraction apps trigger timer
    test('17. Distraction apps trigger timer', () {
      final distractionService = Get.find<DistractionAppService>();
      const instagram = AppInfo(
        name: 'Instagram',
        packageName: 'com.instagram.android',
        category: 4,
      );

      expect(distractionService.isDistraction(instagram.packageName, app: instagram), isTrue);
    });

    // 18. Timer remains correct after lifecycle changes
    test('18. Timer remains correct after lifecycle changes using timestamps', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(name: 'Instagram', packageName: 'com.instagram.android');

      await controller.startSessionAndLaunch(
        app: app,
        displayName: 'Instagram',
        durationMinutes: 10,
      );

      // Simulate app resumed lifecycle
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(controller.currentSession.value, isNotNull);
      expect(controller.remainingSeconds.value, inInclusiveRange(590, 600));
    });

    // 19. Target app is restricted after expiration
    test('19. Target app is restricted after expiration', () {
      final controller = Get.find<TimedAccessController>();
      controller.handleSessionExpired(expiredPackage: 'com.instagram.android');

      expect(controller.hasActiveSessionFor('com.instagram.android'), isFalse);
      expect(cancelCalls, greaterThan(0));
    });

    // 20. App returns to Unclutter after expiration
    test('20. App returns to Unclutter after expiration', () {
      final controller = Get.find<TimedAccessController>();
      controller.handleSessionExpired(expiredPackage: 'com.instagram.android');

      expect(returnToLauncherCalls, greaterThan(0));
    });
  });
}
