import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';

class ScheduleBlockedView extends StatelessWidget {
  final String appName;
  final String scheduleLabel;

  const ScheduleBlockedView({
    super.key,
    required this.appName,
    required this.scheduleLabel,
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
                'Scheduled block',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 16),

              MinimalText(
                appName,
                style: TextStyle(
                  fontSize: 18,
                  color: secondaryColor,
                ),
              ),

              const SizedBox(height: 24),

              MinimalText(
                scheduleLabel,
                style: TextStyle(
                  fontSize: 15,
                  color: secondaryColor.withValues(alpha: 0.7),
                ),
              ),

              const Spacer(flex: 3),

              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: MinimalText(
                  'Close',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
