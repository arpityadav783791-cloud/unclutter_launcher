import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/services/native_bridge.dart';
import 'settings_service.dart';

/// Subsystem for fetching and setting daily curated wallpapers
/// based on Olauncher's repository architecture.
class DailyWallpaperService extends GetxService {
  static const String curatedWallpapersUrl =
      'https://gist.githubusercontent.com/tanujnotes/85e2d0343ace71e76615ac346fbff82b/raw';

  static const String fallbackDarkWallpaper =
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e';
  static const String fallbackLightWallpaper =
      'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05';

  final NativeBridge _nativeBridge = Get.find<NativeBridge>();
  final SettingsService _settingsService = Get.find<SettingsService>();

  final RxBool isUpdating = false.obs;
  final RxString lastUpdatedKey = ''.obs;

  /// Calculates the day key according to Olauncher specification:
  /// - If < 10 days since install: "0_{daysSinceInstall}"
  /// - If >= 10 days: "{month}_{day}"
  static String calculateDayKey(DateTime now, DateTime installDate) {
    final daysSinceInstall = now.difference(installDate).inDays;
    if (daysSinceInstall < 10 && daysSinceInstall >= 0) {
      return '0_$daysSinceInstall';
    } else {
      return '${now.month}_${now.day}';
    }
  }

  /// Downloads and applies the daily curated wallpaper
  Future<bool> updateDailyWallpaper({
    bool isDark = true,
    bool force = false,
    DateTime? testNow,
    DateTime? testInstallDate,
  }) async {
    final settings = _settingsService.settings;
    if (!settings.dailyWallpaperEnabled && !force) return false;

    final now = testNow ?? DateTime.now();
    final installDate = testInstallDate ?? DateTime(now.year, now.month, now.day);
    final dayKey = calculateDayKey(now, installDate);

    if (!force && lastUpdatedKey.value == dayKey) {
      return true; // Already applied today
    }

    isUpdating.value = true;
    try {
      final imageUrl = await _resolveWallpaperUrl(dayKey, isDark: isDark);
      final imageBytes = await _downloadBytes(imageUrl);
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final success = await _nativeBridge.setWallpaper(imageBytes, which: 3);
        if (success) {
          lastUpdatedKey.value = dayKey;
        }
        return success;
      }
      return false;
    } catch (e) {
      debugPrint('Error applying daily wallpaper: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  /// Resets wallpaper to clean pure black minimalist state
  Future<bool> resetWallpaper() async {
    isUpdating.value = true;
    try {
      final success = await _nativeBridge.clearWallpaper();
      if (success) {
        lastUpdatedKey.value = '';
      }
      return success;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<String> _resolveWallpaperUrl(String dayKey, {required bool isDark}) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(curatedWallpapersUrl));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(body);
        final list = isDark ? data['dark'] : data['light'];
        if (list is Map && list.containsKey(dayKey)) {
          return list[dayKey].toString();
        }
      }
    } catch (_) {
      // Fallback
    }
    return isDark ? fallbackDarkWallpaper : fallbackLightWallpaper;
  }

  Future<Uint8List?> _downloadBytes(String url) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        return bytes;
      }
    } catch (_) {
      // Failed to download
    }
    return null;
  }
}
