import 'package:get/get.dart';
import '../../../core/utils/text_normalizer.dart';
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

  /// Filters and ranks a list of [apps] given search query [q].
  List<AppInfo> filterApps(List<AppInfo> apps, String q) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return apps;

    final matches = apps.where((app) {
      final display = _appsController.displayName(app);
      if (TextNormalizer.matches(display, trimmed)) return true;
      if (TextNormalizer.matches(app.packageName, trimmed)) return true;
      return false;
    }).toList();

    matches.sort((a, b) {
      final aName = _appsController.displayName(a);
      final bName = _appsController.displayName(b);

      final aScore = TextNormalizer.scoreMatch(aName, trimmed);
      final bScore = TextNormalizer.scoreMatch(bName, trimmed);

      if (aScore != bScore) {
        return aScore.compareTo(bScore);
      }

      return TextNormalizer.normalize(aName)
          .compareTo(TextNormalizer.normalize(bName));
    });

    return matches;
  }

  void _performSearch(String q) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) {
      results.clear();
      return;
    }

    // Search only visible apps (hidden apps are already filtered)
    final filtered = filterApps(_appsController.apps, trimmed);
    results.assignAll(filtered);
  }

  void clear() {
    query.value = '';
    results.clear();
  }
}
