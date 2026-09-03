import 'package:get/get.dart';
import '../../../core/services/native_bridge.dart';
import '../models/protected_mode_state.dart';

/// Service interfacing with native Android DevicePolicyManager for Protected Launcher Mode.
class ProtectedModeService extends GetxService {
  final NativeBridge _nativeBridge = Get.find<NativeBridge>();

  /// Queries native Android for authoritative Protected Mode & Device Owner state
  Future<ProtectedModeState> fetchState() async {
    final map = await _nativeBridge.getProtectedModeState();
    if (map.isEmpty) {
      final isOwner = await _nativeBridge.isDeviceOwner();
      final isEnabled = await _nativeBridge.isProtectedModeEnabled();
      final isDefault = await _nativeBridge.isDefaultLauncher();
      return ProtectedModeState(
        enabled: isEnabled,
        deviceOwnerActive: isOwner,
        defaultLauncherActive: isDefault,
      );
    }
    return ProtectedModeState.fromMap(map);
  }

  /// Enables Device Owner protection
  Future<bool> enableProtection() async {
    return await _nativeBridge.enableProtectedMode();
  }

  /// Disables protection during recovery flow
  Future<bool> disableProtection() async {
    return await _nativeBridge.disableProtectedMode();
  }

  /// Prompts user to choose default launcher
  Future<void> requestDefaultLauncher() async {
    await _nativeBridge.requestDefaultLauncher();
  }
}
