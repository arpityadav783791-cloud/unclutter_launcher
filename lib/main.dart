import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/services/native_bridge.dart';
import 'features/apps/services/native_app_service.dart';
import 'features/apps/services/app_config_service.dart';
import 'features/favorites/services/favorites_service.dart';
import 'features/mindful_delay/services/mindful_delay_service.dart';
import 'features/mindful_delay/controllers/mindful_delay_controller.dart';
import 'features/screen_time/services/usage_stats_service.dart';
import 'features/daily_limits/services/daily_limit_service.dart';
import 'features/daily_limits/controllers/daily_limit_controller.dart';
import 'features/focus_mode/services/focus_mode_service.dart';
import 'features/focus_mode/controllers/focus_mode_controller.dart';
import 'features/scheduled_block/services/schedule_service.dart';
import 'features/scheduled_block/controllers/schedule_controller.dart';
import 'features/settings/services/settings_service.dart';
import 'features/settings/services/daily_wallpaper_service.dart';
import 'features/settings/controllers/settings_controller.dart';
import 'features/timed_access/services/timed_access_service.dart';
import 'features/timed_access/controllers/timed_access_controller.dart';
import 'features/protected_mode/services/protected_mode_service.dart';
import 'features/protected_mode/controllers/protected_mode_controller.dart';
import 'core/services/permission_service.dart';
import 'features/onboarding/services/onboarding_service.dart';
import 'features/launcher/services/home_gesture_service.dart';
import 'features/distraction_apps/services/distraction_app_service.dart';
import 'features/distraction_apps/controllers/distraction_app_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Get.putAsync(() => StorageService().init());
  Get.put(NativeBridge());
  Get.put(PermissionService(), permanent: true);
  Get.put(OnboardingService(), permanent: true);
  Get.put(NativeAppService(), permanent: true);
  Get.put(AppConfigService(), permanent: true);
  Get.put(FavoritesService(), permanent: true);
  Get.put(MindfulDelayService(), permanent: true);
  Get.put(MindfulDelayController(), permanent: true);
  Get.put(UsageStatsService(), permanent: true);
  Get.put(DailyLimitService(), permanent: true);
  Get.put(DailyLimitController(), permanent: true);
  Get.put(FocusModeService(), permanent: true);
  Get.put(FocusModeController(), permanent: true);
  Get.put(ScheduleService(), permanent: true);
  Get.put(ScheduleController(), permanent: true);
  Get.put(TimedAccessService(), permanent: true);
  Get.put(TimedAccessController(), permanent: true);
  Get.put(ProtectedModeService(), permanent: true);
  Get.put(ProtectedModeController(), permanent: true);
  Get.put(SettingsService(), permanent: true);
  Get.put(SettingsController(), permanent: true);
  Get.put(DailyWallpaperService(), permanent: true);
  Get.put(HomeGestureService(), permanent: true);
  Get.put(DistractionAppService(), permanent: true);
  Get.put(DistractionAppController(), permanent: true);

  runApp(const MinimalLauncherApp());
}
