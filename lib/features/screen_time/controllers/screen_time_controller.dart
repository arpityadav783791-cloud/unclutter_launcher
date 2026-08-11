import 'package:get/get.dart';
import '../../apps/controllers/apps_controller.dart';
import '../models/app_usage.dart';
import '../services/usage_stats_service.dart';

class ScreenTimeController extends GetxController {
  final UsageStatsService _usageService = Get.find<UsageStatsService>();
  final AppsController _appsController = Get.find<AppsController>();

  final RxBool hasPermission = false.obs;
  final RxBool isLoading = true.obs;
  final RxList<AppUsage> todayUsage = <AppUsage>[].obs;
  final RxList<AppUsage> weekUsage = <AppUsage>[].obs;
  final RxInt totalTodayMs = 0.obs;
  final RxInt totalYesterdayMs = 0.obs;

  bool _hasLoadedOnce = false;

  @override
  void onInit() {
    super.onInit();
    // Defer heavy work slightly so the route transition stays smooth
    Future.microtask(refresh);
  }

  Future<void> refresh() async {
    if (!_hasLoadedOnce) {
      isLoading.value = true;
    }

    hasPermission.value = await _usageService.hasPermission();

    if (hasPermission.value) {
      // Run both queries; they are independent
      final results = await Future.wait([
        _usageService.getTodayUsage(),
        _usageService.getWeeklyUsage(),
      ]);

      final today = results[0];
      final week = results[1];

      todayUsage.assignAll(today);
      weekUsage.assignAll(week);

      totalTodayMs.value =
          today.fold<int>(0, (sum, item) => sum + item.totalTimeInForegroundMs);

      final weekTotal =
          week.fold<int>(0, (sum, item) => sum + item.totalTimeInForegroundMs);
      final otherDays = (weekTotal - totalTodayMs.value).clamp(0, weekTotal);
      totalYesterdayMs.value = otherDays ~/ 6;
    } else {
      todayUsage.clear();
      weekUsage.clear();
      totalTodayMs.value = 0;
      totalYesterdayMs.value = 0;
    }

    _hasLoadedOnce = true;
    isLoading.value = false;
  }

  Future<void> requestPermission() async {
    await _usageService.openUsageAccessSettings();
  }

  String displayNameFor(String packageName) {
    final app = _appsController.findByPackage(packageName);
    if (app != null) return _appsController.displayName(app);
    return packageName;
  }

  String get totalTodayFormatted => _format(totalTodayMs.value);

  String get comparisonText {
    final diff = totalTodayMs.value - totalYesterdayMs.value;
    if (totalYesterdayMs.value == 0) return '';
    final abs = diff.abs();
    final formatted = _format(abs);
    if (diff > 0) return '↑ $formatted vs avg';
    if (diff < 0) return '↓ $formatted vs avg';
    return 'Same as avg';
  }

  bool get isUp => totalTodayMs.value > totalYesterdayMs.value;

  static String _format(int ms) {
    final totalSeconds = ms ~/ 1000;
    if (totalSeconds < 60) return '${totalSeconds}s';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }
}
