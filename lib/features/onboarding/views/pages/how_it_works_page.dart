import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/minimal_text.dart';
import '../../widgets/onboarding_button.dart';

class HowItWorksPage extends StatelessWidget {
  final VoidCallback onNext;

  const HowItWorksPage({super.key, required this.onNext});

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
            'How it works.',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          MinimalText(
            'A gentle friction model to keep you present.',
            style: TextStyle(
              fontSize: 16,
              color: secondaryColor,
            ),
          ),
          const Spacer(),
          _buildConceptRow(
            context,
            number: '01',
            title: 'Choose distracting apps',
            description:
                'Select the apps that pull you in without you noticing.',
            textColor: textColor,
            secondaryColor: secondaryColor,
          ),
          const SizedBox(height: 32),
          _buildConceptRow(
            context,
            number: '02',
            title: 'Decide how long you want to use them',
            description:
                'Set an intentional timer before the app opens (5, 10, 15 min or custom).',
            textColor: textColor,
            secondaryColor: secondaryColor,
          ),
          const SizedBox(height: 32),
          _buildConceptRow(
            context,
            number: '03',
            title: 'Stay focused without mindless scrolling',
            description:
                'When time expires, access ends and you return to your minimalist home screen.',
            textColor: textColor,
            secondaryColor: secondaryColor,
          ),
          const Spacer(),
          OnboardingButton(
            text: 'Continue',
            onPressed: onNext,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildConceptRow(
    BuildContext context, {
    required String number,
    required String title,
    required String description,
    required Color textColor,
    required Color secondaryColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MinimalText(
          number,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: secondaryColor.withValues(alpha: 0.6),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MinimalText(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: 0.1,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 6),
              MinimalText(
                description,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: secondaryColor,
                  height: 1.4,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
