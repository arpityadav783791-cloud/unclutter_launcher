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
}
