import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';
import '../controllers/mindful_delay_controller.dart';

class MindfulDelayView extends StatelessWidget {
  const MindfulDelayView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    final controller = Get.find<MindfulDelayController>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Question
              Obx(() => MinimalText(
                    'Do you really want to open\n${controller.appName.value}?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                      height: 1.4,
                    ),
                  )),

              const SizedBox(height: 48),

              // Countdown number
              Obx(() => MinimalText(
                    '${controller.remainingSeconds.value}',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w200,
                      color: textColor,
                      letterSpacing: -2,
                    ),
                  )),

              const SizedBox(height: 12),

              MinimalText(
                'seconds',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryColor,
                ),
              ),

              const Spacer(flex: 3),

              // No cancel button – intentional
              MinimalText(
                'Opening automatically…',
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryColor.withValues(alpha: 0.6),
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
