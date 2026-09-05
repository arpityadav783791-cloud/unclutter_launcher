import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../features/apps/models/pinned_shortcut.dart';

/// Bridge between Flutter and Android native code.
/// All launcher-specific Android operations go through this service.
class NativeBridge extends GetxService {
  static const MethodChannel _channel =
      MethodChannel('com.minimal.launcher/native');

  void Function()? onRecoveryTriggered;
  void Function(String packageName, String action)? onPackagesChanged;
  void Function()? onHomePressed;

  @override
  void onInit() {
    super.onInit();
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onHomePressed') {
      onHomePressed?.call();
      return true;
    }
    if (call.method == 'onRecoveryTriggered') {
      onRecoveryTriggered?.call();
      return true;
    }
    if (call.method == 'onPackagesChanged') {
      final args = call.arguments as Map<dynamic, dynamic>?;
      final packageName = args?['packageName'] as String? ?? '';
      final action = args?['action'] as String? ?? '';
      onPackagesChanged?.call(packageName, action);
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

  /// Checks whether accessibility service is currently enabled
  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens system Accessibility settings screen
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException {
      // ignore
    }
  }

  /// Checks whether overlay permission or accessibility service is enabled to draw the timer
  Future<bool> hasOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasOverlayPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Requests overlay permission or opens accessibility settings
  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } on PlatformException {
      // ignore
    }
  }

  /// Opens default Digital Wellbeing or custom assigned screen time application
  Future<bool> openScreenTimeApp({String? customPackage}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'openScreenTimeApp',
        {'customPackage': customPackage},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ── E-Ink Subsystem ─────────────────────────────────────────

  /// Detects whether current device is an E-Ink hardware display
  Future<bool> isEinkDevice() async {
    try {
      final result = await _channel.invokeMethod<bool>('isEinkDevice');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ── Pinned Shortcuts Subsystem ──────────────────────────────

  /// Queries all pinned shortcuts across profiles
  Future<List<PinnedShortcut>> getPinnedShortcuts() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getPinnedShortcuts');
      if (result == null) return [];
      return result
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => PinnedShortcut.fromMap(m))
          .toList();
    } on PlatformException {
      return [];
    }
  }

  /// Launches an Android pinned shortcut
  Future<bool> launchShortcut({
    required String packageName,
    required String shortcutId,
    int? userSerial,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'launchShortcut',
        {
          'packageName': packageName,
          'shortcutId': shortcutId,
          'userSerial': userSerial,
        },
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Unpins / removes an Android pinned shortcut
  Future<bool> unpinShortcut({
    required String packageName,
    required String shortcutId,
    int? userSerial,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'unpinShortcut',
        {
          'packageName': packageName,
          'shortcutId': shortcutId,
          'userSerial': userSerial,
        },
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ── Daily Curated Wallpaper Subsystem ───────────────────────

  /// Sets device wallpaper for system, lock, or both
  /// [which]: 1 = system, 2 = lock, 3 = both
  Future<bool> setWallpaper(Uint8List bytes, {int which = 1}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'setWallpaper',
        {
          'bytes': bytes,
          'which': which,
        },
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Clears wallpaper back to default / black minimalist background
  Future<bool> clearWallpaper() async {
    try {
      final result = await _channel.invokeMethod<bool>('clearWallpaper');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Sets pure black wallpaper for distraction-free minimalist experience
  Future<bool> setBlackWallpaper() async {
    try {
      final result = await _channel.invokeMethod<bool>('setBlackWallpaper');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ── Android 15+ Private Space Subsystem ─────────────────────

  /// Checks if a Private Space profile exists on Android 15+ (API 35+)
  Future<bool> isPrivateSpaceAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isPrivateSpaceAvailable');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Checks if Private Space is currently locked (quiet mode active)
  Future<bool> isPrivateSpaceLocked() async {
    try {
      final result = await _channel.invokeMethod<bool>('isPrivateSpaceLocked');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Requests locking or unlocking Private Space (prompts biometric/PIN)
  Future<bool> togglePrivateSpace({bool requestUnlock = true}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'togglePrivateSpace',
        {'requestUnlock': requestUnlock},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens native Android device settings (Settings app)
  Future<bool> openDeviceSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('openDeviceSettings');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
