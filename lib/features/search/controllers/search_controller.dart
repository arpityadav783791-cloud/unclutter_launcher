import 'package:get/get.dart';
import '../../../core/utils/text_normalizer.dart';
import '../../apps/models/app_info.dart';
import '../../apps/controllers/apps_controller.dart';

/// Pre-indexed app item for fast search matching and sorting without repeated string allocation
class _SearchIndexItem {
  final AppInfo app;
  final String displayName;
  final String normName;
  final String cleanName;
  final String normPackage;

  _SearchIndexItem({
    required this.app,
    required this.displayName,
    required this.normName,
    required this.cleanName,
    required this.normPackage,
  });
}

class AppSearchController extends GetxController {
  final AppsController _appsController = Get.find<AppsController>();

  final RxString query = ''.obs;
  final RxList<AppInfo> results = <AppInfo>[].obs;

  List<_SearchIndexItem>? _cachedIndex;
  int _lastAppListHash = 0;

  @override
  void onInit() {
    super.onInit();
    // Invalidate index whenever visible apps change
    ever(_appsController.apps, (_) {
      _cachedIndex = null;
    });
  }

  void onQueryChanged(String value) {
    query.value = value;
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      results.clear();
      return;
    }
    _performSearch(trimmed);
  }

  void _ensureIndex(List<AppInfo> apps) {
    final currentHash = Object.hashAll(apps.map((a) => a.packageName));
    if (_cachedIndex != null && _lastAppListHash == currentHash) return;

    _cachedIndex = apps.map((app) {
      final name = _appsController.displayName(app);
      return _SearchIndexItem(
        app: app,
        displayName: name,
        normName: TextNormalizer.normalize(name),
        cleanName: TextNormalizer.cleanKey(name),
        normPackage: TextNormalizer.normalize(app.packageName),
      );
    }).toList();
    _lastAppListHash = currentHash;
  }

  /// High-performance filtering and ranking of installed applications.
  List<AppInfo> filterApps(List<AppInfo> apps, String q) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return apps;

    _ensureIndex(apps);
    final index = _cachedIndex!;
    final normQuery = TextNormalizer.normalize(trimmed);
    final cleanQuery = TextNormalizer.cleanKey(trimmed);

    final scored = <_ScoredItem>[];

    for (var i = 0; i < index.length; i++) {
      final item = index[i];
      final score = _scoreIndexItem(item, normQuery, cleanQuery);
      if (score < 999) {
        scored.add(_ScoredItem(item: item, score: score));
      }
    }

    scored.sort((a, b) {
      if (a.score != b.score) return a.score.compareTo(b.score);
      return a.item.normName.compareTo(b.item.normName);
    });

    return scored.map((s) => s.item.app).toList();
  }

  int _scoreIndexItem(_SearchIndexItem item, String normQuery, String cleanQuery) {
    if (item.normName == normQuery || item.cleanName == cleanQuery) return 0;
    if (item.normName.startsWith(normQuery)) return 1;
    if (item.cleanName.startsWith(cleanQuery)) return 2;

    // Word prefix match (e.g. "camera" matches word "Camera" in "Pro Camera")
    final words = item.normName.split(RegExp(r'[\s\-_.,:;/]'));
    for (final word in words) {
      if (word.startsWith(normQuery)) return 3;
    }

    if (item.normName.contains(normQuery)) return 4;
    if (item.cleanName.contains(cleanQuery)) return 5;
    if (item.normPackage.contains(normQuery)) return 6;

    return 999;
  }

  void _performSearch(String q) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) {
      results.clear();
      return;
    }

    final filtered = filterApps(_appsController.apps, trimmed);
    results.assignAll(filtered);
  }

  void clear() {
    query.value = '';
    results.clear();
  }
}

class _ScoredItem {
  final _SearchIndexItem item;
  final int score;

  _ScoredItem({required this.item, required this.score});
}
