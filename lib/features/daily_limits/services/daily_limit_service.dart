import 'dart:convert';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/services/storage_service.dart';
import '../models/daily_limit_config.dart';

class DailyLimitService extends GetxService {
  static const String _key = 'daily_limit_configs';
  final StorageService _storage = Get.find<StorageService>();

  Map<String, DailyLimitConfig> _cache = {};

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

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
              DailyLimitConfig.fromMap(Map<String, dynamic>.from(item))
      };
    } catch (_) {
      _cache = {};
    }
  }

  Future<void> _save() async {
    final list = _cache.values.map((e) => e.toMap()).toList();
    await _storage.setString(_key, jsonEncode(list));
  }

  DailyLimitConfig getConfig(String packageName) {
    return _cache[packageName] ??
        DailyLimitConfig(packageName: packageName);
  }

  bool isEnabled(String packageName) => getConfig(packageName).enabled;

  int effectiveLimitMinutes(String packageName) {
    return getConfig(packageName).effectiveLimitMinutes(_today);
  }

  Future<void> setLimit(String packageName, int minutes) async {
    final current = getConfig(packageName);
    _cache[packageName] = current.copyWith(
      enabled: true,
      limitMinutes: minutes,
    );
    await _save();
  }

  Future<void> disable(String packageName) async {
    final current = getConfig(packageName);
    _cache[packageName] = current.copyWith(enabled: false);
    await _save();
  }

  /// Grant a one-time extension for today (default +5 min)
  Future<void> extend(String packageName, {int extraMinutes = 5}) async {
    final current = getConfig(packageName);
    final alreadyToday = current.extensionDate == _today
        ? current.extensionMinutesToday
        : 0;

    _cache[packageName] = current.copyWith(
      extensionMinutesToday: alreadyToday + extraMinutes,
      extensionDate: _today,
    );
    await _save();
  }
}
