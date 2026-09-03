import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/minimal_text.dart';
import '../../controllers/onboarding_controller.dart';
import '../../widgets/onboarding_button.dart';

class ProtectionPage extends StatelessWidget {
  final OnboardingController controller;
  final VoidCallback onNext;

  const ProtectionPage({
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
                  'Optional Advanced Setup',
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
            'Protect your Digital Detox setup.',
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
            'Protection can make it harder to bypass your Digital Detox restrictions by preventing uninstallation or accidental removal.',
            style: TextStyle(
              fontSize: 16,
              color: secondaryColor,
              height: 1.5,
            ),
            maxLines: 4,
          ),
          const Spacer(),
          Obx(() {
            final isOwner = controller.deviceOwnerActive.value;
            final isProtected = controller.protectedModeActive.value;

            if (isProtected) {
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
                    const Icon(Icons.shield_outlined,
                        color: AppColors.accent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MinimalText(
                        'Device Owner Protection Active',
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

            if (isOwner) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MinimalText(
                      'Device Owner is provisioned on this device.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    MinimalText(
                      'You can enable strict anti-uninstall protection now or later in Settings.',
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                        height: 1.4,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MinimalText(
                    'Device Owner is not provisioned.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  MinimalText(
                    'This is an optional feature requiring advanced device provisioning (via ADB / factory setup). You can safely skip this step.',
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryColor,
                      height: 1.4,
                    ),
                    maxLines: 4,
                  ),
                ],
              ),
            );
          }),
          const Spacer(),
          Obx(() {
            final isOwner = controller.deviceOwnerActive.value;
            final isProtected = controller.protectedModeActive.value;

            if (isProtected) {
              return OnboardingButton(
                text: 'Continue',
                onPressed: onNext,
              );
            }

            if (isOwner) {
              return Column(
                children: [
                  OnboardingButton(
                    text: 'Set Up Protection',
                    onPressed: () async {
                      await controller.enableProtection();
                      onNext();
                    },
                  ),
                  const SizedBox(height: 10),
                  OnboardingButton(
                    text: 'Skip',
                    isSecondary: true,
                    onPressed: onNext,
                  ),
                ],
              );
            }

            return Column(
              children: [
                OnboardingButton(
                  text: 'Continue',
                  onPressed: onNext,
                ),
                const SizedBox(height: 10),
                OnboardingButton(
                  text: 'Skip',
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
