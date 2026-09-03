import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/services/native_bridge.dart';

class LauncherController extends GetxController {
  final RxString currentTime = ''.obs;
  final RxString currentDate = ''.obs;
  final RxInt batteryLevel = (-1).obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _updateDateTime();
    updateBatteryLevel();
    // Update every 30 seconds – good balance of accuracy vs battery
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateDateTime();
      updateBatteryLevel();
    });
  }

  Future<void> updateBatteryLevel() async {
    if (Get.isRegistered<NativeBridge>()) {
      final level = await Get.find<NativeBridge>().getBatteryLevel();
      batteryLevel.value = level;
    }
  }

  void _updateDateTime() {
    final now = DateTime.now();
    final newTime = DateFormat('h:mm a').format(now);
    final newDate = DateFormat('EEEE, d MMMM').format(now);

    // Only trigger rebuilds when values actually change
    if (currentTime.value != newTime) currentTime.value = newTime;
    if (currentDate.value != newDate) currentDate.value = newDate;
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
