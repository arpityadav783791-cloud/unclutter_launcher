import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import '../../features/launcher/views/launcher_home_view.dart';
import '../../features/launcher/bindings/launcher_binding.dart';
import '../../features/apps/bindings/apps_binding.dart';
import '../../features/search/views/search_view.dart';
import '../../features/search/controllers/search_controller.dart';
import '../../features/favorites/controllers/favorites_controller.dart';
import '../../features/favorites/services/favorites_service.dart';
import '../../features/productivity/controllers/productivity_controller.dart';
import '../../features/apps/services/app_config_service.dart';
import '../../features/mindful_delay/services/mindful_delay_service.dart';
import '../../features/mindful_delay/controllers/mindful_delay_controller.dart';
import '../../features/screen_time/services/usage_stats_service.dart';
import '../../features/screen_time/controllers/screen_time_controller.dart';
import '../../features/screen_time/views/screen_time_view.dart';
import '../../features/daily_limits/services/daily_limit_service.dart';
import '../../features/daily_limits/controllers/daily_limit_controller.dart';
import '../../features/focus_mode/services/focus_mode_service.dart';
import '../../features/focus_mode/controllers/focus_mode_controller.dart';
import '../../features/scheduled_block/services/schedule_service.dart';
import '../../features/scheduled_block/controllers/schedule_controller.dart';
import '../../features/settings/services/settings_service.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/settings/views/settings_view.dart';
import '../../features/timed_access/services/timed_access_service.dart';
import '../../features/timed_access/controllers/timed_access_controller.dart';
import '../../features/protected_mode/services/protected_mode_service.dart';
import '../../features/protected_mode/controllers/protected_mode_controller.dart';
import '../../features/protected_mode/views/protected_mode_view.dart';
import '../../features/protected_mode/views/protected_mode_recovery_view.dart';
import '../../features/onboarding/services/onboarding_service.dart';
import '../../features/onboarding/views/onboarding_view.dart';
import '../../features/launcher/services/home_gesture_service.dart';
import '../services/permission_service.dart';
import 'app_routes.dart';

class AppRouter {
  static String _determineInitialLocation() {
    if (Get.isRegistered<OnboardingService>() &&
        !Get.find<OnboardingService>().isOnboardingCompleted) {
      return AppRoutes.onboarding;
    }
    return AppRoutes.launcher;
  }

  static final GoRouter router = GoRouter(
    initialLocation: _determineInitialLocation(),
    redirect: (context, state) {
      if (!Get.isRegistered<OnboardingService>()) return null;
      final onboardingCompleted =
          Get.find<OnboardingService>().isOnboardingCompleted;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;

      if (!onboardingCompleted && !isOnboarding) {
        return AppRoutes.onboarding;
      }
      if (onboardingCompleted && isOnboarding) {
        return AppRoutes.launcher;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) {
          _ensureCoreBindings();
          return const OnboardingView();
        },
      ),
      GoRoute(
        path: AppRoutes.launcher,
        name: 'launcher',
        builder: (context, state) {
          _ensureCoreBindings();
          return const LauncherHomeView();
        },
      ),
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        builder: (context, state) {
          if (!Get.isRegistered<AppSearchController>()) {
            Get.put(AppSearchController());
          }
          return const SearchView();
        },
      ),
      GoRoute(
        path: AppRoutes.screenTime,
        name: 'screenTime',
        builder: (context, state) {
          if (!Get.isRegistered<UsageStatsService>()) {
            Get.put(UsageStatsService(), permanent: true);
          }
          if (!Get.isRegistered<ScreenTimeController>()) {
            Get.put(ScreenTimeController());
          }
          return const ScreenTimeView();
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) {
          if (!Get.isRegistered<SettingsService>()) {
            Get.put(SettingsService(), permanent: true);
          }
          if (!Get.isRegistered<SettingsController>()) {
            Get.put(SettingsController());
          }
          return const SettingsView();
        },
      ),
      GoRoute(
        path: AppRoutes.protectedMode,
        name: 'protectedMode',
        builder: (context, state) {
          if (!Get.isRegistered<ProtectedModeService>()) {
            Get.put(ProtectedModeService(), permanent: true);
          }
          if (!Get.isRegistered<ProtectedModeController>()) {
            Get.put(ProtectedModeController(), permanent: true);
          }
          return const ProtectedModeView();
        },
      ),
      GoRoute(
        path: AppRoutes.protectedModeRecovery,
        name: 'protectedModeRecovery',
        builder: (context, state) {
          if (!Get.isRegistered<ProtectedModeService>()) {
            Get.put(ProtectedModeService(), permanent: true);
          }
          if (!Get.isRegistered<ProtectedModeController>()) {
            Get.put(ProtectedModeController(), permanent: true);
          }
          return const ProtectedModeRecoveryView();
        },
      ),
    ],
  );

  static void _ensureCoreBindings() {
    LauncherBinding().dependencies();
    AppsBinding().dependencies();

    if (!Get.isRegistered<AppConfigService>()) {
      Get.put(AppConfigService(), permanent: true);
    }
    if (!Get.isRegistered<FavoritesService>()) {
      Get.put(FavoritesService(), permanent: true);
    }
    if (!Get.isRegistered<FavoritesController>()) {
      Get.put(FavoritesController());
    }
    if (!Get.isRegistered<MindfulDelayService>()) {
      Get.put(MindfulDelayService(), permanent: true);
    }
    if (!Get.isRegistered<MindfulDelayController>()) {
      Get.put(MindfulDelayController(), permanent: true);
    }
    if (!Get.isRegistered<UsageStatsService>()) {
      Get.put(UsageStatsService(), permanent: true);
    }
    if (!Get.isRegistered<DailyLimitService>()) {
      Get.put(DailyLimitService(), permanent: true);
    }
    if (!Get.isRegistered<DailyLimitController>()) {
      Get.put(DailyLimitController(), permanent: true);
    }
    if (!Get.isRegistered<FocusModeService>()) {
      Get.put(FocusModeService(), permanent: true);
    }
    if (!Get.isRegistered<FocusModeController>()) {
      Get.put(FocusModeController(), permanent: true);
    }
    if (!Get.isRegistered<ScheduleService>()) {
      Get.put(ScheduleService(), permanent: true);
    }
    if (!Get.isRegistered<ScheduleController>()) {
      Get.put(ScheduleController(), permanent: true);
    }
    if (!Get.isRegistered<SettingsService>()) {
      Get.put(SettingsService(), permanent: true);
    }
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController(), permanent: true);
    }
    if (!Get.isRegistered<TimedAccessService>()) {
      Get.put(TimedAccessService(), permanent: true);
    }
    if (!Get.isRegistered<TimedAccessController>()) {
      Get.put(TimedAccessController(), permanent: true);
    }
    if (!Get.isRegistered<ProtectedModeService>()) {
      Get.put(ProtectedModeService(), permanent: true);
    }
    if (!Get.isRegistered<ProtectedModeController>()) {
      Get.put(ProtectedModeController(), permanent: true);
    }
    if (!Get.isRegistered<PermissionService>()) {
      Get.put(PermissionService(), permanent: true);
    }
    if (!Get.isRegistered<OnboardingService>()) {
      Get.put(OnboardingService(), permanent: true);
    }
    if (!Get.isRegistered<ProductivityController>()) {
      Get.put(ProductivityController(), permanent: true);
    }
    if (!Get.isRegistered<HomeGestureService>()) {
      Get.put(HomeGestureService(), permanent: true);
    }
    if (!Get.isRegistered<AppSearchController>()) {
      Get.put(AppSearchController(), permanent: true);
    }
  }
}
