import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';

/// Service managing persistent onboarding state across launches.
class OnboardingService extends GetxService {
  static const String keyCompleted = 'onboarding_completed';
  static const String keyCurrentStep = 'onboarding_step';

  final StorageService _storage = Get.find<StorageService>();

  /// Returns true if onboarding has ever been successfully completed.
  bool get isOnboardingCompleted =>
      _storage.getBool(keyCompleted, defaultValue: false);

  /// Returns the last saved step index (0-based) to resume from if interrupted.
  int get savedStep => _storage.getInt(keyCurrentStep, defaultValue: 0);

  /// Saves the current step progress.
  Future<void> saveStep(int step) async {
    await _storage.setInt(keyCurrentStep, step);
  }

  /// Marks onboarding as permanently completed and resets step pointer.
  Future<void> completeOnboarding() async {
    await _storage.setBool(keyCompleted, true);
    await _storage.setInt(keyCurrentStep, 0);
  }

  /// Resets onboarding state (primarily for testing and debug).
  Future<void> resetOnboarding() async {
    await _storage.setBool(keyCompleted, false);
    await _storage.setInt(keyCurrentStep, 0);
  }
}
