import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../models/schedule_config.dart';

class ScheduleService extends GetxService {
  static const String _key = 'schedule_configs';
  final StorageService _storage = Get.find<StorageService>();

  Map<String, ScheduleConfig> _cache = {};

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
              ScheduleConfig.fromMap(Map<String, dynamic>.from(item))
      };
    } catch (_) {
      _cache = {};
    }
  }

  Future<void> _save() async {
    final list = _cache.values.map((e) => e.toMap()).toList();
    await _storage.setString(_key, jsonEncode(list));
  }

  ScheduleConfig getConfig(String packageName) {
    return _cache[packageName] ??
        ScheduleConfig(packageName: packageName);
  }

  bool isEnabled(String packageName) => getConfig(packageName).enabled;

  bool isCurrentlyBlocked(String packageName) {
    return getConfig(packageName).isCurrentlyBlocked();
  }

  Future<void> setSchedule(
    String packageName, {
    required int startMinutes,
    required int endMinutes,
  }) async {
    _cache[packageName] = ScheduleConfig(
      packageName: packageName,
      enabled: true,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
    );
    await _save();
  }

  Future<void> disable(String packageName) async {
    final current = getConfig(packageName);
    _cache[packageName] = current.copyWith(enabled: false);
    await _save();
  }
}
