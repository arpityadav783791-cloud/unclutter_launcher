import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../models/app_config.dart';

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
}
