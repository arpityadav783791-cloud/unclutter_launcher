import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/native_bridge.dart';
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
  final RxBool showScreenTime = true.obs;
  final RxnString customScreenTimePackage = RxnString();
  final RxString eInkMode = 'auto'.obs;
  final RxBool isHardwareEink = false.obs;
  final RxBool dailyWallpaperEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    _sync();
    _applyStatusBar();
    _detectHardwareEink();
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
    showScreenTime.value = s.showScreenTime;
    customScreenTimePackage.value = s.customScreenTimePackage;
    eInkMode.value = s.eInkMode;
    dailyWallpaperEnabled.value = s.dailyWallpaperEnabled;
  }

  Future<void> _detectHardwareEink() async {
    if (Get.isRegistered<NativeBridge>()) {
      try {
        final bridge = Get.find<NativeBridge>();
        isHardwareEink.value = await bridge.isEinkDevice();
      } catch (_) {}
    }
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

  Future<void> cycleHomeAppsCount() async {
    final next = (homeAppsCount.value >= 8) ? 0 : homeAppsCount.value + 1;
    await setHomeAppsCount(next);
  }

  Future<void> cycleHomeAlignment() async {
    final current = homeAlignment.value;
    final next = current == 'left'
        ? 'center'
        : current == 'center'
            ? 'right'
            : 'left';
    await setHomeAlignment(next);
  }

  Future<void> cycleDateTimeVisibility() async {
    final current = dateTimeVisibility.value;
    final next = current == 'on'
        ? 'date_only'
        : current == 'date_only'
            ? 'off'
            : 'on';
    await setDateTimeVisibility(next);
  }

  Future<void> cycleThemeMode() async {
    final current = themeMode.value;
    final next = current == 'system'
        ? 'dark'
        : current == 'dark'
            ? 'light'
            : 'system';
    await setThemeMode(next);
  }

  Future<void> cycleTextScale() async {
    final current = textScale.value;
    final next = current < 0.95
        ? 1.0
        : (current <= 1.05 ? 1.15 : 0.9);
    await setTextScale(next);
  }

  Future<void> setSwipeDownAction(String action) async {
    await _service.setSwipeDownAction(action);
    swipeDownAction.value = _service.settings.swipeDownAction;
  }

  Future<void> cycleSwipeDownAction() async {
    final current = swipeDownAction.value;
    final next = current == 'notifications' ? 'search' : 'notifications';
    await setSwipeDownAction(next);
  }

  Future<void> cycleEInkMode() async {
    final current = eInkMode.value;
    final next = current == 'auto'
        ? 'on'
        : current == 'on'
            ? 'off'
            : 'auto';
    await setEInkMode(next);
  }

  String get homeAlignmentLabel {
    switch (homeAlignment.value) {
      case 'center':
        return 'Center';
      case 'right':
        return 'Right';
      default:
        return 'Left';
    }
  }

  String get dateTimeVisibilityLabel {
    switch (dateTimeVisibility.value) {
      case 'date_only':
        return 'Date only';
      case 'off':
        return 'Off';
      default:
        return 'On';
    }
  }

  String get themeModeLabel {
    switch (themeMode.value) {
      case 'dark':
        return 'Dark';
      case 'light':
        return 'Light';
      default:
        return 'System';
    }
  }

  String get textScaleLabel {
    if (textScale.value < 0.95) return 'Small';
    if (textScale.value <= 1.05) return 'Normal';
    return 'Large';
  }

  String get swipeDownActionLabel {
    return swipeDownAction.value == 'search' ? 'Search' : 'Notifications';
  }

  String get eInkModeLabel {
    if (eInkMode.value == 'on') return 'Always on';
    if (eInkMode.value == 'off') return 'Off';
    return isHardwareEink.value ? 'Auto (E-Ink)' : 'Auto';
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

    if (next && Get.isRegistered<NativeBridge>()) {
      final bridge = Get.find<NativeBridge>();
      final isEnabled = await bridge.isAccessibilityServiceEnabled();
      if (!isEnabled) {
        await bridge.openAccessibilitySettings();
      }
    }
  }

  Future<void> toggleShowScreenTime() async {
    final next = !showScreenTime.value;
    await _service.setShowScreenTime(next);
    showScreenTime.value = next;
  }

  Future<void> setCustomScreenTimePackage(String? package) async {
    await _service.setCustomScreenTimePackage(package);
    customScreenTimePackage.value = package;
  }

  bool get isEinkActive {
    if (eInkMode.value == 'on') return true;
    if (eInkMode.value == 'off') return false;
    return isHardwareEink.value;
  }

  Future<void> setEInkMode(String mode) async {
    await _service.setEInkMode(mode);
    eInkMode.value = mode;
  }

  Future<void> toggleDailyWallpaper() async {
    final next = !dailyWallpaperEnabled.value;
    await _service.setDailyWallpaperEnabled(next);
    dailyWallpaperEnabled.value = next;
  }

  CrossAxisAlignment get currentCrossAxisAlignment {
    switch (homeAlignment.value) {
      case 'center':
        return CrossAxisAlignment.center;
      case 'right':
        return CrossAxisAlignment.end;
      case 'left':
      default:
        return CrossAxisAlignment.start;
    }
  }

  TextAlign get currentTextAlign {
    switch (homeAlignment.value) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'left':
      default:
        return TextAlign.left;
    }
  }

  Alignment get currentFavoritesAlignment {
    final isBottom = homeBottomAlignment.value;
    switch (homeAlignment.value) {
      case 'center':
        return isBottom ? Alignment.bottomCenter : Alignment.center;
      case 'right':
        return isBottom ? Alignment.bottomRight : Alignment.centerRight;
      case 'left':
      default:
        return isBottom ? Alignment.bottomLeft : Alignment.centerLeft;
    }
  }

  ThemeMode get flutterThemeMode {
    if (isEinkActive) {
      return ThemeMode.light; // E-Ink displays force light mode for contrast
    }
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
