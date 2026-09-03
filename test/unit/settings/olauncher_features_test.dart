import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_launcher/features/apps/models/app_info.dart';
import 'package:minimal_launcher/features/settings/models/launcher_settings.dart';

void main() {
  group('Olauncher Features - LauncherSettings', () {
    test('defaults match Olauncher spec', () {
      const s = LauncherSettings();
      expect(s.homeAlignment, 'left');
      expect(s.homeBottomAlignment, false);
      expect(s.homeAppsCount, 4);
      expect(s.dateTimeVisibility, 'on');
      expect(s.showStatusBar, true);
      expect(s.boldFont, false);
      expect(s.autoShowKeyboard, true);
      expect(s.autoLaunchSingleMatch, true);
      expect(s.swipeDownAction, 'notifications');
      expect(s.swipeLeftPackage, isNull);
      expect(s.swipeRightPackage, isNull);
      expect(s.doubleTapToLock, false);
    });

    test('serialization round-trip preserves all Olauncher fields', () {
      const original = LauncherSettings(
        homeAlignment: 'center',
        homeBottomAlignment: true,
        homeAppsCount: 6,
        dateTimeVisibility: 'date_only',
        showStatusBar: false,
        boldFont: true,
        autoShowKeyboard: false,
        autoLaunchSingleMatch: false,
        swipeDownAction: 'search',
        swipeLeftPackage: 'com.custom.camera',
        swipeRightPackage: 'com.custom.phone',
        doubleTapToLock: true,
      );

      final map = original.toMap();
      final restored = LauncherSettings.fromMap(map);

      expect(restored.homeAlignment, 'center');
      expect(restored.homeBottomAlignment, true);
      expect(restored.homeAppsCount, 6);
      expect(restored.dateTimeVisibility, 'date_only');
      expect(restored.showStatusBar, false);
      expect(restored.boldFont, true);
      expect(restored.autoShowKeyboard, false);
      expect(restored.autoLaunchSingleMatch, false);
      expect(restored.swipeDownAction, 'search');
      expect(restored.swipeLeftPackage, 'com.custom.camera');
      expect(restored.swipeRightPackage, 'com.custom.phone');
      expect(restored.doubleTapToLock, true);
    });

    test('copyWith allows mutating and clearing fields', () {
      const base = LauncherSettings();
      final updated = base.copyWith(
        homeAlignment: 'right',
        homeAppsCount: 8,
        swipeLeftPackage: 'com.test.app',
      );

      expect(updated.homeAlignment, 'right');
      expect(updated.homeAppsCount, 8);
      expect(updated.swipeLeftPackage, 'com.test.app');

      final cleared = updated.copyWith(clearSwipeLeft: true);
      expect(cleared.swipeLeftPackage, isNull);
    });
  });

  group('Olauncher Features - AppInfo Recent Install Badge', () {
    test('isRecentInstall is true when installed within 24 hours', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final recentApp = AppInfo(
        name: 'New App',
        packageName: 'com.new.app',
        installTime: now - const Duration(hours: 2).inMilliseconds,
      );

      expect(recentApp.isRecentInstall, isTrue);
    });

    test('isRecentInstall is false when installed more than 24 hours ago', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final oldApp = AppInfo(
        name: 'Old App',
        packageName: 'com.old.app',
        installTime: now - const Duration(hours: 25).inMilliseconds,
      );

      expect(oldApp.isRecentInstall, isFalse);
    });

    test('isRecentInstall is false when installTime is 0 or negative', () {
      const unknownApp = AppInfo(
        name: 'Unknown App',
        packageName: 'com.unknown.app',
        installTime: 0,
      );

      expect(unknownApp.isRecentInstall, isFalse);
    });

    test('AppInfo serialization round-trip includes installTime', () {
      final app = AppInfo(
        name: 'Test App',
        packageName: 'com.test.app',
        isGame: true,
        category: 0,
        installTime: 123456789,
      );

      final restored = AppInfo.fromMap(app.toMap());
      expect(restored.installTime, 123456789);
      expect(restored.isGame, isTrue);
      expect(restored.category, 0);
    });
  });
}
