import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/storage_service.dart';
import 'package:minimal_launcher/features/apps/models/app_info.dart';
import 'package:minimal_launcher/features/apps/services/app_config_service.dart';
import 'package:minimal_launcher/features/apps/services/distraction_detector.dart';
import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DistractionDetector Tests', () {
    test('Identifies social media apps by known package names', () {
      const ig = AppInfo(name: 'Instagram', packageName: 'com.instagram.android');
      const fb = AppInfo(name: 'Facebook', packageName: 'com.facebook.katana');
      const x = AppInfo(name: 'X', packageName: 'com.twitter.android');
      const snap = AppInfo(name: 'Snapchat', packageName: 'com.snapchat.android');
      const reddit = AppInfo(name: 'Reddit', packageName: 'com.reddit.frontpage');

      expect(DistractionDetector.isDistraction(ig), isTrue);
      expect(DistractionDetector.isDistraction(fb), isTrue);
      expect(DistractionDetector.isDistraction(x), isTrue);
      expect(DistractionDetector.isDistraction(snap), isTrue);
      expect(DistractionDetector.isDistraction(reddit), isTrue);
    });

    test('Identifies video streaming and entertainment apps', () {
      const yt = AppInfo(name: 'YouTube', packageName: 'com.google.android.youtube');
      const netflix = AppInfo(name: 'Netflix', packageName: 'com.netflix.mediaclient');
      const twitch = AppInfo(name: 'Twitch', packageName: 'tv.twitch.android.app');

      expect(DistractionDetector.isDistraction(yt), isTrue);
      expect(DistractionDetector.isDistraction(netflix), isTrue);
      expect(DistractionDetector.isDistraction(twitch), isTrue);
    });

    test('Identifies games by isGame flag, OS category, or package/name keywords', () {
      const gameByFlag = AppInfo(
        name: 'My Arcade',
        packageName: 'com.random.customapp',
        isGame: true,
      );
      const gameByCategory = AppInfo(
        name: 'Fun Racer',
        packageName: 'com.racer.game',
        category: 0, // CATEGORY_GAME
      );
      const candyCrush = AppInfo(
        name: 'Candy Crush',
        packageName: 'com.king.candycrushsaga',
      );
      const pubg = AppInfo(
        name: 'PUBG Mobile',
        packageName: 'com.pubg.imobile',
      );

      expect(DistractionDetector.isDistraction(gameByFlag), isTrue);
      expect(DistractionDetector.isDistraction(gameByCategory), isTrue);
      expect(DistractionDetector.isDistraction(candyCrush), isTrue);
      expect(DistractionDetector.isDistraction(pubg), isTrue);
    });

    test('Does not classify system or utility apps as distraction', () {
      const clock = AppInfo(
        name: 'Clock',
        packageName: 'com.google.android.deskclock',
      );
      const dialer = AppInfo(
        name: 'Phone',
        packageName: 'com.google.android.dialer',
      );
      const calc = AppInfo(
        name: 'Calculator',
        packageName: 'com.google.android.calculator',
      );
      const settings = AppInfo(
        name: 'Settings',
        packageName: 'com.android.settings',
        isSystemApp: true,
      );
      const notes = AppInfo(
        name: 'Minimal Notes',
        packageName: 'com.minimal.notes',
      );

      expect(DistractionDetector.isDistraction(clock), isFalse);
      expect(DistractionDetector.isDistraction(dialer), isFalse);
      expect(DistractionDetector.isDistraction(calc), isFalse);
      expect(DistractionDetector.isDistraction(settings), isFalse);
      expect(DistractionDetector.isDistraction(notes), isFalse);
    });
  });

  group('AppConfigService Auto-detection Tests', () {
    late StorageService storage;
    late AppConfigService configService;

    setUp(() async {
      Get.reset();
      await setupTestStorage();
      storage = StorageService();
      await storage.init();
      Get.put<StorageService>(storage);

      configService = AppConfigService();
      Get.put<AppConfigService>(configService);
    });

    tearDown(() {
      Get.reset();
    });

    test('autoDetectDistractions automatically configures social and game apps', () async {
      final apps = [
        const AppInfo(name: 'Instagram', packageName: 'com.instagram.android'),
        const AppInfo(name: 'Subway Surfers', packageName: 'com.kiloo.subwaysurf'),
        const AppInfo(name: 'Calculator', packageName: 'com.google.android.calculator'),
      ];

      final detected = await configService.autoDetectDistractions(apps);

      expect(detected, contains('com.instagram.android'));
      expect(detected, contains('com.kiloo.subwaysurf'));
      expect(detected, isNot(contains('com.google.android.calculator')));

      expect(configService.isDistraction('com.instagram.android'), isTrue);
      expect(configService.isDistraction('com.kiloo.subwaysurf'), isTrue);
      expect(configService.isDistraction('com.google.android.calculator'), isFalse);
    });

    test('autoDetectDistractions does not override explicit user preferences', () async {
      // User explicitly unchecks Instagram as distraction
      await configService.setDistraction('com.instagram.android', false, isUserAction: true);
      expect(configService.isDistraction('com.instagram.android'), isFalse);

      // New scan runs
      final apps = [
        const AppInfo(name: 'Instagram', packageName: 'com.instagram.android'),
      ];
      await configService.autoDetectDistractions(apps);

      // Should remain false because user explicitly configured it
      expect(configService.isDistraction('com.instagram.android'), isFalse);
    });
  });
}
