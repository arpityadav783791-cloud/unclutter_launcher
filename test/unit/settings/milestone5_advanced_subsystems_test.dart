import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/native_bridge.dart';
import 'package:minimal_launcher/core/services/storage_service.dart';
import 'package:minimal_launcher/features/apps/models/pinned_shortcut.dart';
import 'package:minimal_launcher/features/settings/controllers/settings_controller.dart';
import 'package:minimal_launcher/features/settings/models/launcher_settings.dart';
import 'package:minimal_launcher/features/settings/services/daily_wallpaper_service.dart';
import 'package:minimal_launcher/features/settings/services/settings_service.dart';
import '../../helpers/test_helpers.dart';

class FakeMilestone5NativeBridge extends GetxService implements NativeBridge {
  bool isEink = false;
  bool wallpaperCleared = false;
  bool privateSpaceAvailable = false;
  bool privateSpaceLocked = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> isEinkDevice() async => isEink;

  @override
  Future<bool> clearWallpaper() async {
    wallpaperCleared = true;
    return true;
  }

  @override
  Future<bool> isPrivateSpaceAvailable() async => privateSpaceAvailable;

  @override
  Future<bool> isPrivateSpaceLocked() async => privateSpaceLocked;

  @override
  Future<bool> togglePrivateSpace({bool requestUnlock = true}) async {
    privateSpaceLocked = !requestUnlock;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PinnedShortcut Model', () {
    test('constructs correctly and computes composite shortcutKey', () {
      const shortcut = PinnedShortcut(
        id: 'https://news.ycombinator.com',
        packageName: 'org.mozilla.fenix',
        label: 'Hacker News',
        userSerial: 0,
      );

      expect(shortcut.id, 'https://news.ycombinator.com');
      expect(shortcut.packageName, 'org.mozilla.fenix');
      expect(shortcut.label, 'Hacker News');
      expect(shortcut.shortcutKey,
          'shortcut:org.mozilla.fenix:https://news.ycombinator.com:0');
    });

    test('equality and hashCode differentiate shortcuts', () {
      const a = PinnedShortcut(
        id: 'id1',
        packageName: 'com.example',
        label: 'App 1',
        userSerial: 0,
      );
      const b = PinnedShortcut(
        id: 'id1',
        packageName: 'com.example',
        label: 'App 1',
        userSerial: 0,
      );
      const c = PinnedShortcut(
        id: 'id2',
        packageName: 'com.example',
        label: 'App 1',
        userSerial: 0,
      );
      const d = PinnedShortcut(
        id: 'id1',
        packageName: 'com.example',
        label: 'App 1',
        userSerial: 10,
      );

      expect(a == b, isTrue);
      expect(a.hashCode == b.hashCode, isTrue);
      expect(a == c, isFalse);
      expect(a == d, isFalse);
    });

    test('serialization round-trip', () {
      const original = PinnedShortcut(
        id: 'compose_email',
        packageName: 'com.google.android.gm',
        label: 'Compose',
        userSerial: 10,
        isEnabled: true,
      );

      final map = original.toMap();
      final restored = PinnedShortcut.fromMap(map);

      expect(restored.id, 'compose_email');
      expect(restored.packageName, 'com.google.android.gm');
      expect(restored.label, 'Compose');
      expect(restored.userSerial, 10);
      expect(restored.isEnabled, true);
      expect(restored, equals(original));
    });
  });

  group('DailyWallpaperService - Key Calculations', () {
    test('relative day key when daysSinceInstall is under 10', () {
      final installDate = DateTime(2026, 9, 1);

      // Day 0
      expect(
        DailyWallpaperService.calculateDayKey(
            DateTime(2026, 9, 1, 10, 0), installDate),
        '0_0',
      );
      // Day 3
      expect(
        DailyWallpaperService.calculateDayKey(
            DateTime(2026, 9, 4, 15, 30), installDate),
        '0_3',
      );
      // Day 9
      expect(
        DailyWallpaperService.calculateDayKey(
            DateTime(2026, 9, 10, 8, 0), installDate),
        '0_9',
      );
    });

    test('calendar date key when daysSinceInstall is >= 10', () {
      final installDate = DateTime(2026, 1, 1);
      final now = DateTime(2026, 9, 4);

      expect(
        DailyWallpaperService.calculateDayKey(now, installDate),
        '9_4',
      );
    });
  });

  group('LauncherSettings - Milestone 5 Extensions', () {
    test('defaults are auto for eInkMode and false for dailyWallpaper', () {
      const settings = LauncherSettings();
      expect(settings.eInkMode, 'auto');
      expect(settings.dailyWallpaperEnabled, false);
    });

    test('serialization preserves eInkMode and dailyWallpaperEnabled', () {
      const settings = LauncherSettings(
        eInkMode: 'on',
        dailyWallpaperEnabled: true,
      );

      final map = settings.toMap();
      final restored = LauncherSettings.fromMap(map);

      expect(restored.eInkMode, 'on');
      expect(restored.dailyWallpaperEnabled, true);
    });

    test('copyWith updates eInkMode and dailyWallpaperEnabled', () {
      const settings = LauncherSettings();
      final updated = settings.copyWith(
        eInkMode: 'off',
        dailyWallpaperEnabled: true,
      );

      expect(updated.eInkMode, 'off');
      expect(updated.dailyWallpaperEnabled, true);
    });
  });

  group('SettingsController - E-Ink Optimization', () {
    late FakeMilestone5NativeBridge fakeBridge;

    setUp(() async {
      Get.reset();
      await setupTestStorage();
      await Get.putAsync(() => StorageService().init());
      fakeBridge = FakeMilestone5NativeBridge();
      Get.put<NativeBridge>(fakeBridge);
      Get.put(SettingsService());
    });

    tearDown(() {
      Get.reset();
    });

    test('isEinkActive evaluates correctly based on eInkMode and hardware',
        () async {
      final controller = Get.put(SettingsController());

      // Default: auto, hardware: false -> not active
      expect(controller.isEinkActive, false);

      // Force ON -> active regardless of hardware
      await controller.setEInkMode('on');
      expect(controller.isEinkActive, true);

      // Force OFF -> inactive even if hardware is true
      fakeBridge.isEink = true;
      controller.isHardwareEink.value = true;
      await controller.setEInkMode('off');
      expect(controller.isEinkActive, false);

      // Auto with hardware true -> active
      await controller.setEInkMode('auto');
      expect(controller.isEinkActive, true);
    });

    test('flutterThemeMode forces ThemeMode.light when E-Ink is active',
        () async {
      final controller = Get.put(SettingsController());
      await controller.setThemeMode('dark');
      expect(controller.flutterThemeMode, ThemeMode.dark);

      // Activate E-Ink
      await controller.setEInkMode('on');
      expect(controller.isEinkActive, true);
      // E-Ink forces light theme for high-contrast e-paper readability
      expect(controller.flutterThemeMode, ThemeMode.light);
    });
  });
}
