import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/launcher_settings.dart';
import '../services/settings_service.dart';

class SettingsController extends GetxController {
  final SettingsService _service = Get.find<SettingsService>();

  final RxBool showClock = true.obs;
  final RxBool showDate = true.obs;
  final RxDouble textScale = 1.0.obs;
  final RxString themeMode = 'system'.obs;

  @override
  void onInit() {
    super.onInit();
    _sync();
  }

  void _sync() {
    final s = _service.settings;
    showClock.value = s.showClock;
    showDate.value = s.showDate;
    textScale.value = s.textScale;
    themeMode.value = s.themeMode;
  }

  Future<void> toggleClock() async {
    await _service.setShowClock(!showClock.value);
    showClock.value = _service.settings.showClock;
  }

  Future<void> toggleDate() async {
    await _service.setShowDate(!showDate.value);
    showDate.value = _service.settings.showDate;
  }

  Future<void> setTextScale(double value) async {
    await _service.setTextScale(value);
    textScale.value = _service.settings.textScale;
  }

  Future<void> setThemeMode(String mode) async {
    await _service.setThemeMode(mode);
    themeMode.value = _service.settings.themeMode;
  }

  ThemeMode get flutterThemeMode {
    switch (themeMode.value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
