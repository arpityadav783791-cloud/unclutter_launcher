import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/minimal_text.dart';
import '../../controllers/onboarding_controller.dart';
import '../../widgets/onboarding_button.dart';

class UsageAccessPage extends StatelessWidget {
  final OnboardingController controller;
  final VoidCallback onNext;

  const UsageAccessPage({
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
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                child: MinimalText(
                  'Recommended',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: secondaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MinimalText(
            'Understand where your time goes.',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.2,
              letterSpacing: -0.5,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          MinimalText(
            'Usage Access lets Minimalist measure app usage and provide screen-time and daily-limit features.',
            style: TextStyle(
              fontSize: 16,
              color: secondaryColor,
              height: 1.5,
            ),
            maxLines: 4,
          ),
          const Spacer(),
          Obx(() {
            final isGranted = controller.usageAccessGranted.value;
            if (isGranted) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.accent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MinimalText(
                        'Usage Access is granted',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                border: Border.all(
                  color: secondaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: MinimalText(
                'Without Usage Access, screen-time statistics and daily limits may not function, but you can still use the launcher.',
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryColor,
                  height: 1.4,
                ),
                maxLines: 4,
              ),
            );
          }),
          const Spacer(),
          Obx(() {
            final isGranted = controller.usageAccessGranted.value;
            if (isGranted) {
              return OnboardingButton(
                text: 'Continue',
                onPressed: onNext,
              );
            }

            return Column(
              children: [
                OnboardingButton(
                  text: 'Allow Usage Access',
                  onPressed: () async {
                    await controller.requestUsageAccess();
                  },
                ),
                const SizedBox(height: 10),
                OnboardingButton(
                  text: 'Skip for now',
                  isSecondary: true,
                  onPressed: onNext,
                ),
              ],
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
