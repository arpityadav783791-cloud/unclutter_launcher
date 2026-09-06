import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/minimal_text.dart';
import '../../apps/models/app_info.dart';
import '../controllers/timed_access_controller.dart';

void showTimedAccessBottomSheet(
  BuildContext context, {
  required AppInfo app,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bgColor = isDark ? const Color(0xFF111111) : AppColors.lightBackground;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: bgColor,
    shape: const RoundedRectangleBorder(
      borderRadius: AppRadius.topXl,
    ),
    builder: (sheetContext) => TimedAccessBottomSheet(app: app),
  );
}

class TimedAccessBottomSheet extends StatefulWidget {
  final AppInfo app;

  const TimedAccessBottomSheet({
    super.key,
    required this.app,
  });

  @override
  State<TimedAccessBottomSheet> createState() => _TimedAccessBottomSheetState();
}

class _TimedAccessBottomSheetState extends State<TimedAccessBottomSheet> {
  final TextEditingController _customController = TextEditingController();
  final FocusNode _customFocusNode = FocusNode();
  bool _showCustomInput = false;

  @override
  void dispose() {
    _customController.dispose();
    _customFocusNode.dispose();
    super.dispose();
  }

  void _onCustomTapped(TimedAccessController controller) {
    setState(() {
      _showCustomInput = !_showCustomInput;
    });
    if (_showCustomInput) {
      _customFocusNode.requestFocus();
    } else {
      _customFocusNode.unfocus();
    }
  }

  void _onCustomSubmitted(String value, TimedAccessController controller) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null && controller.setCustomDuration(parsed)) {
      _customFocusNode.unfocus();
    } else {
      HapticFeedback.heavyImpact();
      Get.rawSnackbar(
        message: 'Enter a duration between 1 and ${TimedAccessController.maxCustomMinutes} minutes.',
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<TimedAccessController>()
        ? Get.find<TimedAccessController>()
        : Get.put(TimedAccessController());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final bgColor = isDark ? const Color(0xFF111111) : AppColors.lightBackground;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xxl,
        right: AppSpacing.xxl,
        top: AppSpacing.lg,
        bottom: AppSpacing.xxl + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: secondaryColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title & Subtitle
          Center(
            child: MinimalText(
              'Timed Access',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: MinimalText(
              'How long do you need?',
              style: TextStyle(
                fontSize: 14,
                color: secondaryColor,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Presets Grid (5m, 10m, 15m, 30m)
          Row(
            children: [
              Expanded(
                child: _buildDurationButton(
                  minutes: 5,
                  label: '5 m',
                  controller: controller,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                  bgColor: bgColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDurationButton(
                  minutes: 10,
                  label: '10 m',
                  controller: controller,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                  bgColor: bgColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDurationButton(
                  minutes: 15,
                  label: '15 m',
                  controller: controller,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                  bgColor: bgColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDurationButton(
                  minutes: 30,
                  label: '30 m',
                  controller: controller,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                  bgColor: bgColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Custom Duration Button
          Obx(() {
            final isCustomActive = controller.isCustom.value;
            return GestureDetector(
              onTap: () => _onCustomTapped(controller),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(
                    color: isCustomActive
                        ? textColor
                        : secondaryColor.withValues(alpha: 0.25),
                    width: isCustomActive ? 1.5 : 1.0,
                  ),
                  color: isCustomActive
                      ? secondaryColor.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
                child: Center(
                  child: MinimalText(
                    isCustomActive
                        ? 'Custom (${controller.customDurationMinutes.value} m)'
                        : 'Custom',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isCustomActive ? FontWeight.w600 : FontWeight.w500,
                      color: isCustomActive ? textColor : secondaryColor,
                    ),
                  ),
                ),
              ),
            );
          }),

          // Inline Custom Input Field
          if (_showCustomInput) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    focusNode: _customFocusNode,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor, fontSize: 15),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter minutes (1 - ${TimedAccessController.maxCustomMinutes})',
                      hintStyle: TextStyle(
                        color: secondaryColor.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: secondaryColor.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderSm,
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (val) => _onCustomSubmitted(val, controller),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () =>
                      _onCustomSubmitted(_customController.text, controller),
                  child: MinimalText(
                    'Set',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Selected duration display
          Obx(() {
            final duration = controller.effectiveDurationMinutes;
            final minuteText = duration == 1 ? 'minute' : 'minutes';
            return Center(
              child: MinimalText(
                'Selected: $duration $minuteText',
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // Start Button
          Obx(() {
            final loading = controller.isStarting.value;
            return SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: loading
                    ? null
                    : () => controller.startSessionAndLaunch(
                          app: widget.app,
                          durationMinutes: controller.effectiveDurationMinutes,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: textColor,
                  foregroundColor: bgColor,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.borderFull,
                  ),
                ),
                child: loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: bgColor,
                        ),
                      )
                    : const Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDurationButton({
    required int minutes,
    required String label,
    required TimedAccessController controller,
    required Color textColor,
    required Color secondaryColor,
    required Color bgColor,
  }) {
    return Obx(() {
      final isSelected = !controller.isCustom.value &&
          controller.selectedDurationMinutes.value == minutes;

      return GestureDetector(
        onTap: () {
          setState(() {
            _showCustomInput = false;
          });
          _customFocusNode.unfocus();
          controller.selectPresetDuration(minutes);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? textColor
                : secondaryColor.withValues(alpha: 0.1),
            borderRadius: AppRadius.borderMd,
          ),
          child: Center(
            child: MinimalText(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? bgColor : textColor,
              ),
            ),
          ),
        ),
      );
    });
  }
}
