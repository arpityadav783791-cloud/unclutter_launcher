import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/native_bridge.dart';
import '../../apps/services/native_app_service.dart';
import '../../productivity/controllers/productivity_controller.dart';
import '../../settings/controllers/settings_controller.dart';

/// Single Responsibility: Handles gesture recognition and routing for the Home Screen.
class HomeGestureService extends GetxService {
  final SettingsController _settings = Get.find<SettingsController>();
  final NativeBridge _nativeBridge = Get.find<NativeBridge>();

  /// Handles vertical swipe down gesture on the Home Screen.
  Future<void> handleSwipeDown(BuildContext context) async {
    final action = _settings.swipeDownAction.value;
    HapticFeedback.lightImpact();

    if (action == 'notifications') {
      await _nativeBridge.expandStatusBar();
    } else if (action == 'search') {
      context.push(AppRoutes.search);
    }
  }

  /// Handles horizontal swipe left gesture on the Home Screen.
  Future<void> handleSwipeLeft() async {
    final pkg = _settings.swipeLeftPackage.value;
    HapticFeedback.lightImpact();

    if (pkg != null && pkg.isNotEmpty) {
      if (Get.isRegistered<ProductivityController>()) {
        await Get.find<ProductivityController>().handleAppLaunch(pkg);
      }
    } else {
      // Default: Camera
      await _launchDefaultCamera();
    }
  }

  /// Handles horizontal swipe right gesture on the Home Screen.
  Future<void> handleSwipeRight() async {
    final pkg = _settings.swipeRightPackage.value;
    HapticFeedback.lightImpact();

    if (pkg != null && pkg.isNotEmpty) {
      if (Get.isRegistered<ProductivityController>()) {
        await Get.find<ProductivityController>().handleAppLaunch(pkg);
      }
    } else {
      // Default: Phone / Dialer
      await _launchDefaultPhone();
    }
  }

  /// Handles double tap to lock screen.
  Future<void> handleDoubleTap() async {
    if (!_settings.doubleTapToLock.value) return;
    HapticFeedback.mediumImpact();
    await _nativeBridge.lockScreen();
  }

  Future<void> _launchDefaultCamera() async {
    if (!Get.isRegistered<NativeAppService>()) return;
    final nativeApps = Get.find<NativeAppService>();

    final knownCameras = [
      'com.android.camera',
      'com.google.android.GoogleCamera',
      'com.sec.android.app.camera',
      'com.oneplus.camera',
      'com.oppo.camera',
      'com.motorola.camera2',
    ];

    for (final pkg in knownCameras) {
      if (await nativeApps.isAppInstalled(pkg)) {
        await nativeApps.launchApp(pkg);
        return;
      }
    }
  }

  Future<void> _launchDefaultPhone() async {
    if (!Get.isRegistered<NativeAppService>()) return;
    final nativeApps = Get.find<NativeAppService>();

    final knownDialers = [
      'com.google.android.dialer',
      'com.android.dialer',
      'com.samsung.android.dialer',
      'com.oneplus.dialer',
      'com.coloros.dialer',
    ];

    for (final pkg in knownDialers) {
      if (await nativeApps.isAppInstalled(pkg)) {
        await nativeApps.launchApp(pkg);
        return;
      }
    }
  }
}
