import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/minimal_text.dart';
import '../../widgets/onboarding_button.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomePage({super.key, required this.onNext});

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
          const Spacer(flex: 2),
          MinimalText(
            'Take back control of your phone.',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.2,
              letterSpacing: -0.5,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          MinimalText(
            'Minimalist helps you reduce distracting screen time and use your phone intentionally.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: secondaryColor,
              height: 1.5,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          MinimalText(
            'Designed specifically to break the habit of mindless scrolling on social media, video streaming, and gaming apps.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: secondaryColor.withValues(alpha: 0.8),
              height: 1.4,
            ),
            maxLines: 4,
          ),
          const Spacer(flex: 3),
          OnboardingButton(
            text: 'Get Started',
            onPressed: onNext,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
