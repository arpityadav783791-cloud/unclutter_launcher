import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/native_bridge.dart';
import 'package:minimal_launcher/core/services/storage_service.dart';
import 'package:minimal_launcher/features/apps/models/app_info.dart';
import 'package:minimal_launcher/features/apps/services/app_config_service.dart';
import 'package:minimal_launcher/features/apps/services/native_app_service.dart';
import 'package:minimal_launcher/features/distraction_apps/services/distraction_app_service.dart';
import 'package:minimal_launcher/features/distraction_apps/services/distraction_classifier.dart';
import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('com.minimal.launcher/native');
  final List<String> launchedPackages = [];

  setUp(() async {
    Get.reset();
    launchedPackages.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'launchApp':
          launchedPackages.add(call.arguments['packageName'] as String);
          return true;
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
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    Get.reset();
  });

  group('Distraction Apps Classification & Management Tests', () {
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

    // 6. Normal apps launch without distraction classification
    test('6. Normal apps are not classified as distraction', () {
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

    // 7. Distraction apps classified properly
    test('7. Distraction apps classified properly by service', () {
      final distractionService = Get.find<DistractionAppService>();
      const instagram = AppInfo(
        name: 'Instagram',
        packageName: 'com.instagram.android',
        category: 4,
      );

      expect(distractionService.isDistraction(instagram.packageName, app: instagram), isTrue);
    });
  });
}
