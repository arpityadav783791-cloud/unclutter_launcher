import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/native_bridge.dart';
import 'package:minimal_launcher/core/services/storage_service.dart';
import 'package:minimal_launcher/features/apps/models/app_info.dart';
import 'package:minimal_launcher/features/apps/services/app_config_service.dart';
import 'package:minimal_launcher/features/apps/services/native_app_service.dart';
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
          timedSessionCalls.add(Map<String, dynamic>.from(call.arguments as Map));
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
    Get.put(TimedAccessService());
    Get.put(TimedAccessController());
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    Get.reset();
  });

  group('Distraction App Identification', () {
    test('normal app is not distraction by default', () {
      final configService = Get.find<AppConfigService>();
      expect(configService.isDistraction('com.android.calculator'), isFalse);
    });

    test('app can be configured as distraction and toggled', () async {
      final configService = Get.find<AppConfigService>();
      const pkg = 'com.instagram.android';

      expect(configService.isDistraction(pkg), isFalse);

      await configService.setDistraction(pkg, true);
      expect(configService.isDistraction(pkg), isTrue);
      expect(configService.distractionPackageNames, contains(pkg));

      await configService.toggleDistraction(pkg);
      expect(configService.isDistraction(pkg), isFalse);
      expect(configService.distractionPackageNames, isNot(contains(pkg)));
    });
  });

  group('TimedAccessController Session Creation', () {
    test('5-minute selection starts session and launches target app', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(packageName: 'com.instagram.android', name: 'Instagram');

      final success = await controller.startSessionAndLaunch(
        app: app,
        displayName: 'Instagram',
        durationMinutes: 5,
      );

      expect(success, isTrue);
      expect(launchedPackages, contains('com.instagram.android'));
      expect(controller.currentSession.value, isNotNull);
      expect(controller.currentSession.value!.durationMinutes, 5);
      expect(controller.currentSession.value!.isExpired, isFalse);
      expect(timedSessionCalls.length, 1);
      expect(timedSessionCalls.first['packageName'], 'com.instagram.android');
      expect(timedSessionCalls.first['durationSeconds'], greaterThan(290));
    });

    test('10-minute selection', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(packageName: 'com.google.android.youtube', name: 'YouTube');

      final success = await controller.startSessionAndLaunch(
        app: app,
        displayName: 'YouTube',
        durationMinutes: 10,
      );

      expect(success, isTrue);
      expect(controller.currentSession.value!.durationMinutes, 10);
      expect(controller.remainingSeconds.value, greaterThan(590));
    });

    test('15-minute selection', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(packageName: 'com.facebook.katana', name: 'Facebook');

      final success = await controller.startSessionAndLaunch(
        app: app,
        displayName: 'Facebook',
        durationMinutes: 15,
      );

      expect(success, isTrue);
      expect(controller.currentSession.value!.durationMinutes, 15);
      expect(controller.remainingSeconds.value, greaterThan(890));
    });

    test('custom duration (e.g. 25 minutes)', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(packageName: 'com.reddit.frontpage', name: 'Reddit');

      final success = await controller.startSessionAndLaunch(
        app: app,
        displayName: 'Reddit',
        durationMinutes: 25,
      );

      expect(success, isTrue);
      expect(controller.currentSession.value!.durationMinutes, 25);
    });

    test('custom duration > 60 minutes is clamped to maximum 60 minutes', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(packageName: 'com.test.game', name: 'Game');

      final success = await controller.startSessionAndLaunch(
        app: app,
        displayName: 'Game',
        durationMinutes: 120, // greater than 60
      );

      expect(success, isTrue);
      expect(controller.currentSession.value!.durationMinutes, 60);
    });

    test('custom duration < 1 minute is clamped to minimum 1 minute', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(packageName: 'com.test.app', name: 'App');

      final success = await controller.startSessionAndLaunch(
        app: app,
        displayName: 'App',
        durationMinutes: 0,
      );

      expect(success, isTrue);
      expect(controller.currentSession.value!.durationMinutes, 1);
    });
  });

  group('Active Session & Multiple Launches', () {
    test('hasActiveSessionFor is true while session is active', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(packageName: 'com.instagram.android', name: 'Instagram');

      expect(controller.hasActiveSessionFor(app.packageName), isFalse);

      await controller.startSessionAndLaunch(
        app: app,
        displayName: 'Instagram',
        durationMinutes: 10,
      );

      expect(controller.hasActiveSessionFor(app.packageName), isTrue);
      expect(controller.hasActiveSessionFor('com.other.app'), isFalse);
    });
  });

  group('Session Expiration & Return to Launcher', () {
    test('handleSessionExpired clears session and invokes native enforcement', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(packageName: 'com.instagram.android', name: 'Instagram');

      await controller.startSessionAndLaunch(
        app: app,
        displayName: 'Instagram',
        durationMinutes: 5,
      );

      expect(controller.currentSession.value, isNotNull);

      // Simulate expiration
      controller.handleSessionExpired(expiredPackage: 'com.instagram.android');

      expect(controller.currentSession.value, isNull);
      expect(controller.isExpired.value, isTrue);
      expect(controller.remainingSeconds.value, 0);
      expect(returnToLauncherCalls, greaterThanOrEqualTo(1));
      expect(cancelCalls, greaterThanOrEqualTo(1));
    });

    test('extending an expired session restarts session with new duration', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(packageName: 'com.instagram.android', name: 'Instagram');

      await controller.startSessionAndLaunch(
        app: app,
        displayName: 'Instagram',
        durationMinutes: 5,
      );

      controller.handleSessionExpired(expiredPackage: 'com.instagram.android');
      expect(controller.isExpired.value, isTrue);

      // Extend for 10 minutes
      final success = await controller.startSessionAndLaunch(
        app: app,
        displayName: 'Instagram',
        durationMinutes: 10,
      );

      expect(success, isTrue);
      expect(controller.currentSession.value!.durationMinutes, 10);
      expect(controller.isExpired.value, isFalse);
      expect(controller.remainingSeconds.value, greaterThan(590));
    });

    test('cancelling a session clears state and native timer', () async {
      final controller = Get.find<TimedAccessController>();
      const app = AppInfo(packageName: 'com.instagram.android', name: 'Instagram');

      await controller.startSessionAndLaunch(
        app: app,
        displayName: 'Instagram',
        durationMinutes: 5,
      );

      await controller.cancelSession();

      expect(controller.currentSession.value, isNull);
      expect(controller.remainingSeconds.value, 0);
      expect(controller.isExpired.value, isFalse);
      expect(cancelCalls, greaterThanOrEqualTo(1));
    });
  });

  group('Lifecycle and Timestamp-based Resume Behavior', () {
    test('recalculateRemainingTime on resume detects expired session', () async {
      final controller = Get.find<TimedAccessController>();

      // Create an expired session directly in service
      final past = DateTime.now().subtract(const Duration(minutes: 1));
      final expiredSession = TimedAppSession(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        startedAt: past.subtract(const Duration(minutes: 10)),
        expiresAt: past,
        durationMinutes: 10,
      );
      controller.currentSession.value = expiredSession;

      // Trigger resume
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(controller.currentSession.value, isNull);
      expect(controller.isExpired.value, isTrue);
      expect(returnToLauncherCalls, greaterThanOrEqualTo(1));
    });

    test('recalculateRemainingTime on resume updates remaining time accurately', () async {
      final controller = Get.find<TimedAccessController>();

      final now = DateTime.now();
      final future = now.add(const Duration(minutes: 4, seconds: 30));
      final session = TimedAppSession(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        startedAt: now.subtract(const Duration(minutes: 5, seconds: 30)),
        expiresAt: future,
        durationMinutes: 10,
      );
      controller.currentSession.value = session;

      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(controller.currentSession.value, isNotNull);
      expect(controller.isExpired.value, isFalse);
      expect(controller.remainingSeconds.value, inInclusiveRange(260, 275));
    });
  });
}
