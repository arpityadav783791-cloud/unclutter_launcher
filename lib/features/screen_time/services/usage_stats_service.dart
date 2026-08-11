import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/app_usage.dart';

class UsageStatsService extends GetxService {
  static const MethodChannel _channel =
      MethodChannel('com.minimal.launcher/native');

  /// Whether the user has granted Usage Access permission.
  Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasUsagePermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system Usage Access settings screen.
  Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } on PlatformException {
      // ignore
    }
  }

  /// Today's usage for all apps, sorted by time descending.
  Future<List<AppUsage>> getTodayUsage() async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getTodayUsage');
      if (result == null) return [];
      return result
          .map((e) => AppUsage.fromMap(e as Map<dynamic, dynamic>))
          .toList();
    } on PlatformException {
      return [];
    }
  }

  /// This week's usage for all apps.
  Future<List<AppUsage>> getWeeklyUsage() async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getWeeklyUsage');
      if (result == null) return [];
      return result
          .map((e) => AppUsage.fromMap(e as Map<dynamic, dynamic>))
          .toList();
    } on PlatformException {
      return [];
    }
  }

  /// Usage for a single package (today + week).
  Future<SingleAppUsage> getAppUsage(String packageName) async {
    try {
      final result = await _channel.invokeMethod<Map>(
        'getAppUsage',
        {'packageName': packageName},
      );
      if (result == null) {
        return SingleAppUsage(packageName: packageName, todayMs: 0, weekMs: 0);
      }
      return SingleAppUsage.fromMap(result);
    } on PlatformException {
      return SingleAppUsage(packageName: packageName, todayMs: 0, weekMs: 0);
    }
  }
}
