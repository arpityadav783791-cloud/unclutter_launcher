import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/services/native_bridge.dart';
import '../../screen_time/services/usage_stats_service.dart';

class LauncherController extends GetxController with WidgetsBindingObserver {
  final RxString currentTime = ''.obs;
  final RxString currentDate = ''.obs;
  final RxInt batteryLevel = (-1).obs;
  final RxString todayScreenTime = ''.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _updateDateTime();
    updateBatteryLevel();
    updateScreenTime();

    // Update every 30 seconds – good balance of accuracy vs battery
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateDateTime();
      updateBatteryLevel();
      updateScreenTime();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateDateTime();
      updateBatteryLevel();
      updateScreenTime();
    }
  }

  Future<void> updateBatteryLevel() async {
    if (Get.isRegistered<NativeBridge>()) {
      final level = await Get.find<NativeBridge>().getBatteryLevel();
      batteryLevel.value = level;
    }
  }

  Future<void> updateScreenTime() async {
    try {
      final usageService = Get.isRegistered<UsageStatsService>()
          ? Get.find<UsageStatsService>()
          : Get.put(UsageStatsService(), permanent: true);

      final hasPermission = await usageService.hasPermission();
      if (!hasPermission) {
        todayScreenTime.value = '';
        return;
      }

      final today = await usageService.getTodayUsage();
      final totalMs = today.fold<int>(
        0,
        (sum, item) => sum + item.totalTimeInForegroundMs,
      );

      final formatted = formatScreenTime(totalMs);
      if (todayScreenTime.value != formatted) {
        todayScreenTime.value = formatted;
      }
    } catch (_) {
      todayScreenTime.value = '';
    }
  }

  static String formatScreenTime(int totalMs) {
    if (totalMs <= 0) return '<1m';
    final totalMinutes = totalMs ~/ 60000;
    if (totalMinutes < 1) return '<1m';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
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
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.onClose();
  }
}
