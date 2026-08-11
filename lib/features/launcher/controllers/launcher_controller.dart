import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LauncherController extends GetxController {
  final RxString currentTime = ''.obs;
  final RxString currentDate = ''.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _updateDateTime();
    // Update every 30 seconds – good balance of accuracy vs battery
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateDateTime();
    });
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
