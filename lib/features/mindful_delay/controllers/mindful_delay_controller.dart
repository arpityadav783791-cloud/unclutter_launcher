import 'dart:async';
import 'package:get/get.dart';
import '../services/mindful_delay_service.dart';
import '../models/mindful_delay_config.dart';

class MindfulDelayController extends GetxController {
  final MindfulDelayService _service = Get.find<MindfulDelayService>();

  final RxInt remainingSeconds = 0.obs;
  final RxString appName = ''.obs;
  final RxString packageName = ''.obs;
  final RxBool isActive = false.obs;

  Timer? _timer;
  void Function()? _onComplete;

  bool isEnabledFor(String package) => _service.isEnabled(package);

  int durationFor(String package) => _service.getDuration(package);

  Future<void> setDuration(String package, int seconds) async {
    await _service.setDuration(package, seconds);
  }

  Future<void> disable(String package) async {
    await _service.disable(package);
  }

  /// Start the mindful delay countdown.
  /// Calls [onComplete] when finished (no cancel possible).
  void start({
    required String package,
    required String name,
    required void Function() onComplete,
  }) {
    // Cancel any previous timer
    _timer?.cancel();

    packageName.value = package;
    appName.value = name;
    remainingSeconds.value = _service.getDuration(package);
    isActive.value = true;
    _onComplete = onComplete;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value <= 1) {
        timer.cancel();
        isActive.value = false;
        _onComplete?.call();
      } else {
        remainingSeconds.value--;
      }
    });
  }

  void forceStop() {
    _timer?.cancel();
    isActive.value = false;
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
