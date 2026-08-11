import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../models/focus_mode_config.dart';

class FocusModeService extends GetxService {
  static const String _key = 'focus_mode_config';
  final StorageService _storage = Get.find<StorageService>();

  FocusModeConfig _config = const FocusModeConfig();

  FocusModeConfig get config => _config;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  void _load() {
    final raw = _storage.getString(_key);
    if (raw == null || raw.isEmpty) {
      _config = const FocusModeConfig();
      return;
    }
    try {
      _config = FocusModeConfig.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      // Auto-expire if needed
      if (_config.isActive && !_config.isCurrentlyActive) {
        _config = _config.copyWith(isActive: false, clearEndsAt: true);
        _save();
      }
    } catch (_) {
      _config = const FocusModeConfig();
    }
  }

  Future<void> _save() async {
    await _storage.setString(_key, jsonEncode(_config.toMap()));
  }

  Future<void> start({
    required int durationMinutes,
    required List<String> blockedPackages,
  }) async {
    final endsAt = DateTime.now().add(Duration(minutes: durationMinutes));
    _config = FocusModeConfig(
      isActive: true,
      endsAt: endsAt,
      blockedPackages: blockedPackages,
    );
    await _save();
  }

  Future<void> stop() async {
    _config = _config.copyWith(isActive: false, clearEndsAt: true);
    await _save();
  }

  Future<void> setBlockedPackages(List<String> packages) async {
    _config = _config.copyWith(blockedPackages: packages);
    await _save();
  }

  Future<void> toggleBlocked(String packageName) async {
    final list = List<String>.from(_config.blockedPackages);
    if (list.contains(packageName)) {
      list.remove(packageName);
    } else {
      list.add(packageName);
    }
    await setBlockedPackages(list);
  }

  bool isBlocked(String packageName) {
    if (!_config.isCurrentlyActive) return false;
    return _config.blockedPackages.contains(packageName);
  }

  bool get isActive => _config.isCurrentlyActive;
}
