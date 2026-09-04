import 'package:get/get.dart';
import 'native_bridge.dart';

/// Centralized permission service managing Android runtime and special permissions.
/// Avoids scattering platform-specific permission logic throughout UI widgets.
class PermissionService extends GetxService {
  final NativeBridge _nativeBridge = Get.find<NativeBridge>();

  /// Checks if Usage Access permission is granted
  Future<bool> checkUsageAccess() async {
    return await _nativeBridge.hasUsagePermission();
  }

  /// Opens the system Usage Access settings screen
  Future<void> openUsageAccessSettings() async {
    await _nativeBridge.openUsageAccessSettings();
  }

  /// Checks if notification permission is granted
  Future<bool> checkNotificationPermission() async {
    return await _nativeBridge.hasNotificationPermission();
  }

  /// Requests notification permission on platforms where required
  Future<bool> requestNotificationPermission() async {
    return await _nativeBridge.requestNotificationPermission();
  }

  /// Returns true if notification permission is required by the Android version (Android 13+)
  Future<bool> isNotificationPermissionRequired() async {
    return await _nativeBridge.isNotificationPermissionRequired();
  }

  /// Opens the application notification settings
  Future<void> openNotificationSettings() async {
    await _nativeBridge.openNotificationSettings();
  }

  /// Checks whether Minimalist is the active default home launcher
  Future<bool> isDefaultLauncher() async {
    final isHome = await _nativeBridge.isDefaultLauncher();
    if (isHome) {
      try {
        await _nativeBridge.setBlackWallpaper();
      } catch (_) {}
    }
    return isHome;
  }

  /// Opens the Android default launcher chooser / home settings
  Future<void> openDefaultLauncherSettings() async {
    await _nativeBridge.openDefaultLauncherSettings();
  }

  /// Checks if enforcement permission is satisfied
  Future<bool> checkEnforcementPermission() async {
    return await _nativeBridge.hasEnforcementPermission();
  }

  /// Returns whether this device/architecture requires an extra enforcement permission
  Future<bool> isEnforcementPermissionRequired() async {
    return await _nativeBridge.isEnforcementPermissionRequired();
  }

  /// Opens enforcement settings screen if applicable
  Future<void> openEnforcementSettings() async {
    await _nativeBridge.openEnforcementSettings();
  }

  /// Checks if the app is active as Android Device Owner
  Future<bool> isDeviceOwner() async {
    return await _nativeBridge.isDeviceOwner();
  }

  /// Enables Device Owner protection
  Future<bool> enableProtection() async {
    return await _nativeBridge.enableProtectedMode();
  }

  /// Checks if Accessibility Service is enabled (used for Double Tap to Lock)
  Future<bool> checkAccessibilityPermission() async {
    return await _nativeBridge.isAccessibilityServiceEnabled();
  }

  /// Opens the system Accessibility settings screen
  Future<void> openAccessibilitySettings() async {
    await _nativeBridge.openAccessibilitySettings();
  }

  /// Checks if overlay drawing is permitted (via Accessibility or SYSTEM_ALERT_WINDOW)
  Future<bool> checkOverlayPermission() async {
    return await _nativeBridge.hasOverlayPermission();
  }

  /// Requests overlay / accessibility permission
  Future<void> requestOverlayPermission() async {
    await _nativeBridge.requestOverlayPermission();
  }

  /// Returns diagnostic permission items with human-friendly status and rationales
  Future<List<PermissionDiagnostic>> getPermissionDiagnostics() async {
    final defaultLauncher = await isDefaultLauncher();
    final usageAccess = await checkUsageAccess();
    final notifRequired = await isNotificationPermissionRequired();
    final notification = notifRequired ? await checkNotificationPermission() : true;
    final accessibility = await checkAccessibilityPermission();
    final enfRequired = await isEnforcementPermissionRequired();
    final enforcement = enfRequired ? await checkEnforcementPermission() : true;
    final owner = await isDeviceOwner();

    return [
      PermissionDiagnostic(
        id: 'default_launcher',
        title: 'Default Launcher',
        description: defaultLauncher ? '✓ Enabled' : '⚠ Needs setup',
        rationale: 'Required to make Unclutter your primary home screen.',
        isGranted: defaultLauncher,
        isRequired: true,
        onAction: openDefaultLauncherSettings,
      ),
      PermissionDiagnostic(
        id: 'usage_access',
        title: 'Usage Access',
        description: usageAccess ? '✓ Enabled' : '⚠ Needs setup',
        rationale: 'Required for screen time insights and enforcing daily app limits.',
        isGranted: usageAccess,
        isRequired: true,
        onAction: openUsageAccessSettings,
      ),
      PermissionDiagnostic(
        id: 'notification',
        title: 'Notifications',
        description: notification ? '✓ Enabled' : '⚠ Needs setup',
        rationale: 'Required for timed access countdowns and expiration notices.',
        isGranted: notification,
        isRequired: notifRequired,
        onAction: openNotificationSettings,
      ),
      PermissionDiagnostic(
        id: 'accessibility',
        title: 'Accessibility Service',
        description: accessibility ? '✓ Enabled' : '⚠ Needs setup',
        rationale: 'Required for the double-tap to lock screen gesture.',
        isGranted: accessibility,
        isRequired: false,
        onAction: openAccessibilitySettings,
      ),
      if (enfRequired)
        PermissionDiagnostic(
          id: 'enforcement',
          title: 'Overlay Enforcement',
          description: enforcement ? '✓ Enabled' : '⚠ Needs setup',
          rationale: 'Required on your Android version to reliably block distracting apps.',
          isGranted: enforcement,
          isRequired: true,
          onAction: openEnforcementSettings,
        ),
      PermissionDiagnostic(
        id: 'tamper_protection',
        title: 'Tamper Protection',
        description: owner ? '✓ Protected' : 'Inactive (Optional)',
        rationale: 'Prevents uninstalling or force-closing Unclutter to bypass limits.',
        isGranted: owner,
        isRequired: false,
        onAction: () async {
          if (!owner) {
            await enableProtection();
          }
        },
      ),
    ];
  }
}

/// Represents a standardized permission diagnostic item with human-friendly rationale
class PermissionDiagnostic {
  final String id;
  final String title;
  final String description;
  final String rationale;
  final bool isGranted;
  final bool isRequired;
  final Future<void> Function() onAction;

  const PermissionDiagnostic({
    required this.id,
    required this.title,
    required this.description,
    required this.rationale,
    required this.isGranted,
    this.isRequired = true,
    required this.onAction,
  });
}
