import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../models/launcher_settings.dart';

class SettingsService extends GetxService {
  static const String _key = 'launcher_settings';
  final StorageService _storage = Get.find<StorageService>();

  LauncherSettings _settings = const LauncherSettings();

  LauncherSettings get settings => _settings;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  void _load() {
    final raw = _storage.getString(_key);
    if (raw == null || raw.isEmpty) {
      _settings = const LauncherSettings();
      return;
    }
    try {
      _settings = LauncherSettings.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      _settings = const LauncherSettings();
    }
  }

  Future<void> _save() async {
    await _storage.setString(_key, jsonEncode(_settings.toMap()));
  }

  Future<void> update(LauncherSettings newSettings) async {
    _settings = newSettings;
    await _save();
  }

  Future<void> setShowClock(bool value) async {
    await update(_settings.copyWith(showClock: value));
  }

  Future<void> setShowDate(bool value) async {
    await update(_settings.copyWith(showDate: value));
  }

  Future<void> setTextScale(double value) async {
    await update(_settings.copyWith(textScale: value.clamp(0.85, 1.25)));
  }

  Future<void> setThemeMode(String mode) async {
    await update(_settings.copyWith(themeMode: mode));
  }

  Future<void> setHomeAlignment(String alignment) async {
    await update(_settings.copyWith(homeAlignment: alignment));
  }

  Future<void> setHomeBottomAlignment(bool bottom) async {
    await update(_settings.copyWith(homeBottomAlignment: bottom));
  }

  Future<void> setHomeAppsCount(int count) async {
    await update(_settings.copyWith(homeAppsCount: count.clamp(0, 8)));
  }

  Future<void> setDateTimeVisibility(String visibility) async {
    await update(_settings.copyWith(dateTimeVisibility: visibility));
  }

  Future<void> setShowStatusBar(bool show) async {
    await update(_settings.copyWith(showStatusBar: show));
  }

  Future<void> setBoldFont(bool bold) async {
    await update(_settings.copyWith(boldFont: bold));
  }

  Future<void> setAutoShowKeyboard(bool auto) async {
    await update(_settings.copyWith(autoShowKeyboard: auto));
  }

  Future<void> setAutoLaunchSingleMatch(bool auto) async {
    await update(_settings.copyWith(autoLaunchSingleMatch: auto));
  }

  Future<void> setSwipeDownAction(String action) async {
    await update(_settings.copyWith(swipeDownAction: action));
  }

  Future<void> setSwipeLeftPackage(String? package) async {
    await update(_settings.copyWith(
      swipeLeftPackage: package,
      clearSwipeLeft: package == null,
    ));
  }

  Future<void> setSwipeRightPackage(String? package) async {
    await update(_settings.copyWith(
      swipeRightPackage: package,
      clearSwipeRight: package == null,
    ));
  }

  Future<void> setDoubleTapToLock(bool lock) async {
    await update(_settings.copyWith(doubleTapToLock: lock));
  }

  Future<void> setShowScreenTime(bool show) async {
    await update(_settings.copyWith(showScreenTime: show));
  }

  Future<void> setCustomScreenTimePackage(String? package) async {
    await update(_settings.copyWith(
      customScreenTimePackage: package,
      clearCustomScreenTimePackage: package == null,
    ));
  }

  Future<void> setEInkMode(String mode) async {
    await update(_settings.copyWith(eInkMode: mode));
  }

  Future<void> setDailyWallpaperEnabled(bool enabled) async {
    await update(_settings.copyWith(dailyWallpaperEnabled: enabled));
  }
}
