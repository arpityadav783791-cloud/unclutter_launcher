import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/app_info.dart';

/// Abstraction over Android PackageManager.
/// Includes a simple in-memory cache to avoid repeated native calls.
class NativeAppService extends GetxService {
  static const MethodChannel _channel =
      MethodChannel('com.minimal.launcher/native');

  List<AppInfo>? _cachedApps;
  DateTime? _cachedAt;
  static const _cacheTtl = Duration(minutes: 5);

  /// Returns all launchable installed applications (cached).
  Future<List<AppInfo>> getInstalledApps({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedApps != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return _cachedApps!;
    }

    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getInstalledApps');

      if (result == null) return _cachedApps ?? [];

      final apps = result
          .map((item) => AppInfo.fromMap(item as Map<dynamic, dynamic>))
          .where((app) => app.packageName.isNotEmpty)
          .toList();

      apps.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      _cachedApps = apps;
      _cachedAt = DateTime.now();
      return apps;
    } on PlatformException catch (e) {
      Get.log('NativeAppService.getInstalledApps error: ${e.message}');
      return _cachedApps ?? [];
    } catch (e) {
      Get.log('NativeAppService.getInstalledApps unexpected error: $e');
      return _cachedApps ?? [];
    }
  }

  /// Invalidate cache (e.g. after install/uninstall if we detect it later)
  void invalidateCache() {
    _cachedApps = null;
    _cachedAt = null;
  }

  Future<bool> launchApp(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'launchApp',
        {'packageName': packageName},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isAppInstalled(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isAppInstalled',
        {'packageName': packageName},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
