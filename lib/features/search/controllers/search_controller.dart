import 'package:get/get.dart';
import '../../apps/models/app_info.dart';
import '../../apps/controllers/apps_controller.dart';

class AppSearchController extends GetxController {
  final AppsController _appsController = Get.find<AppsController>();

  final RxString query = ''.obs;
  final RxList<AppInfo> results = <AppInfo>[].obs;

  void onQueryChanged(String value) {
    query.value = value;
    _performSearch(value);
  }

  void _performSearch(String q) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) {
      results.clear();
      return;
    }

    final lower = trimmed.toLowerCase();
    // Search only visible apps (hidden apps are already filtered)
    final matches = _appsController.apps.where((app) {
      final display = _appsController.displayName(app).toLowerCase();
      return display.contains(lower) ||
          app.packageName.toLowerCase().contains(lower);
    }).toList();

    matches.sort((a, b) {
      final aName = _appsController.displayName(a).toLowerCase();
      final bName = _appsController.displayName(b).toLowerCase();
      final aStarts = aName.startsWith(lower);
      final bStarts = bName.startsWith(lower);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;
      return aName.compareTo(bName);
    });

    results.assignAll(matches);
  }

  void clear() {
    query.value = '';
    results.clear();
  }
}
