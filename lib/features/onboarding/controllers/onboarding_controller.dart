import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/permission_service.dart';
import '../../apps/controllers/apps_controller.dart';
import '../../apps/models/app_info.dart';
import '../../apps/services/app_config_service.dart';
import '../services/onboarding_service.dart';

/// Enum representing each step of the onboarding flow.
enum OnboardingStepType {
  welcome,
  howItWorks,
  distractionApps,
  usageAccess,
  notifications,
  defaultLauncher,
  enforcement,
  protection,
  completion,
}

class OnboardingController extends GetxController with WidgetsBindingObserver {
  final OnboardingService _onboardingService = Get.find<OnboardingService>();
  final PermissionService _permissionService = Get.find<PermissionService>();
  final AppConfigService _appConfigService = Get.find<AppConfigService>();

  final PageController pageController = PageController();

  final RxInt currentStepIndex = 0.obs;
  final RxList<OnboardingStepType> activeSteps = <OnboardingStepType>[].obs;

  // Permission & setup state
  final RxBool usageAccessGranted = false.obs;
  final RxBool notificationGranted = false.obs;
  final RxBool isNotificationRequired = false.obs;
  final RxBool defaultLauncherActive = false.obs;
  final RxBool enforcementGranted = true.obs;
  final RxBool isEnforcementRequired = false.obs;
  final RxBool deviceOwnerActive = false.obs;
  final RxBool protectedModeActive = false.obs;

  // Selected distraction apps
  final RxSet<String> selectedDistractionPackages = <String>{}.obs;

  // Loading state
  final RxBool isCheckingPermissions = false.obs;

  int get totalSteps => activeSteps.length;
  bool get canGoBack => currentStepIndex.value > 0;
  OnboardingStepType get currentStepType =>
      activeSteps.isNotEmpty && currentStepIndex.value < activeSteps.length
          ? activeSteps[currentStepIndex.value]
          : OnboardingStepType.welcome;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    _initSteps();
    final saved = _onboardingService.savedStep;
    if (saved > 0 && saved < activeSteps.length) {
      currentStepIndex.value = saved;
    }
    _loadInitialData();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    pageController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-verify permission states when returning from Android Settings
      refreshPermissions();
    }
  }

  void _initSteps({bool includeEnforcement = false}) {
    final steps = <OnboardingStepType>[
      OnboardingStepType.welcome,
      OnboardingStepType.howItWorks,
      OnboardingStepType.distractionApps,
      OnboardingStepType.usageAccess,
      OnboardingStepType.notifications,
      OnboardingStepType.defaultLauncher,
    ];

    if (includeEnforcement) {
      steps.add(OnboardingStepType.enforcement);
    }

    steps.add(OnboardingStepType.protection);
    steps.add(OnboardingStepType.completion);

    activeSteps.assignAll(steps);
  }

  Future<void> _loadInitialData() async {
    final enfReq = await _permissionService.isEnforcementPermissionRequired();
    _initSteps(includeEnforcement: enfReq);

    // 1. Auto-detect distraction apps if available
    if (Get.isRegistered<AppsController>()) {
      final apps = Get.find<AppsController>().allApps;
      if (apps.isNotEmpty) {
        await _appConfigService.autoDetectDistractions(apps);
      }
    }

    // Restore distraction apps selection
    selectedDistractionPackages.assignAll(_appConfigService.distractionPackageNames);

    // 2. Refresh permission states
    await refreshPermissions();

    // 3. Resume from saved step if valid
    final saved = _onboardingService.savedStep;
    if (saved > 0 && saved < activeSteps.length) {
      currentStepIndex.value = saved;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pageController.hasClients) {
          pageController.jumpToPage(saved);
        }
      });
    }
  }

  /// Checks current device state across all permissions
  Future<void> refreshPermissions() async {
    isCheckingPermissions.value = true;
    try {
      final usage = await _permissionService.checkUsageAccess();
      usageAccessGranted.value = usage;

      final notifReq = await _permissionService.isNotificationPermissionRequired();
      isNotificationRequired.value = notifReq;
      if (!notifReq) {
        notificationGranted.value = true;
      } else {
        notificationGranted.value = await _permissionService.checkNotificationPermission();
      }

      final isHome = await _permissionService.isDefaultLauncher();
      defaultLauncherActive.value = isHome;

      final enfReq = await _permissionService.isEnforcementPermissionRequired();
      isEnforcementRequired.value = enfReq;
      if (enfReq) {
        enforcementGranted.value = await _permissionService.checkEnforcementPermission();
      } else {
        enforcementGranted.value = true;
      }

      final isOwner = await _permissionService.isDeviceOwner();
      deviceOwnerActive.value = isOwner;
    } finally {
      isCheckingPermissions.value = false;
    }
  }

  // ── Navigation ───────────────────────────────────────────────

  void nextStep() {
    if (currentStepIndex.value < activeSteps.length - 1) {
      final nextIndex = currentStepIndex.value + 1;
      goToStep(nextIndex);
    }
  }

  void previousStep() {
    if (currentStepIndex.value > 0) {
      final prevIndex = currentStepIndex.value - 1;
      goToStep(prevIndex);
    }
  }

  void goToStep(int index) {
    if (index >= 0 && index < activeSteps.length) {
      currentStepIndex.value = index;
      _onboardingService.saveStep(index);
      if (pageController.hasClients) {
        pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  // ── Step 3: Distraction Apps ─────────────────────────────────

  List<AppInfo> getAvailableApps() {
    if (!Get.isRegistered<AppsController>()) return [];
    final appsController = Get.find<AppsController>();
    // Exclude system apps from distraction suggestions
    final nonSystem = appsController.allApps
        .where((app) => !app.isSystemApp)
        .toList();

    if (selectedDistractionPackages.isEmpty && nonSystem.isNotEmpty) {
      final autoDetected = nonSystem
          .where((app) => _appConfigService.isDistraction(app.packageName))
          .map((app) => app.packageName);
      if (autoDetected.isNotEmpty) {
        selectedDistractionPackages.addAll(autoDetected);
      }
    }

    return nonSystem;
  }

  bool isDistractionSelected(String packageName) {
    return selectedDistractionPackages.contains(packageName);
  }

  Future<void> toggleDistractionApp(String packageName) async {
    if (selectedDistractionPackages.contains(packageName)) {
      selectedDistractionPackages.remove(packageName);
      await _appConfigService.setDistraction(packageName, false);
    } else {
      selectedDistractionPackages.add(packageName);
      await _appConfigService.setDistraction(packageName, true);
    }
  }

  // ── Step 5: Usage Access ─────────────────────────────────────

  Future<void> requestUsageAccess() async {
    await _permissionService.openUsageAccessSettings();
  }

  // ── Step 6: Notifications ────────────────────────────────────

  Future<void> requestNotifications() async {
    final granted = await _permissionService.requestNotificationPermission();
    notificationGranted.value = granted;
    nextStep();
  }

  void skipNotifications() {
    nextStep();
  }

  // ── Step 7: Default Launcher ─────────────────────────────────

  Future<void> requestDefaultLauncher() async {
    await _permissionService.openDefaultLauncherSettings();
  }

  // ── Step 8: Enforcement (if applicable) ──────────────────────

  Future<void> requestEnforcement() async {
    await _permissionService.openEnforcementSettings();
  }

  // ── Step 9: Protection ───────────────────────────────────────

  Future<bool> enableProtection() async {
    if (deviceOwnerActive.value) {
      final success = await _permissionService.enableProtection();
      protectedModeActive.value = success;
      return success;
    }
    return false;
  }

  // ── Step 10: Completion ──────────────────────────────────────

  Future<void> completeOnboarding(BuildContext context) async {
    await _onboardingService.completeOnboarding();
    if (context.mounted) {
      context.go(AppRoutes.launcher);
    }
  }
}
