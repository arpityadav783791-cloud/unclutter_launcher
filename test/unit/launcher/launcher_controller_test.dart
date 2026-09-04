import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/native_bridge.dart';
import 'package:minimal_launcher/features/launcher/controllers/launcher_controller.dart';
import 'package:minimal_launcher/features/screen_time/models/app_usage.dart';
import 'package:minimal_launcher/features/screen_time/services/usage_stats_service.dart';

class FakeUsageStatsService extends GetxService implements UsageStatsService {
  bool permission = true;
  List<AppUsage> today = [];

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> openUsageAccessSettings() async {}

  @override
  Future<List<AppUsage>> getTodayUsage() async => today;

  @override
  Future<List<AppUsage>> getWeeklyUsage() async => [];

  @override
  Future<SingleAppUsage> getAppUsage(String packageName) async {
    return SingleAppUsage(packageName: packageName, todayMs: 0, weekMs: 0);
  }
}

class FakeLauncherNativeBridge extends GetxService implements NativeBridge {
  int battery = 88;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<int> getBatteryLevel() async => battery;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LauncherController - Screen Time Formatting', () {
    test('formatScreenTime formats under a minute as <1m', () {
      expect(LauncherController.formatScreenTime(0), '<1m');
      expect(LauncherController.formatScreenTime(-100), '<1m');
      expect(LauncherController.formatScreenTime(30000), '<1m');
      expect(LauncherController.formatScreenTime(59999), '<1m');
    });

    test('formatScreenTime formats minutes only without hour', () {
      expect(LauncherController.formatScreenTime(60000), '1m');
      expect(LauncherController.formatScreenTime(120000), '2m');
      expect(LauncherController.formatScreenTime(45 * 60000), '45m');
    });

    test('formatScreenTime formats hours only when minutes are zero', () {
      expect(LauncherController.formatScreenTime(3600000), '1h');
      expect(LauncherController.formatScreenTime(2 * 3600000), '2h');
    });

    test('formatScreenTime formats hours and minutes', () {
      // 1h 24m = (60 + 24) * 60 * 1000 = 5040000
      expect(LauncherController.formatScreenTime(5040000), '1h 24m');
      // 3h 7m = (3 * 60 + 7) * 60 * 1000 = 11220000
      expect(LauncherController.formatScreenTime(11220000), '3h 7m');
    });
  });

  group('LauncherController - State and Lifecycle Updates', () {
    late FakeUsageStatsService fakeUsage;
    late FakeLauncherNativeBridge fakeNative;

    setUp(() {
      Get.reset();
      fakeUsage = FakeUsageStatsService();
      fakeNative = FakeLauncherNativeBridge();
      Get.put<UsageStatsService>(fakeUsage);
      Get.put<NativeBridge>(fakeNative);
    });

    tearDown(() {
      Get.reset();
    });

    test('updateScreenTime computes and formats total usage', () async {
      fakeUsage.today = [
        AppUsage(
          packageName: 'com.app.one',
          totalTimeInForegroundMs: 3600000, // 1h
          lastTimeUsed: 1000,
        ),
        AppUsage(
          packageName: 'com.app.two',
          totalTimeInForegroundMs: 1440000, // 24m
          lastTimeUsed: 2000,
        ),
      ];

      final controller = LauncherController();
      await controller.updateScreenTime();

      expect(controller.todayScreenTime.value, '1h 24m');
      controller.onClose();
    });

    test('updateScreenTime sets empty when permission is denied', () async {
      fakeUsage.permission = false;

      final controller = LauncherController();
      await controller.updateScreenTime();

      expect(controller.todayScreenTime.value, '');
      controller.onClose();
    });

    test('didChangeAppLifecycleState on resumed triggers updates', () async {
      fakeUsage.today = [
        AppUsage(
          packageName: 'com.app.one',
          totalTimeInForegroundMs: 120000, // 2m
          lastTimeUsed: 1000,
        ),
      ];

      final controller = LauncherController();
      await controller.updateScreenTime();
      expect(controller.todayScreenTime.value, '2m');

      fakeUsage.today = [
        AppUsage(
          packageName: 'com.app.one',
          totalTimeInForegroundMs: 300000, // 5m
          lastTimeUsed: 1000,
        ),
      ];
      fakeNative.battery = 75;

      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.todayScreenTime.value, '5m');
      expect(controller.batteryLevel.value, 75);
      controller.onClose();
    });
  });
}
