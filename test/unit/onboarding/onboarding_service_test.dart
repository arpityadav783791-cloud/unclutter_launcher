import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/storage_service.dart';
import 'package:minimal_launcher/features/onboarding/services/onboarding_service.dart';
import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late OnboardingService onboardingService;

  setUp(() async {
    Get.reset();
    await setupTestStorage();
    storageService = StorageService();
    await storageService.init();
    Get.put<StorageService>(storageService);
    onboardingService = OnboardingService();
    Get.put<OnboardingService>(onboardingService);
  });

  tearDown(() {
    Get.reset();
  });

  test('1. Fresh installation detects onboarding not completed and step at 0', () {
    expect(onboardingService.isOnboardingCompleted, isFalse);
    expect(onboardingService.savedStep, 0);
  });

  test('3. Onboarding interrupted persists and resumes from saved step', () async {
    await onboardingService.saveStep(4);
    expect(onboardingService.savedStep, 4);
    expect(onboardingService.isOnboardingCompleted, isFalse);
  });

  test('15. Completion state persists and resets step counter', () async {
    await onboardingService.saveStep(5);
    await onboardingService.completeOnboarding();

    expect(onboardingService.isOnboardingCompleted, isTrue);
    expect(onboardingService.savedStep, 0);
  });

  test('2. Onboarding completed allows launcher to open directly next time', () async {
    await onboardingService.completeOnboarding();
    expect(onboardingService.isOnboardingCompleted, isTrue);
  });

  test('Reset onboarding restores fresh installation state', () async {
    await onboardingService.completeOnboarding();
    expect(onboardingService.isOnboardingCompleted, isTrue);

    await onboardingService.resetOnboarding();
    expect(onboardingService.isOnboardingCompleted, isFalse);
    expect(onboardingService.savedStep, 0);
  });
}
