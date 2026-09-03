import 'package:get/get.dart';
import '../models/app_info.dart';
import '../services/native_app_service.dart';
import '../services/app_config_service.dart';

class AppsController extends GetxController {
  final NativeAppService _nativeAppService = Get.find<NativeAppService>();
  final AppConfigService _configService = Get.find<AppConfigService>();

  final RxList<AppInfo> apps = <AppInfo>[].obs;       // visible only
  final RxList<AppInfo> allApps = <AppInfo>[].obs;    // includes hidden
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  bool _hasLoaded = false;
  DateTime? _lastLoadedAt;

  /// Cache is considered fresh for 5 minutes
  static const _cacheTtl = Duration(minutes: 5);

  @override
  void onInit() {
    super.onInit();
    loadApps();
  }

  Future<void> loadApps({bool forceRefresh = false}) async {
    // Use cache if still fresh
    if (_hasLoaded &&
        !forceRefresh &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _cacheTtl) {
      return;
    }

    // Only show loading spinner on first load
    if (!_hasLoaded) {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      final result = await _nativeAppService.getInstalledApps();
      allApps.assignAll(result);
      await _configService.autoDetectDistractions(result);
      _applyVisibility();
      _hasLoaded = true;
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      errorMessage.value = 'Could not load apps';
      if (!_hasLoaded) {
        apps.clear();
        allApps.clear();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _applyVisibility() {
    final visible = allApps
        .where((app) => !_configService.isHidden(app.packageName))
        .toList();
    // Only update if the list actually changed (reduces rebuilds)
    if (!_listEquals(apps, visible)) {
      apps.assignAll(visible);
    }
  }

  bool _listEquals(List<AppInfo> a, List<AppInfo> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].packageName != b[i].packageName) return false;
    }
    return true;
  }

  /// Call after rename / hide / unhide
  void refreshVisibility() {
    _applyVisibility();
  }

  Future<void> refreshApps() => loadApps(forceRefresh: true);

  Future<bool> launchApp(String packageName) async {
    return await _nativeAppService.launchApp(packageName);
  }

  AppInfo? findByPackage(String packageName) {
    // Prefer in-memory lookup – O(n) but list is small
    for (final app in allApps) {
      if (app.packageName == packageName) return app;
    }
    return null;
  }

  String displayName(AppInfo app) {
    return _configService.displayName(app.packageName, app.name);
  }
}
