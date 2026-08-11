import 'dart:async';
import 'package:get/get.dart';
import '../models/focus_mode_config.dart';
import '../services/focus_mode_service.dart';

class FocusModeController extends GetxController {
  final FocusModeService _service = Get.find<FocusModeService>();

  final RxBool isActive = false.obs;
  final RxString remainingText = ''.obs;
  final RxList<String> blockedPackages = <String>[].obs;

  Timer? _ticker;

  @override
  void onInit() {
    super.onInit();
    _syncFromService();
    _startTicker();
  }

  void _syncFromService() {
    final config = _service.config;
    isActive.value = config.isCurrentlyActive;
    blockedPackages.assignAll(config.blockedPackages);
    remainingText.value = FocusModeConfig.formatDuration(config.remaining);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      _syncFromService();
      // Auto stop when expired
      if (isActive.value && !_service.config.isCurrentlyActive) {
        stop();
      }
    });
  }

  bool isBlocked(String packageName) => _service.isBlocked(packageName);

  Future<void> start(int durationMinutes) async {
    // Use currently selected blocked list
    await _service.start(
      durationMinutes: durationMinutes,
      blockedPackages: blockedPackages.toList(),
    );
    _syncFromService();
  }

  Future<void> stop() async {
    await _service.stop();
    _syncFromService();
  }

  Future<void> toggleBlockedApp(String packageName) async {
    await _service.toggleBlocked(packageName);
    blockedPackages.assignAll(_service.config.blockedPackages);
  }

  bool isAppInBlockList(String packageName) {
    return blockedPackages.contains(packageName);
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }
}
