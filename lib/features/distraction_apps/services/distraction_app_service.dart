import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../../apps/controllers/apps_controller.dart';
import '../../apps/models/app_info.dart';
import '../../apps/services/app_config_service.dart';
import '../models/distraction_app.dart';
import '../models/distraction_settings.dart';
import 'distraction_classifier.dart';

/// Repository and persistence service for distraction application management.
/// Enforces user override priority: User Exclusions > User Additions > Auto Classification.
class DistractionAppService extends GetxService {
  static const String _storageKey = 'distraction_settings_v1';
  final StorageService _storage = Get.find<StorageService>();

  DistractionSettings _settings = const DistractionSettings();
  DistractionSettings get settings => _settings;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  void _loadSettings() {
    final raw = _storage.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _settings = const DistractionSettings();
      return;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _settings = DistractionSettings.fromMap(map);
    } catch (_) {
      _settings = const DistractionSettings();
    }
  }

  Future<void> _saveSettings() async {
    await _storage.setString(_storageKey, jsonEncode(_settings.toMap()));
  }

  /// Automatically identifies applications belonging to distracting categories
  /// and enables them by default unless the user has explicitly excluded them.
  Future<void> autoDetectDistractions(List<AppInfo> apps) async {
    final newEnabled = Set<String>.from(_settings.enabledPackages);

    for (final app in apps) {
      // If user explicitly excluded this app, do not re-enable it
      if (_settings.excludedPackages.contains(app.packageName)) {
        continue;
      }

      if (DistractionClassifier.isDistraction(app)) {
        newEnabled.add(app.packageName);
      }
    }

    _settings = _settings.copyWith(enabledPackages: newEnabled);
    await _saveSettings();
    _syncWithAppConfigService();
  }

  /// Returns true if the package is currently an active, enabled distraction.
  bool isDistraction(String packageName, {AppInfo? app}) {
    // 1. Explicit user exclusion: OFF
    if (_settings.excludedPackages.contains(packageName)) {
      return false;
    }

    // 2. Explicit user addition: ON
    if (_settings.manuallyAddedPackages.contains(packageName)) {
      return true;
    }

    // 3. Explicit enabled set
    if (_settings.enabledPackages.contains(packageName)) {
      return true;
    }

    // 4. Resolve AppInfo if not provided
    AppInfo? targetApp = app;
    if (targetApp == null && Get.isRegistered<AppsController>()) {
      try {
        final apps = Get.find<AppsController>().allApps;
        for (final a in apps) {
          if (a.packageName == packageName) {
            targetApp = a;
            break;
          }
        }
      } catch (_) {}
    }

    // 5. Fallback to automatic classifier if app info is found
    if (targetApp != null) {
      return DistractionClassifier.isDistraction(targetApp);
    }

    // 6. Safety net keyword heuristics on package name
    final pkgLower = packageName.toLowerCase();
    const distractionKeywords = [
      'youtube',
      'instagram',
      'facebook',
      'tiktok',
      'snapchat',
      'twitter',
      'reddit',
      'pinterest',
      'netflix',
      'twitch',
      'hotstar',
      'disneyplus',
      'spotify',
      'discord',
      'threads',
      'reels',
      'shorts',
      'game',
      'gaming',
    ];
    for (final kw in distractionKeywords) {
      if (pkgLower.contains(kw)) {
        return true;
      }
    }

    return false;
  }

  /// User overrides an app's distraction status:
  /// - If [enable] is false: app is excluded and launches normally.
  /// - If [enable] is true: app is marked as a distraction.
  Future<void> toggleDistraction(
    String packageName, {
    required bool enable,
    AppInfo? app,
  }) async {
    final newExcluded = Set<String>.from(_settings.excludedPackages);
    final newManual = Set<String>.from(_settings.manuallyAddedPackages);
    final newEnabled = Set<String>.from(_settings.enabledPackages);

    if (enable) {
      newExcluded.remove(packageName);
      newManual.add(packageName);
      newEnabled.add(packageName);
    } else {
      newExcluded.add(packageName);
      newManual.remove(packageName);
      newEnabled.remove(packageName);
    }

    _settings = _settings.copyWith(
      enabledPackages: newEnabled,
      excludedPackages: newExcluded,
      manuallyAddedPackages: newManual,
    );

    await _saveSettings();
    _syncWithAppConfigService();
  }

  /// Manually adds an application to the distraction list.
  Future<void> addManualDistraction(String packageName) async {
    await toggleDistraction(packageName, enable: true);
  }

  /// Manually removes an application from the distraction list.
  Future<void> removeDistraction(String packageName) async {
    await toggleDistraction(packageName, enable: false);
  }

  /// Returns the complete list of DistractionApp models for UI display.
  List<DistractionApp> getDistractionApps(List<AppInfo> allApps) {
    final Map<String, DistractionApp> result = {};

    for (final app in allApps) {
      if (app.packageName == 'com.minimal.launcher.settings') continue;

      final isAuto = DistractionClassifier.isDistraction(app);
      final isManual = _settings.manuallyAddedPackages.contains(app.packageName);
      final isExcluded = _settings.excludedPackages.contains(app.packageName);
      final isEnabled = isDistraction(app.packageName, app: app);

      // Show apps that are either automatically detected or manually added/excluded
      if (isAuto || isManual || isExcluded) {
        result[app.packageName] = DistractionApp(
          packageName: app.packageName,
          appName: app.name,
          isAutomaticallyDetected: isAuto,
          isEnabled: isEnabled,
          categoryLabel: DistractionClassifier.getCategoryLabel(app),
        );
      }
    }

    final list = result.values.toList();
    list.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
    return list;
  }

  void _syncWithAppConfigService() {
    if (Get.isRegistered<AppConfigService>()) {
      final configService = Get.find<AppConfigService>();
      for (final pkg in _settings.enabledPackages) {
        configService.setDistraction(pkg, true, isUserAction: true);
      }
      for (final pkg in _settings.excludedPackages) {
        configService.setDistraction(pkg, false, isUserAction: true);
      }
    }
  }
}
