class OnboardingState {
  final int currentStep;
  final int totalSteps;
  final bool usageAccessGranted;
  final bool notificationGranted;
  final bool defaultLauncherActive;
  final bool enforcementGranted;
  final bool deviceOwnerActive;
  final bool protectedModeActive;
  final int distractionAppsCount;
  final bool isCompleted;

  const OnboardingState({
    this.currentStep = 0,
    this.totalSteps = 9,
    this.usageAccessGranted = false,
    this.notificationGranted = false,
    this.defaultLauncherActive = false,
    this.enforcementGranted = false,
    this.deviceOwnerActive = false,
    this.protectedModeActive = false,
    this.distractionAppsCount = 0,
    this.isCompleted = false,
  });

  OnboardingState copyWith({
    int? currentStep,
    int? totalSteps,
    bool? usageAccessGranted,
    bool? notificationGranted,
    bool? defaultLauncherActive,
    bool? enforcementGranted,
    bool? deviceOwnerActive,
    bool? protectedModeActive,
    int? distractionAppsCount,
    bool? isCompleted,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      usageAccessGranted: usageAccessGranted ?? this.usageAccessGranted,
      notificationGranted: notificationGranted ?? this.notificationGranted,
      defaultLauncherActive:
          defaultLauncherActive ?? this.defaultLauncherActive,
      enforcementGranted: enforcementGranted ?? this.enforcementGranted,
      deviceOwnerActive: deviceOwnerActive ?? this.deviceOwnerActive,
      protectedModeActive: protectedModeActive ?? this.protectedModeActive,
      distractionAppsCount: distractionAppsCount ?? this.distractionAppsCount,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
