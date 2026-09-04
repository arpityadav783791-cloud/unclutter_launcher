import 'package:get/get.dart';
import '../../../core/services/native_bridge.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/routes/app_router.dart';
import '../models/app_info.dart';
import '../models/pinned_shortcut.dart';
import '../services/native_app_service.dart';
import '../services/app_config_service.dart';

class AppsController extends GetxController {
  final NativeAppService _nativeAppService = Get.find<NativeAppService>();
  final AppConfigService _configService = Get.find<AppConfigService>();

  final RxList<AppInfo> apps = <AppInfo>[].obs;       // visible only
  final RxList<AppInfo> allApps = <AppInfo>[].obs;    // includes hidden
  final RxList<PinnedShortcut> pinnedShortcuts = <PinnedShortcut>[].obs;
  final RxBool isPrivateSpaceAvailable = false.obs;
  final RxBool isPrivateSpaceLocked = false.obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  bool _hasLoaded = false;
  DateTime? _lastLoadedAt;

  /// Cache is considered fresh for 5 minutes
  static const _cacheTtl = Duration(minutes: 5);

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<NativeBridge>()) {
      Get.find<NativeBridge>().onPackagesChanged = (packageName, action) {
        _nativeAppService.invalidateCache();
        loadApps(forceRefresh: true);
      };
    }
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
      final appList = List<AppInfo>.from(result);
      if (!appList.any((a) => a.packageName == 'com.minimal.launcher.settings')) {
        appList.add(const AppInfo(
          name: 'Settings(unclutter)',
          packageName: 'com.minimal.launcher.settings',
          isSystemApp: true,
        ));
      }
      appList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      allApps.assignAll(appList);
      await _configService.autoDetectDistractions(result);
      _applyVisibility();
      _hasLoaded = true;
      _lastLoadedAt = DateTime.now();
      await loadPinnedShortcuts();
      await checkPrivateSpaceStatus();
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
      if (a[i].packageName != b[i].packageName ||
          a[i].userSerial != b[i].userSerial) {
        return false;
      }
    }
    return true;
  }

  /// Call after rename / hide / unhide
  void refreshVisibility() {
    _applyVisibility();
  }

  Future<void> refreshApps() => loadApps(forceRefresh: true);

  Future<bool> launchApp(
    String packageName, {
    int? userSerial,
    String? activityName,
  }) async {
    if (packageName == 'com.minimal.launcher.settings' ||
        packageName == 'com.minimal.launcher') {
      AppRouter.router.push(AppRoutes.settings);
      return true;
    }
    if (packageName == 'com.android.settings' ||
        packageName == 'android.settings') {
      if (Get.isRegistered<NativeBridge>()) {
        return await Get.find<NativeBridge>().openDeviceSettings();
      }
    }
    return await _nativeAppService.launchApp(
      packageName,
      userSerial: userSerial,
      activityName: activityName,
    );
  }

  AppInfo? findApp(String packageName, {int userSerial = 0}) {
    for (final app in allApps) {
      if (app.packageName == packageName && app.userSerial == userSerial) {
        return app;
      }
    }
    return findByPackage(packageName);
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

  Future<void> loadPinnedShortcuts() async {
    if (Get.isRegistered<NativeBridge>()) {
      try {
        final shortcuts = await Get.find<NativeBridge>().getPinnedShortcuts();
        pinnedShortcuts.assignAll(shortcuts);
      } catch (_) {}
    }
  }

  Future<void> checkPrivateSpaceStatus() async {
    if (Get.isRegistered<NativeBridge>()) {
      try {
        final bridge = Get.find<NativeBridge>();
        isPrivateSpaceAvailable.value = await bridge.isPrivateSpaceAvailable();
        if (isPrivateSpaceAvailable.value) {
          isPrivateSpaceLocked.value = await bridge.isPrivateSpaceLocked();
        }
      } catch (_) {}
    }
  }

  Future<bool> togglePrivateSpace() async {
    if (Get.isRegistered<NativeBridge>()) {
      try {
        final bridge = Get.find<NativeBridge>();
        final requestUnlock = isPrivateSpaceLocked.value;
        final success =
            await bridge.togglePrivateSpace(requestUnlock: requestUnlock);
        await checkPrivateSpaceStatus();
        await refreshApps();
        return success;
      } catch (_) {}
    }
    return false;
  }

  Future<bool> launchShortcut(PinnedShortcut shortcut) async {
    if (Get.isRegistered<NativeBridge>()) {
      try {
        return await Get.find<NativeBridge>().launchShortcut(
          packageName: shortcut.packageName,
          shortcutId: shortcut.id,
          userSerial: shortcut.userSerial,
        );
      } catch (_) {}
    }
    return false;
  }

  Future<bool> unpinShortcut(PinnedShortcut shortcut) async {
    if (Get.isRegistered<NativeBridge>()) {
      try {
        final success = await Get.find<NativeBridge>().unpinShortcut(
          packageName: shortcut.packageName,
          shortcutId: shortcut.id,
          userSerial: shortcut.userSerial,
        );
        if (success) {
          pinnedShortcuts.removeWhere((s) =>
              s.id == shortcut.id && s.packageName == shortcut.packageName);
        }
        return success;
      } catch (_) {}
    }
    return false;
  }
}
