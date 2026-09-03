import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../services/settings_service.dart';

class SettingsController extends GetxController {
  final SettingsService _service = Get.find<SettingsService>();

  final RxBool showClock = true.obs;
  final RxBool showDate = true.obs;
  final RxDouble textScale = 1.0.obs;
  final RxString themeMode = 'system'.obs;

  // ── Olauncher Subsystems ──
  final RxString homeAlignment = 'left'.obs;
  final RxBool homeBottomAlignment = false.obs;
  final RxInt homeAppsCount = 4.obs;
  final RxString dateTimeVisibility = 'on'.obs;
  final RxBool showStatusBar = true.obs;
  final RxBool boldFont = false.obs;
  final RxBool autoShowKeyboard = true.obs;
  final RxBool autoLaunchSingleMatch = true.obs;
  final RxString swipeDownAction = 'notifications'.obs;
  final RxnString swipeLeftPackage = RxnString();
  final RxnString swipeRightPackage = RxnString();
  final RxBool doubleTapToLock = false.obs;

  @override
  void onInit() {
    super.onInit();
    _sync();
    _applyStatusBar();
  }

  void _sync() {
    final s = _service.settings;
    showClock.value = s.showClock;
    showDate.value = s.showDate;
    textScale.value = s.textScale;
    themeMode.value = s.themeMode;
    homeAlignment.value = s.homeAlignment;
    homeBottomAlignment.value = s.homeBottomAlignment;
    homeAppsCount.value = s.homeAppsCount;
    dateTimeVisibility.value = s.dateTimeVisibility;
    showStatusBar.value = s.showStatusBar;
    boldFont.value = s.boldFont;
    autoShowKeyboard.value = s.autoShowKeyboard;
    autoLaunchSingleMatch.value = s.autoLaunchSingleMatch;
    swipeDownAction.value = s.swipeDownAction;
    swipeLeftPackage.value = s.swipeLeftPackage;
    swipeRightPackage.value = s.swipeRightPackage;
    doubleTapToLock.value = s.doubleTapToLock;
  }

  void _applyStatusBar() {
    if (showStatusBar.value) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom],
      );
    }
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

  Future<void> setHomeAlignment(String alignment) async {
    await _service.setHomeAlignment(alignment);
    homeAlignment.value = _service.settings.homeAlignment;
  }

  Future<void> toggleHomeBottomAlignment() async {
    await _service.setHomeBottomAlignment(!homeBottomAlignment.value);
    homeBottomAlignment.value = _service.settings.homeBottomAlignment;
  }

  Future<void> setHomeAppsCount(int count) async {
    await _service.setHomeAppsCount(count);
    homeAppsCount.value = _service.settings.homeAppsCount;
  }

  Future<void> setDateTimeVisibility(String visibility) async {
    await _service.setDateTimeVisibility(visibility);
    dateTimeVisibility.value = _service.settings.dateTimeVisibility;
  }

  Future<void> toggleStatusBar() async {
    final next = !showStatusBar.value;
    await _service.setShowStatusBar(next);
    showStatusBar.value = next;
    _applyStatusBar();
  }

  Future<void> toggleBoldFont() async {
    final next = !boldFont.value;
    await _service.setBoldFont(next);
    boldFont.value = next;
  }

  Future<void> toggleAutoShowKeyboard() async {
    final next = !autoShowKeyboard.value;
    await _service.setAutoShowKeyboard(next);
    autoShowKeyboard.value = next;
  }

  Future<void> toggleAutoLaunchSingleMatch() async {
    final next = !autoLaunchSingleMatch.value;
    await _service.setAutoLaunchSingleMatch(next);
    autoLaunchSingleMatch.value = next;
  }

  Future<void> setSwipeDownAction(String action) async {
    await _service.setSwipeDownAction(action);
    swipeDownAction.value = _service.settings.swipeDownAction;
  }

  Future<void> setSwipeLeftPackage(String? package) async {
    await _service.setSwipeLeftPackage(package);
    swipeLeftPackage.value = _service.settings.swipeLeftPackage;
  }

  Future<void> setSwipeRightPackage(String? package) async {
    await _service.setSwipeRightPackage(package);
    swipeRightPackage.value = _service.settings.swipeRightPackage;
  }

  Future<void> toggleDoubleTapToLock() async {
    final next = !doubleTapToLock.value;
    await _service.setDoubleTapToLock(next);
    doubleTapToLock.value = next;
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
