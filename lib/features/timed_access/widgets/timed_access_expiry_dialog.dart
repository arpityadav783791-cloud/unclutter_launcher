import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/minimal_text.dart';
import '../controllers/timed_access_controller.dart';
import '../domain/entities/timed_access_session.dart';

/// Expiry DialogBox presented when a Timed Access session reaches expiration.
/// Displays options to Extend Time (5, 10, 15, 30 min) or Take Me Out of Here.
/// Prevents accidental dismissal to ensure an explicit user decision.
class TimedAccessExpiryDialog extends StatelessWidget {
  final TimedAccessSession session;

  const TimedAccessExpiryDialog({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<TimedAccessController>()
        ? Get.find<TimedAccessController>()
        : Get.put(TimedAccessController());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final bgColor = isDark ? const Color(0xFF161616) : Colors.white;

    final appName = controller.selectedApp.value?.name ??
        _formatPackageName(session.packageName);

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderXl,
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon Header
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: secondaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.timer_off_outlined,
                    size: 26,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Center(
                child: MinimalText(
                  'Timed Access Ended',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Center(
                child: MinimalText(
                  'Time limit reached for $appName.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Extend presets label
              MinimalText(
                'Need more time?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),

              // Extension Preset Chips (5, 10, 15, 30 min)
              Obx(() {
                final selected = controller.selectedExtensionMinutes.value;
                return Row(
                  children: TimedAccessController.extensionPresets.map((minutes) {
                    final isSelected = selected == minutes;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: InkWell(
                          onTap: () {
                            controller.selectedExtensionMinutes.value = minutes;
                          },
                          borderRadius: AppRadius.borderMd,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.borderMd,
                              border: Border.all(
                                color: isSelected
                                    ? textColor
                                    : secondaryColor.withValues(alpha: 0.25),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              color: isSelected
                                  ? secondaryColor.withValues(alpha: 0.15)
                                  : Colors.transparent,
                            ),
                            child: Center(
                              child: MinimalText(
                                '$minutes m',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected ? textColor : secondaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 16),

              // Extend Time Button
              Obx(() {
                final isExtending = controller.isExtending.value;
                final isTerminating = controller.isTerminating.value;
                final minutes = controller.selectedExtensionMinutes.value;
                final busy = isExtending || isTerminating;

                return SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: busy
                        ? null
                        : () => controller.extendSession(
                              Duration(minutes: minutes),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: textColor,
                      foregroundColor: bgColor,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.borderFull,
                      ),
                    ),
                    child: isExtending
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(bgColor),
                            ),
                          )
                        : MinimalText(
                            'Extend $minutes min',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: bgColor,
                            ),
                          ),
                  ),
                );
              }),
              const SizedBox(height: 10),

              // Take Me Out of Here Button
              Obx(() {
                final isExtending = controller.isExtending.value;
                final isTerminating = controller.isTerminating.value;
                final busy = isExtending || isTerminating;

                return SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: busy ? null : controller.takeMeOut,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(
                        color: secondaryColor.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.borderFull,
                      ),
                    ),
                    child: isTerminating
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(textColor),
                            ),
                          )
                        : MinimalText(
                            'Take Me Out of Here',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPackageName(String packageName) {
    if (packageName.isEmpty) return 'App';
    final parts = packageName.split('.');
    final last = parts.isNotEmpty ? parts.last : packageName;
    if (last.isEmpty) return packageName;
    return '${last[0].toUpperCase()}${last.substring(1)}';
  }
}
