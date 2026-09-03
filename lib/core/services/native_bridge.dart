import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Bridge between Flutter and Android native code.
/// All launcher-specific Android operations go through this service.
class NativeBridge extends GetxService {
  static const MethodChannel _channel =
      MethodChannel('com.minimal.launcher/native');

  void Function(String packageName)? onSessionExpired;
  void Function()? onRecoveryTriggered;

  @override
  void onInit() {
    super.onInit();
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onSessionExpired') {
      final args = call.arguments as Map<dynamic, dynamic>?;
      final packageName = args?['packageName'] as String? ?? '';
      onSessionExpired?.call(packageName);
      return true;
    }
    if (call.method == 'onRecoveryTriggered') {
      onRecoveryTriggered?.call();
      return true;
    }
    return null;
  }

  /// Returns true if this app is currently the default home launcher
  Future<bool> isDefaultLauncher() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDefaultLauncher');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system screen where the user can choose the default launcher
  Future<void> openDefaultLauncherSettings() async {
    try {
      await _channel.invokeMethod('openDefaultLauncherSettings');
    } on PlatformException {
      // Silently ignore – user can still go to settings manually
    }
  }

  /// Starts a native monitoring timer for a timed distraction session
  Future<void> startTimedSession({
    required String packageName,
    required int durationSeconds,
  }) async {
    try {
      await _channel.invokeMethod('startTimedSession', {
        'packageName': packageName,
        'durationSeconds': durationSeconds,
      });
    } on PlatformException catch (e) {
      Get.log('NativeBridge.startTimedSession error: ${e.message}');
    }
  }

  /// Cancels any active native timed session
  Future<void> cancelTimedSession() async {
    try {
      await _channel.invokeMethod('cancelTimedSession');
    } on PlatformException catch (e) {
      Get.log('NativeBridge.cancelTimedSession error: ${e.message}');
    }
  }

  /// Brings the launcher activity back to the foreground
  Future<void> returnToLauncher() async {
    try {
      await _channel.invokeMethod('returnToLauncher');
    } on PlatformException catch (e) {
      Get.log('NativeBridge.returnToLauncher error: ${e.message}');
    }
  }

  // ── Protected Mode ──────────────────────────────────────────

  /// Checks if the app is active as Android Device Owner
  Future<bool> isDeviceOwner() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDeviceOwner');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Checks if Protected Mode is currently active
  Future<bool> isProtectedModeEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isProtectedModeEnabled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Enables Device-Owner-based Protected Mode
  Future<bool> enableProtectedMode() async {
    try {
      final result = await _channel.invokeMethod<bool>('enableProtectedMode');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Disables Protected Mode during recovery
  Future<bool> disableProtectedMode() async {
    try {
      final result = await _channel.invokeMethod<bool>('disableProtectedMode');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Fetches complete protected mode state map from Android native
  Future<Map<String, dynamic>> getProtectedModeState() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getProtectedModeState');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return {};
    } on PlatformException {
      return {};
    }
  }

  /// Requests setting this app as the default launcher
  Future<void> requestDefaultLauncher() async {
    try {
      await _channel.invokeMethod('requestDefaultLauncher');
    } on PlatformException {
      // ignore
    }
  }

  // ── Permissions ─────────────────────────────────────────────

  /// Checks if Usage Access permission is granted
  Future<bool> hasUsagePermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasUsagePermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system Usage Access settings screen
  Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } on PlatformException {
      // ignore
    }
  }

  /// Checks whether notification permission is currently granted
  Future<bool> hasNotificationPermission() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('hasNotificationPermission');
      return result ?? true;
    } on PlatformException {
      return true;
    }
  }

  /// Requests notification permission on platforms where required
  Future<bool> requestNotificationPermission() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('requestNotificationPermission');
      return result ?? true;
    } on PlatformException {
      return true;
    }
  }

  /// Returns true if the device runtime requires explicit notification permission (Android 13+)
  Future<bool> isNotificationPermissionRequired() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('isNotificationPermissionRequired');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens notification settings for this application
  Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } on PlatformException {
      // ignore
    }
  }

  /// Checks if enforcement permission is satisfied
  Future<bool> hasEnforcementPermission() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('hasEnforcementPermission');
      return result ?? true;
    } on PlatformException {
      return true;
    }
  }

  /// Returns whether this device architecture requires additional enforcement permission
  Future<bool> isEnforcementPermissionRequired() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('isEnforcementPermissionRequired');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens enforcement settings screen if applicable
  Future<void> openEnforcementSettings() async {
    try {
      await _channel.invokeMethod('openEnforcementSettings');
    } on PlatformException {
      // ignore
    }
  }

  /// Expands notifications drawer / status bar
  Future<void> expandStatusBar() async {
    try {
      await _channel.invokeMethod('expandStatusBar');
    } on PlatformException {
      // ignore
    }
  }

  /// Opens application details in system settings
  Future<bool> openAppDetails(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>('openAppDetails', {
        'packageName': packageName,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Prompts system uninstaller for the application
  Future<bool> uninstallApp(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>('uninstallApp', {
        'packageName': packageName,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens default or system clock / alarm app
  Future<bool> openClock() async {
    try {
      final result = await _channel.invokeMethod<bool>('openClock');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens default or system calendar app
  Future<bool> openCalendar() async {
    try {
      final result = await _channel.invokeMethod<bool>('openCalendar');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Queries device battery level percentage (-1 if unknown)
  Future<int> getBatteryLevel() async {
    try {
      final result = await _channel.invokeMethod<int>('getBatteryLevel');
      return result ?? -1;
    } on PlatformException {
      return -1;
    }
  }

  /// Opens device web search or browser with query
  Future<void> openWebSearch(String query) async {
    try {
      await _channel.invokeMethod('openWebSearch', {'query': query});
    } on PlatformException {
      // ignore
    }
  }

  /// Locks device screen
  Future<bool> lockScreen() async {
    try {
      final result = await _channel.invokeMethod<bool>('lockScreen');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
