import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/native_bridge.dart';
import '../models/protected_mode_state.dart';
import '../services/protected_mode_service.dart';

/// Controller orchestrating Protected Launcher Mode, recovery triggers, and UI state.
class ProtectedModeController extends GetxController with WidgetsBindingObserver {
  final ProtectedModeService _service = Get.find<ProtectedModeService>();
  final NativeBridge _nativeBridge = Get.find<NativeBridge>();

  final Rx<ProtectedModeState> state = ProtectedModeState.initial().obs;
  final RxBool isLoading = false.obs;
  final RxString statusMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    _nativeBridge.onRecoveryTriggered = () {
      _handleRecoveryTriggered();
    };

    refreshState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      refreshState();
    }
  }

  /// Refreshes state from native DevicePolicyManager
  Future<void> refreshState() async {
    isLoading.value = true;
    try {
      final freshState = await _service.fetchState();
      state.value = freshState;
    } catch (_) {
      // Keep existing state
    } finally {
      isLoading.value = false;
    }
  }

  /// Enables Device Owner protection
  Future<bool> enableProtection() async {
    isLoading.value = true;
    statusMessage.value = '';

    try {
      if (!state.value.deviceOwnerActive) {
        statusMessage.value = 'Device Owner provisioning is required first.';
        return false;
      }

      final success = await _service.enableProtection();
      if (success) {
        await refreshState();
        statusMessage.value = 'Protected Mode enabled successfully.';
        return true;
      } else {
        statusMessage.value = 'Could not enable Protected Mode.';
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Disables protection during recovery flow
  Future<bool> disableProtection() async {
    isLoading.value = true;
    statusMessage.value = '';

    try {
      final success = await _service.disableProtection();
      if (success) {
        await refreshState();
        return true;
      } else {
        statusMessage.value = 'Could not disable protection.';
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Prompts user to set default launcher
  Future<void> requestDefaultLauncher() async {
    await _service.requestDefaultLauncher();
  }

  void _handleRecoveryTriggered() {
    final context = Get.context;
    if (context != null) {
      context.push(AppRoutes.protectedModeRecovery);
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
