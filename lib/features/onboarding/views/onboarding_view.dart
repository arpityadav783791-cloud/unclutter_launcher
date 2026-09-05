import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/onboarding_progress.dart';
import 'pages/welcome_page.dart';
import 'pages/how_it_works_page.dart';
import 'pages/distraction_apps_page.dart';
import 'pages/usage_access_page.dart';
import 'pages/notification_page.dart';
import 'pages/launcher_setup_page.dart';
import 'pages/enforcement_permission_page.dart';
import 'pages/protection_page.dart';
import 'pages/completion_page.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (controller.canGoBack) {
          controller.previousStep();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // Top Progress Header
              Obx(() {
                return OnboardingProgress(
                  currentStep: controller.currentStepIndex.value,
                  totalSteps: controller.totalSteps,
                  onBack: controller.canGoBack
                      ? () => controller.previousStep()
                      : null,
                );
              }),
              // Step Pages
              Expanded(
                child: Obx(() {
                  final steps = controller.activeSteps;
                  return PageView.builder(
                    controller: controller.pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: steps.length,
                    itemBuilder: (context, index) {
                      final stepType = steps[index];
                      return _buildPageForStep(controller, stepType);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageForStep(
      OnboardingController controller, OnboardingStepType stepType) {
    switch (stepType) {
      case OnboardingStepType.welcome:
        return WelcomePage(onNext: controller.nextStep);
      case OnboardingStepType.howItWorks:
        return HowItWorksPage(onNext: controller.nextStep);
      case OnboardingStepType.distractionApps:
        return DistractionAppsPage(
          controller: controller,
          onNext: controller.nextStep,
        );
      case OnboardingStepType.usageAccess:
        return UsageAccessPage(
          controller: controller,
          onNext: controller.nextStep,
        );
      case OnboardingStepType.notifications:
        return NotificationPage(
          controller: controller,
          onNext: controller.nextStep,
        );
      case OnboardingStepType.defaultLauncher:
        return LauncherSetupPage(
          controller: controller,
          onNext: controller.nextStep,
        );
      case OnboardingStepType.enforcement:
        return EnforcementPermissionPage(
          controller: controller,
          onNext: controller.nextStep,
        );
      case OnboardingStepType.protection:
        return ProtectionPage(
          controller: controller,
          onNext: controller.nextStep,
        );
      case OnboardingStepType.completion:
        return CompletionPage(controller: controller);
    }
  }
}
