import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/native_bridge.dart';
import '../../../core/widgets/minimal_text.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/launcher_controller.dart';
import 'screen_time_picker_sheet.dart';

/// Single Responsibility: Renders time, date, battery level, and screen time respecting settings.
class HomeClockWidget extends StatelessWidget {
  final LauncherController controller;
  final Color textColor;
  final Color secondaryColor;
  final VoidCallback onLongPress;

  const HomeClockWidget({
    super.key,
    required this.controller,
    required this.textColor,
    required this.secondaryColor,
    required this.onLongPress,
  });

  CrossAxisAlignment _resolveCrossAxis(String alignment) {
    switch (alignment) {
      case 'center':
        return CrossAxisAlignment.center;
      case 'right':
        return CrossAxisAlignment.end;
      case 'left':
      default:
        return CrossAxisAlignment.start;
    }
  }

  TextAlign _resolveTextAlign(String alignment) {
    switch (alignment) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'left':
      default:
        return TextAlign.left;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();

    return Obx(() {
      final visibility = settings.dateTimeVisibility.value;
      if (visibility == 'off') return const SizedBox.shrink();

      final isDateOnly = visibility == 'date_only';
      final showClock = !isDateOnly && settings.showClock.value;
      final showDate = settings.showDate.value;
      final showScreenTime = settings.showScreenTime.value;
      final alignment = settings.homeAlignment.value;
      final crossAxis = _resolveCrossAxis(alignment);
      final textAlign = _resolveTextAlign(alignment);
      final isBold = settings.boldFont.value;

      final batteryText = (!settings.showStatusBar.value &&
              controller.batteryLevel.value >= 0)
          ? ', ${controller.batteryLevel.value}%'
          : '';

      return GestureDetector(
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: crossAxis,
          children: [
            if (showClock)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (Get.isRegistered<NativeBridge>()) {
                    Get.find<NativeBridge>().openClock();
                  }
                },
                child: MinimalText(
                  controller.currentTime.value,
                  textAlign: textAlign,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: textColor,
                        fontWeight: isBold ? FontWeight.w700 : FontWeight.w300,
                      ),
                ),
              ),
            if (showClock && showDate) const SizedBox(height: 2),
            if (showDate)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (Get.isRegistered<NativeBridge>()) {
                    Get.find<NativeBridge>().openCalendar();
                  }
                },
                child: MinimalText(
                  '${controller.currentDate.value}$batteryText',
                  textAlign: textAlign,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: secondaryColor,
                        fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                      ),
                ),
              ),
            if (showScreenTime && controller.todayScreenTime.value.isNotEmpty) ...[
              const SizedBox(height: 3),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (Get.isRegistered<NativeBridge>()) {
                    Get.find<NativeBridge>().openScreenTimeApp(
                      customPackage: settings.customScreenTimePackage.value,
                    );
                  }
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  showScreenTimeOptionsBottomSheet(context);
                },
                child: MinimalText(
                  controller.todayScreenTime.value,
                  textAlign: textAlign,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: secondaryColor.withValues(alpha: 0.8),
                        fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
