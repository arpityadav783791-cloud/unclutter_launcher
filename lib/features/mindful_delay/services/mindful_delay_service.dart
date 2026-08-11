import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../models/mindful_delay_config.dart';

class MindfulDelayService extends GetxService {
  static const String _key = 'mindful_delay_configs';
  final StorageService _storage = Get.find<StorageService>();

  Map<String, MindfulDelayConfig> _cache = {};

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
          (item as Map)['packageName'] as String:
              MindfulDelayConfig.fromMap(Map<String, dynamic>.from(item))
      };
    } catch (_) {
      _cache = {};
    }
  }

  Future<void> _save() async {
    final list = _cache.values.map((e) => e.toMap()).toList();
    await _storage.setString(_key, jsonEncode(list));
  }

  MindfulDelayConfig getConfig(String packageName) {
    return _cache[packageName] ??
        MindfulDelayConfig(packageName: packageName);
  }

  bool isEnabled(String packageName) {
    return getConfig(packageName).enabled;
  }

  int getDuration(String packageName) {
    return getConfig(packageName).durationSeconds;
  }

  Future<void> setEnabled(String packageName, bool enabled) async {
    final current = getConfig(packageName);
    _cache[packageName] = current.copyWith(enabled: enabled);
    await _save();
  }

  Future<void> setDuration(String packageName, int seconds) async {
    final current = getConfig(packageName);
    _cache[packageName] = current.copyWith(
      enabled: true,
      durationSeconds: seconds,
    );
    await _save();
  }

  Future<void> disable(String packageName) async {
    await setEnabled(packageName, false);
  }
}
