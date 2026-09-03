import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/minimal_text.dart';
import '../../widgets/onboarding_button.dart';

class TimedAccessPage extends StatelessWidget {
  final VoidCallback onNext;

  const TimedAccessPage({super.key, required this.onNext});

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
          MinimalText(
            'Choose your time before you scroll.',
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
            'When you open a distraction app, Minimalist asks how much time you want to spend before allowing access.',
            style: TextStyle(
              fontSize: 16,
              color: secondaryColor,
              height: 1.4,
            ),
            maxLines: 4,
          ),
          const Spacer(),
          // Example duration pills showing the mechanism without triggering an app session
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: secondaryColor.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MinimalText(
                    'Preview: How much time?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: secondaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildPreviewPill('5 min', isDark: isDark, isSelected: false),
                      _buildPreviewPill('10 min', isDark: isDark, isSelected: true),
                      _buildPreviewPill('15 min', isDark: isDark, isSelected: false),
                      _buildPreviewPill('Custom (up to 60m)', isDark: isDark, isSelected: false),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          MinimalText(
            'When your time is up, access ends and you decide whether you really need more time.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: secondaryColor,
              height: 1.4,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          MinimalText(
            'Custom duration lets you pick any duration from 1 up to 60 minutes.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: secondaryColor.withValues(alpha: 0.8),
            ),
            maxLines: 2,
          ),
          const Spacer(),
          OnboardingButton(
            text: 'Got it',
            onPressed: onNext,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPreviewPill(
    String label, {
    required bool isDark,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isSelected
            ? (isDark ? Colors.white : Colors.black)
            : (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05)),
      ),
      child: MinimalText(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected
              ? (isDark ? Colors.black : Colors.white)
              : (isDark ? AppColors.darkText : AppColors.lightText),
        ),
      ),
    );
  }
}
