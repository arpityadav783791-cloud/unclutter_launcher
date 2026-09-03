import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';

class LimitReachedView extends StatelessWidget {
  final String appName;
  final String packageName;
  final VoidCallback onClose;
  final VoidCallback onExtend;

  const LimitReachedView({
    super.key,
    required this.appName,
    required this.packageName,
    required this.onClose,
    required this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              MinimalText(
                "You've reached your limit\nfor $appName",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 48),

              // Actions – minimal, not aggressive
              GestureDetector(
                onTap: onClose,
                child: MinimalText(
                  'Close',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              GestureDetector(
                onTap: onExtend,
                child: MinimalText(
                  'Extend 5 minutes',
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryColor,
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
