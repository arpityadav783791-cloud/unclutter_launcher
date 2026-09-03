import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/native_bridge.dart';
import 'package:minimal_launcher/core/services/permission_service.dart';
import 'package:minimal_launcher/core/services/storage_service.dart';
import 'package:minimal_launcher/features/apps/models/app_info.dart';
import 'package:minimal_launcher/features/apps/services/app_config_service.dart';
import 'package:minimal_launcher/features/onboarding/controllers/onboarding_controller.dart';
import 'package:minimal_launcher/features/onboarding/services/onboarding_service.dart';
import '../../helpers/test_helpers.dart';
import 'permission_service_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late MockNativeBridge mockNativeBridge;
  late PermissionService permissionService;
  late OnboardingService onboardingService;
  late AppConfigService appConfigService;
  late OnboardingController controller;

  setUp(() async {
    Get.reset();
    await setupTestStorage();
    storage = StorageService();
    await storage.init();
    Get.put<StorageService>(storage);

    mockNativeBridge = MockNativeBridge();
    Get.put<NativeBridge>(mockNativeBridge);

    permissionService = PermissionService();
    Get.put<PermissionService>(permissionService);

    onboardingService = OnboardingService();
    Get.put<OnboardingService>(onboardingService);

    appConfigService = AppConfigService();
    Get.put<AppConfigService>(appConfigService);
  });

  tearDown(() {
    Get.reset();
  });

  test('1. Fresh installation -> onboardingCompleted is false initially', () {
    expect(onboardingService.isOnboardingCompleted, isFalse);
    expect(onboardingService.savedStep, 0);
  });

  test('2. Onboarding completed -> marks completed so launcher opens directly next time', () async {
    controller = OnboardingController();
    Get.put<OnboardingController>(controller);

    await onboardingService.completeOnboarding();
    expect(onboardingService.isOnboardingCompleted, isTrue);
  });

  test('3. Onboarding interrupted -> resumes from saved step', () async {
    await onboardingService.saveStep(3);

    controller = OnboardingController();
    Get.put<OnboardingController>(controller);

    // Initial step index should resume from savedStep 3
    expect(controller.currentStepIndex.value, 3);
  });

  test('4. Distraction apps selected -> selection persists in AppConfigService', () async {
    controller = OnboardingController();
    Get.put<OnboardingController>(controller);

    const testPackage = 'com.instagram.android';
    expect(controller.isDistractionSelected(testPackage), isFalse);

    await controller.toggleDistractionApp(testPackage);
    expect(controller.isDistractionSelected(testPackage), isTrue);
    expect(appConfigService.isDistraction(testPackage), isTrue);

    // Deselect
    await controller.toggleDistractionApp(testPackage);
    expect(controller.isDistractionSelected(testPackage), isFalse);
    expect(appConfigService.isDistraction(testPackage), isFalse);
  });

  test('5. Usage Access granted -> onboarding detects it', () async {
    mockNativeBridge.usageAccess = true;
    controller = OnboardingController();
    Get.put<OnboardingController>(controller);

    await controller.refreshPermissions();
    expect(controller.usageAccessGranted.value, isTrue);
  });

  test('6. Usage Access denied -> user can skip and continue', () async {
    mockNativeBridge.usageAccess = false;
    controller = OnboardingController();
    Get.put<OnboardingController>(controller);

    await controller.refreshPermissions();
    expect(controller.usageAccessGranted.value, isFalse);

    final initialStep = controller.currentStepIndex.value;
    controller.nextStep();
    expect(controller.currentStepIndex.value, initialStep + 1);
  });

  test('7. Notification permission granted', () async {
    mockNativeBridge.notificationPermission = true;
    mockNativeBridge.notificationRequired = true;
    controller = OnboardingController();
    Get.put<OnboardingController>(controller);

    await controller.requestNotifications();
    expect(controller.notificationGranted.value, isTrue);
  });

  test('8. Notification permission denied -> user continues normally', () async {
    mockNativeBridge.notificationPermission = false;
    mockNativeBridge.notificationRequired = true;
    controller = OnboardingController();
    Get.put<OnboardingController>(controller);

    final initialStep = controller.currentStepIndex.value;
    controller.skipNotifications();
    expect(controller.currentStepIndex.value, initialStep + 1);
  });

  test('9. Default launcher configured -> detects when home is active', () async {
    mockNativeBridge.defaultLauncher = true;
    controller = OnboardingController();
    Get.put<OnboardingController>(controller);

    await controller.refreshPermissions();
    expect(controller.defaultLauncherActive.value, isTrue);
  });

  test('10. Default launcher skipped -> advances without error', () async {
    mockNativeBridge.defaultLauncher = false;
    controller = OnboardingController();
    Get.put<OnboardingController>(controller);

    final initialStep = controller.currentStepIndex.value;
    controller.nextStep();
    expect(controller.currentStepIndex.value, initialStep + 1);
  });

  test('11 & 12. Enforcement permission handling', () async {
    mockNativeBridge.enforcementPermission = true;
    mockNativeBridge.enforcementRequired = false;
    controller = OnboardingController();
    Get.put<OnboardingController>(controller);

    await controller.refreshPermissions();
    expect(controller.enforcementGranted.value, isTrue);
    expect(controller.isEnforcementRequired.value, isFalse);
  });

  test('13. Device Owner detected', () async {
    mockNativeBridge.deviceOwner = true;
    controller = OnboardingController();
    Get.put<OnboardingController>(controller);

    await controller.refreshPermissions();
    expect(controller.deviceOwnerActive.value, isTrue);

    final enabled = await controller.enableProtection();
    expect(enabled, isTrue);
    expect(controller.protectedModeActive.value, isTrue);
  });

  test('14. Device Owner unavailable', () async {
    mockNativeBridge.deviceOwner = false;
    controller = OnboardingController();
    Get.put<OnboardingController>(controller);

    await controller.refreshPermissions();
    expect(controller.deviceOwnerActive.value, isFalse);

    final enabled = await controller.enableProtection();
    expect(enabled, isFalse);
    expect(controller.protectedModeActive.value, isFalse);
  });

  test('15. Completion state persists correctly', () async {
    controller = OnboardingController();
    Get.put<OnboardingController>(controller);

    await onboardingService.saveStep(4);
    expect(onboardingService.savedStep, 4);

    await onboardingService.completeOnboarding();
    expect(onboardingService.isOnboardingCompleted, isTrue);
    expect(onboardingService.savedStep, 0);
  });

  test('16. Existing launcher behavior remains unchanged with AppConfig and Distraction', () async {
    const app = AppInfo(name: 'Test Social', packageName: 'com.test.social');
    expect(appConfigService.isDistraction(app.packageName), isFalse);

    await appConfigService.setDistraction(app.packageName, true);
    expect(appConfigService.isDistraction(app.packageName), isTrue);
    expect(appConfigService.distractionPackageNames.contains(app.packageName), isTrue);

    // Existing app renaming and hiding still works seamlessly
    await appConfigService.setCustomName(app.packageName, 'Focus Mode Social');
    expect(appConfigService.displayName(app.packageName, app.name), 'Focus Mode Social');

    await appConfigService.setHidden(app.packageName, true);
    expect(appConfigService.isHidden(app.packageName), isTrue);
  });
}
