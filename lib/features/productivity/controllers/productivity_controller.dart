import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../apps/services/native_app_service.dart';
import '../../apps/models/app_info.dart';
import '../../apps/controllers/apps_controller.dart';
import '../../mindful_delay/controllers/mindful_delay_controller.dart';
import '../../mindful_delay/services/mindful_delay_service.dart';
import '../../mindful_delay/views/mindful_delay_view.dart';
import '../../daily_limits/controllers/daily_limit_controller.dart';
import '../../daily_limits/views/limit_reached_view.dart';
import '../../focus_mode/controllers/focus_mode_controller.dart';
import '../../focus_mode/views/focus_blocked_view.dart';
import '../../scheduled_block/controllers/schedule_controller.dart';
import '../../scheduled_block/views/schedule_blocked_view.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/native_bridge.dart';

/// Central authority for every app launch decision.
class ProductivityController extends GetxController {
  final NativeAppService _nativeAppService = Get.find<NativeAppService>();
  final AppsController _appsController = Get.find<AppsController>();
  final MindfulDelayService _mindfulDelayService =
      Get.find<MindfulDelayService>();
  final DailyLimitController _dailyLimitController =
      Get.find<DailyLimitController>();
  final FocusModeController _focusModeController =
      Get.find<FocusModeController>();
  final ScheduleController _scheduleController =
      Get.find<ScheduleController>();

  /// Main entry point for launching an app.
  /// Runs all enabled productivity interventions in priority order:
  /// 1. Focus Mode (hard block)
  /// 2. Scheduled Block (time-of-day block)
  /// 3. Daily Limit (usage cap reached)
  /// 4. Mindful Delay (friction timer)
  /// 5. Direct Launch (if no restrictions apply)
  Future<bool> handleAppLaunch(
    String packageName, {
    int userSerial = 0,
    String? activityName,
    BuildContext? context,
  }) async {
    if (packageName.isEmpty) return false;

    // Direct navigation to Launcher Settings if selected
    if (packageName == 'com.minimal.launcher.settings' ||
        packageName == 'com.minimal.launcher') {
      AppRouter.router.push(AppRoutes.settings);
      return true;
    }

    // Direct opening of Android Device Settings
    if (packageName == 'com.android.settings' ||
        packageName == 'android.settings') {
      if (Get.isRegistered<NativeBridge>()) {
        return await Get.find<NativeBridge>().openDeviceSettings();
      }
    }

    final app = _appsController.findApp(packageName, userSerial: userSerial);
    if (app == null) {
      _showMessage('App not found');
      return false;
    }

    // 1. Focus Mode
    if (_focusModeController.isBlocked(packageName)) {
      return _showFocusBlocked(app);
    }

    // 2. Scheduled Block
    if (_scheduleController.isCurrentlyBlocked(packageName)) {
      return _showScheduleBlocked(app);
    }

    // 3. Daily Limit
    final reached = await _dailyLimitController.hasReachedLimit(packageName);
    if (reached) {
      return _showLimitReached(app);
    }

    // 4. Mindful Delay
    if (_mindfulDelayService.isEnabled(packageName)) {
      return _startMindfulDelay(app);
    }

    return _launch(app);
  }

  Future<bool> _showFocusBlocked(AppInfo app) async {
    final context = Get.context;
    if (context == null) return false;
    final displayName = _appsController.displayName(app);

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => FocusBlockedView(appName: displayName),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
    return false;
  }

  Future<bool> _showScheduleBlocked(AppInfo app) async {
    final context = Get.context;
    if (context == null) return false;
    final displayName = _appsController.displayName(app);
    final config = _scheduleController.configFor(app.packageName);
    final label = '${config.startFormatted} → ${config.endFormatted}';

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ScheduleBlockedView(
          appName: displayName,
          scheduleLabel: label,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
    return false;
  }

  Future<bool> _showLimitReached(AppInfo app) async {
    final context = Get.context;
    if (context == null) return false;
    final displayName = _appsController.displayName(app);

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LimitReachedView(
          appName: displayName,
          packageName: app.packageName,
          onClose: () => Navigator.pop(context),
          onExtend: () async {
            await _dailyLimitController.extend(app.packageName, extraMinutes: 5);
            if (context.mounted) {
              Navigator.pop(context);
            }
            await handleAppLaunch(app.packageName);
          },
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
    return false;
  }

  Future<bool> _startMindfulDelay(AppInfo app) async {
    final delayController = Get.find<MindfulDelayController>();
    final displayName = _appsController.displayName(app);
    final context = Get.context;
    if (context == null) return false;

    delayController.start(
      package: app.packageName,
      name: displayName,
      onComplete: () async {
        if (Get.context != null && Navigator.canPop(Get.context!)) {
          Navigator.pop(Get.context!);
        }
        await _launch(app);
      },
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MindfulDelayView(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
    return true;
  }

  Future<bool> _launch(AppInfo app) async {
    bool success = await _nativeAppService.launchApp(
      app.packageName,
      userSerial: app.userSerial,
      activityName: app.activityName,
    );
    if (!success &&
        (app.packageName == 'com.android.settings' ||
            app.packageName.contains('settings') ||
            app.name.toLowerCase() == 'settings')) {
      if (Get.isRegistered<NativeBridge>()) {
        success = await Get.find<NativeBridge>().openDeviceSettings();
      }
    }
    if (!success) {
      _showMessage('Could not open ${app.name}');
    }
    return success;
  }

  Future<bool> launch(AppInfo app, {BuildContext? context}) => handleAppLaunch(
        app.packageName,
        userSerial: app.userSerial,
        activityName: app.activityName,
        context: context,
      );

  void _showMessage(String message) {
    Get.rawSnackbar(
      message: message,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF222222),
      borderRadius: 8,
      margin: const EdgeInsets.all(16),
    );
  }
}
