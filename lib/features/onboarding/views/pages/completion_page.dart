import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/minimal_text.dart';
import '../../controllers/onboarding_controller.dart';
import '../../widgets/onboarding_button.dart';

class CompletionPage extends StatelessWidget {
  final OnboardingController controller;

  const CompletionPage({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          MinimalText(
            "You're ready.",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          MinimalText(
            'Your phone is now designed to help you use it less.',
            style: TextStyle(
              fontSize: 16,
              color: secondaryColor,
              height: 1.5,
            ),
            maxLines: 3,
          ),
          const Spacer(),
          // Setup Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: secondaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Obx(() {
              final distractionCount =
                  controller.selectedDistractionPackages.length;
              final hasUsage = controller.usageAccessGranted.value;
              final isDefault = controller.defaultLauncherActive.value;
              final isProtected = controller.protectedModeActive.value ||
                  controller.deviceOwnerActive.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MinimalText(
                    'SETUP SUMMARY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: secondaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryItem(
                    isConfigured: distractionCount > 0,
                    configuredLabel:
                        'Distraction apps selected ($distractionCount)',
                    unconfiguredLabel: 'No distraction apps selected',
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                  const SizedBox(height: 14),
                  _buildSummaryItem(
                    isConfigured: true,
                    configuredLabel: 'Timed access enabled',
                    unconfiguredLabel: 'Timed access disabled',
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                  const SizedBox(height: 14),
                  _buildSummaryItem(
                    isConfigured: hasUsage,
                    configuredLabel: 'Screen-time tracking active',
                    unconfiguredLabel: 'Screen-time tracking skipped',
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                  const SizedBox(height: 14),
                  _buildSummaryItem(
                    isConfigured: isDefault,
                    configuredLabel: 'Minimalist launcher default',
                    unconfiguredLabel: 'Default launcher not set',
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                  const SizedBox(height: 14),
                  _buildSummaryItem(
                    isConfigured: isProtected,
                    configuredLabel: 'Device Owner protection active',
                    unconfiguredLabel: 'Protection not enabled (optional)',
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                ],
              );
            }),
          ),
          const Spacer(),
          OnboardingButton(
            text: 'Start Detox',
            onPressed: () => controller.completeOnboarding(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required bool isConfigured,
    required String configuredLabel,
    required String unconfiguredLabel,
    required Color textColor,
    required Color secondaryColor,
  }) {
    return Row(
      children: [
        Icon(
          isConfigured ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          size: 18,
          color: isConfigured
              ? AppColors.accent
              : secondaryColor.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MinimalText(
            isConfigured ? configuredLabel : unconfiguredLabel,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isConfigured ? FontWeight.w500 : FontWeight.w400,
              color: isConfigured
                  ? textColor
                  : secondaryColor.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}
