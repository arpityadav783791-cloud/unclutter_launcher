import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../models/app_config.dart';
import '../models/app_info.dart';
import 'distraction_detector.dart';

class AppConfigService extends GetxService {
  static const String _key = 'app_configs';
  final StorageService _storage = Get.find<StorageService>();

  Map<String, AppConfig> _cache = {};

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  void _load() {
    final raw = _storage.getString(_key);
    if (raw == null || raw.isEmpty) {
      _cache = {};
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _cache = {
        for (final item in list)
          (item as Map)['packageName'] as String: AppConfig.fromMap(
            Map<String, dynamic>.from(item),
          )
      };
    } catch (_) {
      _cache = {};
    }
  }

  Future<void> _save() async {
    final list = _cache.values.map((e) => e.toMap()).toList();
    await _storage.setString(_key, jsonEncode(list));
  }

  AppConfig getConfig(String packageName) {
    return _cache[packageName] ??
        AppConfig(packageName: packageName);
  }

  Future<void> setCustomName(String packageName, String? name) async {
    final current = getConfig(packageName);
    if (name == null || name.trim().isEmpty) {
      _cache[packageName] = current.copyWith(clearCustomName: true);
    } else {
      _cache[packageName] = current.copyWith(customName: name.trim());
    }
    await _save();
  }

  Future<void> setHidden(String packageName, bool hidden) async {
    final current = getConfig(packageName);
    _cache[packageName] = current.copyWith(isHidden: hidden);
    await _save();
  }

  Future<void> toggleHidden(String packageName) async {
    final current = getConfig(packageName);
    await setHidden(packageName, !current.isHidden);
  }

  bool isHidden(String packageName) {
    return getConfig(packageName).isHidden;
  }

  String displayName(String packageName, String originalName) {
    return getConfig(packageName).displayName(originalName);
  }

  List<String> get hiddenPackageNames {
    return _cache.values
        .where((c) => c.isHidden)
        .map((c) => c.packageName)
        .toList();
  }

  List<String> get renamedPackageNames {
    return _cache.values
        .where((c) => c.customName != null && c.customName!.trim().isNotEmpty)
        .map((c) => c.packageName)
        .toList();
  }

  Future<void> setDistraction(
    String packageName,
    bool isDistraction, {
    bool isUserAction = true,
  }) async {
    final current = getConfig(packageName);
    _cache[packageName] = current.copyWith(
      isDistraction: isDistraction,
      isUserConfigured: isUserAction ? true : current.isUserConfigured,
    );
    await _save();
  }

  Future<void> toggleDistraction(String packageName) async {
    final current = getConfig(packageName);
    await setDistraction(packageName, !current.isDistraction, isUserAction: true);
  }

  bool isDistraction(String packageName) {
    return getConfig(packageName).isDistraction;
  }

  List<String> get distractionPackageNames {
    return _cache.values
        .where((c) => c.isDistraction)
        .map((c) => c.packageName)
        .toList();
  }

  /// Automatically classifies newly discovered applications into the distraction
  /// category if they belong to social media, video/entertainment, or games,
  /// unless explicitly overridden by the user.
  Future<List<String>> autoDetectDistractions(List<AppInfo> apps) async {
    final newlyDetected = <String>[];
    bool hasChanges = false;

    for (final app in apps) {
      final current = getConfig(app.packageName);
      // Only auto-configure if user hasn't customized this app
      if (!current.isUserConfigured) {
        final isDistractionApp = DistractionDetector.isDistraction(app);
        if (current.isDistraction != isDistractionApp) {
          _cache[app.packageName] = current.copyWith(
            isDistraction: isDistractionApp,
            isUserConfigured: false,
          );
          hasChanges = true;
          if (isDistractionApp) {
            newlyDetected.add(app.packageName);
          }
        }
      }
    }

    if (hasChanges) {
      await _save();
    }

    return newlyDetected;
  }
}
