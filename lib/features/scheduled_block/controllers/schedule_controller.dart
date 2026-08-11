import 'package:get/get.dart';
import '../models/schedule_config.dart';
import '../services/schedule_service.dart';

class ScheduleController extends GetxController {
  final ScheduleService _service = Get.find<ScheduleService>();

  bool isEnabledFor(String package) => _service.isEnabled(package);

  bool isCurrentlyBlocked(String package) =>
      _service.isCurrentlyBlocked(package);

  ScheduleConfig configFor(String package) => _service.getConfig(package);

  Future<void> setSchedule(
    String package, {
    required int startMinutes,
    required int endMinutes,
  }) async {
    await _service.setSchedule(
      package,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
    );
  }

  Future<void> disable(String package) async {
    await _service.disable(package);
  }
}
