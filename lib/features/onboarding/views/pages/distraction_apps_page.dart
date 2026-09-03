import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/minimal_text.dart';
import '../../../apps/controllers/apps_controller.dart';
import '../../controllers/onboarding_controller.dart';
import '../../widgets/onboarding_app_tile.dart';
import '../../widgets/onboarding_button.dart';

class DistractionAppsPage extends StatelessWidget {
  final OnboardingController controller;
  final VoidCallback onNext;

  const DistractionAppsPage({
    super.key,
    required this.controller,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          MinimalText(
            'Select distraction apps.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          MinimalText(
            'Choose the apps that tempt you to scroll (e.g., social media, video feeds, games).',
            style: TextStyle(
              fontSize: 15,
              color: secondaryColor,
              height: 1.4,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              final appsController = Get.isRegistered<AppsController>()
                  ? Get.find<AppsController>()
                  : null;

              if (appsController != null && appsController.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                  ),
                );
              }

              // Subscribes to apps list and selected distraction packages
              final apps = controller.getAvailableApps();
              final selected = controller.selectedDistractionPackages.toSet();

              if (apps.isEmpty) {
                return Center(
                  child: MinimalText(
                    'No non-system apps found',
                    style: TextStyle(
                      fontSize: 15,
                      color: secondaryColor,
                    ),
                  ),
                );
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: apps.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Colors.transparent,
                ),
                itemBuilder: (context, index) {
                  final app = apps[index];
                  final isSelected = selected.contains(app.packageName);
                  final displayName = appsController != null
                      ? appsController.displayName(app)
                      : app.name;

                  return OnboardingAppTile(
                    appName: displayName,
                    packageName: app.packageName,
                    isSelected: isSelected,
                    onToggle: () {
                      controller.toggleDistractionApp(app.packageName);
                    },
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final count = controller.selectedDistractionPackages.length;
            final subtitle = count == 0
                ? 'No apps selected (you can change this anytime in Settings)'
                : '$count app${count == 1 ? '' : 's'} selected as distraction';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: MinimalText(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            );
          }),
          OnboardingButton(
            text: 'Continue',
            onPressed: onNext,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
