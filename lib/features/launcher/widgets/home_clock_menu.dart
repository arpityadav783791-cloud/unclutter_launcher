import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/native_bridge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';
import '../../focus_mode/controllers/focus_mode_controller.dart';
import '../../focus_mode/models/focus_mode_config.dart';
import 'app_options_bottom_sheet.dart';

/// Shows the quick actions bottom sheet triggered by tapping/long-pressing the clock.
void showHomeClockMenu(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  final focusController = Get.find<FocusModeController>();

  showModalBottomSheet(
    context: context,
    backgroundColor:
        isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MinimalText(
                'Quick actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 1,
                color: secondaryColor.withValues(alpha: 0.12),
              ),
              OptionTile(
                label: 'Clock',
                color: textColor,
                onTap: () {
                  Navigator.pop(ctx);
                  if (Get.isRegistered<NativeBridge>()) {
                    Get.find<NativeBridge>().openClock();
                  }
                },
              ),
              OptionTile(
                label: 'Calendar',
                color: textColor,
                onTap: () {
                  Navigator.pop(ctx);
                  if (Get.isRegistered<NativeBridge>()) {
                    Get.find<NativeBridge>().openCalendar();
                  }
                },
              ),
              OptionTile(
                label: 'Screen Time',
                color: textColor,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.screenTime);
                },
              ),
              OptionTile(
                label: 'Settings',
                color: textColor,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.settings);
                },
              ),
              Obx(() {
                final active = focusController.isActive.value;
                return OptionTile(
                  label: active
                      ? 'Stop Focus Mode (${focusController.remainingText.value})'
                      : 'Start Focus Mode',
                  color: textColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (active) {
                      focusController.stop();
                    } else {
                      showStartFocusModeBottomSheet(context);
                    }
                  },
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}

/// Shows the duration selection sheet to initiate focus mode.
void showStartFocusModeBottomSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  final focusController = Get.find<FocusModeController>();

  showModalBottomSheet(
    context: context,
    backgroundColor:
        isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MinimalText(
                'Start Focus Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              MinimalText(
                'Apps in your block list will be locked',
                style: TextStyle(fontSize: 13, color: secondaryColor),
              ),
              const SizedBox(height: 20),
              Container(
                height: 1,
                color: secondaryColor.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 8),
              ...FocusModeConfig.availableDurationsMinutes.map((minutes) {
                final label = minutes < 60
                    ? '$minutes min'
                    : (minutes == 60
                        ? '1 hour'
                        : '${minutes ~/ 60} hours');
                return OptionTile(
                  label: label,
                  color: textColor,
                  onTap: () async {
                    await focusController.start(minutes);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
