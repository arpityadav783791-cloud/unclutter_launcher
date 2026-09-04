import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/native_bridge.dart';
import 'package:minimal_launcher/core/services/permission_service.dart';

class MockNativeBridge extends GetxService implements NativeBridge {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  bool usageAccess = false;
  bool openedUsageSettings = false;
  bool notificationPermission = false;
  bool notificationRequired = true;
  bool openedNotificationSettings = false;
  bool defaultLauncher = false;
  bool openedLauncherSettings = false;
  bool enforcementPermission = true;
  bool enforcementRequired = false;
  bool openedEnforcementSettings = false;
  bool deviceOwner = false;
  bool protectionEnabled = false;

  @override
  void Function(String packageName)? onSessionExpired;
  @override
  void Function()? onRecoveryTriggered;
  @override
  void Function(String packageName, String action)? onPackagesChanged;

  @override
  Future<bool> hasUsagePermission() async => usageAccess;

  @override
  Future<void> openUsageAccessSettings() async {
    openedUsageSettings = true;
  }

  @override
  Future<bool> hasNotificationPermission() async => notificationPermission;

  @override
  Future<bool> requestNotificationPermission() async => notificationPermission;

  @override
  Future<bool> isNotificationPermissionRequired() async => notificationRequired;

  @override
  Future<void> openNotificationSettings() async {
    openedNotificationSettings = true;
  }

  @override
  Future<bool> isDefaultLauncher() async => defaultLauncher;

  @override
  Future<void> openDefaultLauncherSettings() async {
    openedLauncherSettings = true;
  }

  @override
  Future<void> requestDefaultLauncher() async {
    openedLauncherSettings = true;
  }

  @override
  Future<bool> hasEnforcementPermission() async => enforcementPermission;

  @override
  Future<bool> isEnforcementPermissionRequired() async => enforcementRequired;

  @override
  Future<void> openEnforcementSettings() async {
    openedEnforcementSettings = true;
  }

  @override
  Future<bool> isDeviceOwner() async => deviceOwner;

  @override
  Future<bool> isProtectedModeEnabled() async => protectionEnabled;

  @override
  Future<bool> enableProtectedMode() async {
    if (deviceOwner) {
      protectionEnabled = true;
      return true;
    }
    return false;
  }

  @override
  Future<bool> disableProtectedMode() async {
    protectionEnabled = false;
    return true;
  }

  @override
  Future<Map<String, dynamic>> getProtectedModeState() async => {
        'enabled': protectionEnabled,
        'deviceOwnerActive': deviceOwner,
        'defaultLauncherActive': defaultLauncher,
      };

  @override
  Future<void> cancelTimedSession() async {}

  @override
  Future<void> returnToLauncher() async {}

  @override
  Future<void> startTimedSession({
    required String packageName,
    required int durationSeconds,
  }) async {}

  @override
  Future<void> expandStatusBar() async {}

  @override
  Future<bool> openAppDetails(String packageName) async => true;

  @override
  Future<bool> uninstallApp(String packageName) async => true;

  @override
  Future<bool> openClock() async => true;

  @override
  Future<bool> openCalendar() async => true;

  @override
  Future<int> getBatteryLevel() async => 85;

  @override
  Future<void> openWebSearch(String query) async {}

  @override
  Future<bool> lockScreen() async => true;

  @override
  Future<bool> isAccessibilityServiceEnabled() async => true;

  @override
  Future<void> openAccessibilitySettings() async {}

  @override
  Future<bool> openScreenTimeApp({String? customPackage}) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNativeBridge mockNativeBridge;
  late PermissionService permissionService;

  setUp(() {
    Get.reset();
    mockNativeBridge = MockNativeBridge();
    Get.put<NativeBridge>(mockNativeBridge);
    permissionService = PermissionService();
    Get.put<PermissionService>(permissionService);
  });

  tearDown(() {
    Get.reset();
  });

  test('5 & 6. checkUsageAccess and openUsageAccessSettings work correctly', () async {
    mockNativeBridge.usageAccess = false;
    expect(await permissionService.checkUsageAccess(), isFalse);

    mockNativeBridge.usageAccess = true;
    expect(await permissionService.checkUsageAccess(), isTrue);

    await permissionService.openUsageAccessSettings();
    expect(mockNativeBridge.openedUsageSettings, isTrue);
  });

  test('7 & 8. checkNotificationPermission and requestNotificationPermission work', () async {
    mockNativeBridge.notificationPermission = false;
    expect(await permissionService.checkNotificationPermission(), isFalse);
    expect(await permissionService.requestNotificationPermission(), isFalse);

    mockNativeBridge.notificationPermission = true;
    expect(await permissionService.checkNotificationPermission(), isTrue);
    expect(await permissionService.requestNotificationPermission(), isTrue);

    expect(await permissionService.isNotificationPermissionRequired(), isTrue);
    await permissionService.openNotificationSettings();
    expect(mockNativeBridge.openedNotificationSettings, isTrue);
  });

  test('9 & 10. isDefaultLauncher and openDefaultLauncherSettings work', () async {
    mockNativeBridge.defaultLauncher = false;
    expect(await permissionService.isDefaultLauncher(), isFalse);

    mockNativeBridge.defaultLauncher = true;
    expect(await permissionService.isDefaultLauncher(), isTrue);

    await permissionService.openDefaultLauncherSettings();
    expect(mockNativeBridge.openedLauncherSettings, isTrue);
  });

  test('11 & 12. checkEnforcementPermission and settings work', () async {
    expect(await permissionService.checkEnforcementPermission(), isTrue);
    expect(await permissionService.isEnforcementPermissionRequired(), isFalse);

    await permissionService.openEnforcementSettings();
    expect(mockNativeBridge.openedEnforcementSettings, isTrue);
  });

  test('13 & 14. isDeviceOwner and enableProtection work', () async {
    mockNativeBridge.deviceOwner = false;
    expect(await permissionService.isDeviceOwner(), isFalse);
    expect(await permissionService.enableProtection(), isFalse);

    mockNativeBridge.deviceOwner = true;
    expect(await permissionService.isDeviceOwner(), isTrue);
    expect(await permissionService.enableProtection(), isTrue);
    expect(mockNativeBridge.protectionEnabled, isTrue);
  });
}
