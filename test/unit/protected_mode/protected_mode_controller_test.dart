import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/native_bridge.dart';
import 'package:minimal_launcher/features/protected_mode/controllers/protected_mode_controller.dart';
import 'package:minimal_launcher/features/protected_mode/models/protected_mode_state.dart';
import 'package:minimal_launcher/features/protected_mode/services/protected_mode_service.dart';

class FakeProtectedModeService extends GetxService implements ProtectedModeService {
  ProtectedModeState currentState = ProtectedModeState.initial();
  bool enableResult = true;
  bool disableResult = true;
  bool requestDefaultCalled = false;

  @override
  Future<ProtectedModeState> fetchState() async => currentState;

  @override
  Future<bool> enableProtection() async {
    if (enableResult) {
      currentState = currentState.copyWith(enabled: true);
    }
    return enableResult;
  }

  @override
  Future<bool> disableProtection() async {
    if (disableResult) {
      currentState = currentState.copyWith(enabled: false);
    }
    return disableResult;
  }

  @override
  Future<void> requestDefaultLauncher() async {
    requestDefaultCalled = true;
  }
}

class FakeNativeBridge extends GetxService implements NativeBridge {
  @override
  void Function(String packageName)? onSessionExpired;

  @override
  void Function()? onRecoveryTriggered;

  @override
  Future<bool> isDefaultLauncher() async => false;

  @override
  Future<void> openDefaultLauncherSettings() async {}

  @override
  Future<void> startTimedSession({
    required String packageName,
    required int durationSeconds,
  }) async {}

  @override
  Future<void> cancelTimedSession() async {}

  @override
  Future<void> returnToLauncher() async {}

  @override
  Future<bool> isDeviceOwner() async => false;

  @override
  Future<bool> isProtectedModeEnabled() async => false;

  @override
  Future<bool> enableProtectedMode() async => true;

  @override
  Future<bool> disableProtectedMode() async => true;

  @override
  Future<Map<String, dynamic>> getProtectedModeState() async => {};

  @override
  Future<void> requestDefaultLauncher() async {}

  @override
  Future<bool> hasUsagePermission() async => false;

  @override
  Future<void> openUsageAccessSettings() async {}

  @override
  Future<bool> hasNotificationPermission() async => true;

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<bool> isNotificationPermissionRequired() async => false;

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<bool> hasEnforcementPermission() async => true;

  @override
  Future<bool> isEnforcementPermissionRequired() async => false;

  @override
  Future<void> openEnforcementSettings() async {}

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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeProtectedModeService fakeService;
  late FakeNativeBridge fakeBridge;
  late ProtectedModeController controller;

  setUp(() {
    Get.reset();
    fakeService = FakeProtectedModeService();
    fakeBridge = FakeNativeBridge();

    Get.put<NativeBridge>(fakeBridge);
    Get.put<ProtectedModeService>(fakeService);

    controller = Get.put<ProtectedModeController>(ProtectedModeController());
  });

  tearDown(() {
    Get.reset();
  });

  group('ProtectedModeController Tests', () {
    test('Initial state loads accurately from service', () async {
      fakeService.currentState = const ProtectedModeState(
        enabled: false,
        deviceOwnerActive: true,
        defaultLauncherActive: true,
      );

      await controller.refreshState();

      expect(controller.state.value.enabled, isFalse);
      expect(controller.state.value.deviceOwnerActive, isTrue);
      expect(controller.state.value.defaultLauncherActive, isTrue);
    });

    test('enableProtection fails gracefully when Device Owner is inactive', () async {
      fakeService.currentState = const ProtectedModeState(
        enabled: false,
        deviceOwnerActive: false,
        defaultLauncherActive: false,
      );
      controller.state.value = fakeService.currentState;

      final result = await controller.enableProtection();

      expect(result, isFalse);
      expect(
        controller.statusMessage.value,
        contains('Device Owner provisioning is required'),
      );
      expect(controller.state.value.enabled, isFalse);
    });

    test('enableProtection succeeds when Device Owner is active', () async {
      fakeService.currentState = const ProtectedModeState(
        enabled: false,
        deviceOwnerActive: true,
        defaultLauncherActive: true,
      );
      controller.state.value = fakeService.currentState;

      final result = await controller.enableProtection();

      expect(result, isTrue);
      expect(controller.state.value.enabled, isTrue);
      expect(
        controller.statusMessage.value,
        contains('Protected Mode enabled successfully'),
      );
    });

    test('disableProtection disables protection and updates state', () async {
      fakeService.currentState = const ProtectedModeState(
        enabled: true,
        deviceOwnerActive: true,
        defaultLauncherActive: true,
      );
      controller.state.value = fakeService.currentState;

      final result = await controller.disableProtection();

      expect(result, isTrue);
      expect(controller.state.value.enabled, isFalse);
    });

    test('requestDefaultLauncher delegates to service', () async {
      await controller.requestDefaultLauncher();
      expect(fakeService.requestDefaultCalled, isTrue);
    });

    test('NativeBridge onRecoveryTriggered hook is assigned on init', () {
      expect(fakeBridge.onRecoveryTriggered, isNotNull);
    });

    test('Protected mode state does not leak secret recovery code', () {
      final map = controller.state.value.toMap();
      expect(map.containsKey('secretCode'), isFalse);
      expect(map.containsKey('recoveryCode'), isFalse);
      expect(controller.state.value.toString().contains('550055'), isFalse);
    });
  });
}
