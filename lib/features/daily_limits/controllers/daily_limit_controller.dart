import 'package:get/get.dart';
import '../../screen_time/services/usage_stats_service.dart';
import '../models/daily_limit_config.dart';
import '../services/daily_limit_service.dart';

class DailyLimitController extends GetxController {
  final DailyLimitService _service = Get.find<DailyLimitService>();
  final UsageStatsService _usageService = Get.find<UsageStatsService>();

  bool isEnabledFor(String package) => _service.isEnabled(package);

  int limitMinutesFor(String package) =>
      _service.getConfig(package).limitMinutes;

  int effectiveLimitFor(String package) =>
      _service.effectiveLimitMinutes(package);

  Future<void> setLimit(String package, int minutes) async {
    await _service.setLimit(package, minutes);
  }

  Future<void> disable(String package) async {
    await _service.disable(package);
  }

  Future<void> extend(String package, {int extraMinutes = 5}) async {
    await _service.extend(package, extraMinutes: extraMinutes);
  }

  /// Returns true if the app has already reached its daily limit.
  Future<bool> hasReachedLimit(String packageName) async {
    if (!_service.isEnabled(packageName)) return false;

    final hasPermission = await _usageService.hasPermission();
    if (!hasPermission) return false; // can't enforce without data

    final usage = await _usageService.getAppUsage(packageName);
    final usedMinutes = usage.todayMs ~/ 60000;
    final limit = _service.effectiveLimitMinutes(packageName);

    return usedMinutes >= limit;
  }

  /// Remaining minutes today (can be negative if over).
  Future<int> remainingMinutes(String packageName) async {
    if (!_service.isEnabled(packageName)) return 9999;

    final usage = await _usageService.getAppUsage(packageName);
    final usedMinutes = usage.todayMs ~/ 60000;
    final limit = _service.effectiveLimitMinutes(packageName);
    return limit - usedMinutes;
  }
}
