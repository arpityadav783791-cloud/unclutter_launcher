import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/native_bridge.dart';
import 'package:minimal_launcher/core/services/storage_service.dart';
import 'package:minimal_launcher/features/apps/services/native_app_service.dart';
import 'package:minimal_launcher/features/launcher/services/home_gesture_service.dart';
import 'package:minimal_launcher/features/productivity/controllers/productivity_controller.dart';
import 'package:minimal_launcher/features/settings/controllers/settings_controller.dart';
import 'package:minimal_launcher/features/settings/services/settings_service.dart';
import '../../helpers/test_helpers.dart';

class FakeGestureNativeBridge extends GetxService implements NativeBridge {
  bool expandStatusBarCalled = false;
  bool lockScreenCalled = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> expandStatusBar() async {
    expandStatusBarCalled = true;
  }

  @override
  Future<bool> lockScreen() async {
    lockScreenCalled = true;
    return true;
  }

  @override
  Future<bool> isAccessibilityServiceEnabled() async => true;
}

class FakeProductivityController extends GetxController implements ProductivityController {
  String? lastLaunchedPackage;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> handleAppLaunch(
    String packageName, {
    int userSerial = 0,
    String? activityName,
    BuildContext? context,
  }) async {
    lastLaunchedPackage = packageName;
    return true;
  }
}

class FakeNativeAppService extends GetxService implements NativeAppService {
  String? lastLaunchedPackage;
  final Set<String> installed = {'com.android.camera', 'com.google.android.dialer'};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> isAppInstalled(String packageName) async => installed.contains(packageName);

  @override
  Future<bool> launchApp(String packageName, {int? userSerial, String? activityName}) async {
    lastLaunchedPackage = packageName;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeGestureService - Part 3 Navigation & Shortcuts', () {
    late FakeGestureNativeBridge fakeBridge;
    late FakeProductivityController fakeProd;
    late FakeNativeAppService fakeNativeApps;
    late SettingsController settings;
    late HomeGestureService gestureService;

    setUp(() async {
      Get.reset();
      await setupTestStorage();
      await Get.putAsync(() => StorageService().init());
      Get.put<SettingsService>(SettingsService());
      settings = Get.put<SettingsController>(SettingsController());
      fakeBridge = FakeGestureNativeBridge();
      fakeProd = FakeProductivityController();
      fakeNativeApps = FakeNativeAppService();

      Get.put<NativeBridge>(fakeBridge);
      Get.put<ProductivityController>(fakeProd);
      Get.put<NativeAppService>(fakeNativeApps);
      gestureService = Get.put<HomeGestureService>(HomeGestureService());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('handleSwipeDown expands status bar when configured for notifications', (tester) async {
      await settings.setSwipeDownAction('notifications');
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            gestureService.handleSwipeDown(context);
            return const Placeholder();
          },
        ),
      );
      expect(fakeBridge.expandStatusBarCalled, isTrue);
    });

    test('handleSwipeLeft launches user defined package or falls back to camera', () async {
      // Fallback camera
      await gestureService.handleSwipeLeft();
      expect(fakeNativeApps.lastLaunchedPackage, 'com.android.camera');

      // Custom app
      await settings.setSwipeLeftPackage('com.custom.app');
      await gestureService.handleSwipeLeft();
      expect(fakeProd.lastLaunchedPackage, 'com.custom.app');
    });

    test('handleSwipeRight launches user defined package or falls back to phone', () async {
      // Fallback phone
      await gestureService.handleSwipeRight();
      expect(fakeNativeApps.lastLaunchedPackage, 'com.google.android.dialer');

      // Custom app
      await settings.setSwipeRightPackage('com.custom.phoneapp');
      await gestureService.handleSwipeRight();
      expect(fakeProd.lastLaunchedPackage, 'com.custom.phoneapp');
    });

    test('handleDoubleTap locks screen when enabled and skips when disabled', () async {
      expect(settings.doubleTapToLock.value, isFalse);
      await gestureService.handleDoubleTap();
      expect(fakeBridge.lockScreenCalled, isFalse);

      await settings.toggleDoubleTapToLock();
      expect(settings.doubleTapToLock.value, isTrue);
      await gestureService.handleDoubleTap();
      expect(fakeBridge.lockScreenCalled, isTrue);
    });
  });
}
