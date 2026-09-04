import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/native_bridge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';
import '../../apps/controllers/apps_controller.dart';
import '../../apps/models/app_info.dart';
import '../../apps/services/app_config_service.dart';
import '../../daily_limits/controllers/daily_limit_controller.dart';
import '../../daily_limits/models/daily_limit_config.dart';
import '../../favorites/controllers/favorites_controller.dart';
import '../../focus_mode/controllers/focus_mode_controller.dart';
import '../../mindful_delay/controllers/mindful_delay_controller.dart';
import '../../mindful_delay/models/mindful_delay_config.dart';
import '../../productivity/controllers/productivity_controller.dart';
import '../../scheduled_block/controllers/schedule_controller.dart';
import '../../scheduled_block/models/schedule_config.dart';
import 'app_rename_dialog.dart';

class OptionTile extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const OptionTile({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: MinimalText(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Opens the app context options bottom sheet.
void showAppOptionsBottomSheet({
  required BuildContext context,
  required AppInfo app,
  required String displayName,
  required FavoritesController favoritesController,
  required ProductivityController productivity,
  required bool isFavorite,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  final configService = Get.find<AppConfigService>();
  final appsController = Get.find<AppsController>();
  final delayController = Get.find<MindfulDelayController>();
  final hasDelay = delayController.isEnabledFor(app.packageName);

  showModalBottomSheet(
    context: context,
    backgroundColor:
        isDark ? AppColors.darkBackground : const Color(0xFFF5F5F5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MinimalText(
                displayName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              MinimalText(
                app.packageName,
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryColor.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 1,
                color: secondaryColor.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 6),
              OptionTile(
                label: 'Open',
                color: textColor,
                onTap: () {
                  Navigator.pop(ctx);
                  productivity.handleAppLaunch(
                    app.packageName,
                    userSerial: app.userSerial,
                    activityName: app.activityName,
                    context: context,
                  );
                },
              ),
              OptionTile(
                label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                color: textColor,
                onTap: () {
                  favoritesController.toggleFavorite(app.packageName);
                  Navigator.pop(ctx);
                },
              ),
              if (isFavorite) ...[
                OptionTile(
                  label: 'Move up',
                  color: textColor,
                  onTap: () {
                    favoritesController.moveUp(app.packageName);
                    Navigator.pop(ctx);
                  },
                ),
                OptionTile(
                  label: 'Move down',
                  color: textColor,
                  onTap: () {
                    favoritesController.moveDown(app.packageName);
                    Navigator.pop(ctx);
                  },
                ),
              ],
              if (app.packageName != 'com.minimal.launcher.settings') ...[
                OptionTile(
                  label: 'Rename',
                  color: textColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    showAppRenameDialog(
                      context: context,
                      app: app,
                      currentDisplayName: displayName,
                      configService: configService,
                      appsController: appsController,
                    );
                  },
                ),
                OptionTile(
                  label: hasDelay ? 'Mindful Delay (on)' : 'Mindful Delay',
                  color: textColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showMindfulDelayOptions(
                        context, app, displayName, delayController);
                  },
                ),
                OptionTile(
                  label: Get.find<DailyLimitController>()
                          .isEnabledFor(app.packageName)
                      ? 'Daily Limit (on)'
                      : 'Daily Limit',
                  color: textColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDailyLimitOptions(context, app, displayName);
                  },
                ),
                OptionTile(
                  label: Get.find<ScheduleController>()
                          .isEnabledFor(app.packageName)
                      ? 'Schedule Block (on)'
                      : 'Schedule Block',
                  color: textColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showScheduleOptions(context, app, displayName);
                  },
                ),
                OptionTile(
                  label: Get.find<FocusModeController>()
                          .isAppInBlockList(app.packageName)
                      ? 'Remove from Focus block list'
                      : 'Add to Focus block list',
                  color: textColor,
                  onTap: () async {
                    await Get.find<FocusModeController>()
                        .toggleBlockedApp(app.packageName);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                OptionTile(
                  label: configService.isDistraction(app.packageName)
                      ? 'Distraction App (on)'
                      : 'Mark as Distraction App',
                  color: textColor,
                  onTap: () async {
                    await configService.toggleDistraction(app.packageName);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                OptionTile(
                  label: 'App Info',
                  color: textColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (Get.isRegistered<NativeBridge>()) {
                      Get.find<NativeBridge>().openAppDetails(app.packageName);
                    }
                  },
                ),
                if (!app.isSystemApp)
                  OptionTile(
                    label: 'Uninstall',
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(ctx);
                      if (Get.isRegistered<NativeBridge>()) {
                        Get.find<NativeBridge>().uninstallApp(app.packageName);
                      }
                    },
                  ),
                OptionTile(
                  label: 'Hide',
                  color: textColor,
                  onTap: () async {
                    await configService.setHidden(app.packageName, true);
                    if (isFavorite) {
                      await favoritesController.removeFavorite(app.packageName);
                    }
                    appsController.refreshVisibility();
                    favoritesController.rebuildFavorites();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

void _showMindfulDelayOptions(
  BuildContext context,
  AppInfo app,
  String displayName,
  MindfulDelayController delayController,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  final currentDuration = delayController.durationFor(app.packageName);
  final isEnabled = delayController.isEnabledFor(app.packageName);

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
                'Mindful Delay — $displayName',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              MinimalText(
                'Requires waiting before the app opens.',
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 1,
                color: secondaryColor.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 8),
              if (isEnabled)
                OptionTile(
                  label: 'Turn off',
                  color: textColor,
                  onTap: () async {
                    await delayController.disable(app.packageName);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ...MindfulDelayConfig.availableDurations.map((seconds) {
                final label = MindfulDelayConfig.formatDuration(seconds);
                final selected = isEnabled && currentDuration == seconds;
                return OptionTile(
                  label: selected ? '✓  $label' : label,
                  color: textColor,
                  onTap: () async {
                    await delayController.setDuration(app.packageName, seconds);
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

void _showDailyLimitOptions(
  BuildContext context,
  AppInfo app,
  String displayName,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  final limitController = Get.find<DailyLimitController>();
  final isEnabled = limitController.isEnabledFor(app.packageName);
  final currentLimit = limitController.limitMinutesFor(app.packageName);

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
                'Daily Limit — $displayName',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              MinimalText(
                'Caps total screen time per day for this app.',
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 1,
                color: secondaryColor.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 8),
              if (isEnabled)
                OptionTile(
                  label: 'Turn off',
                  color: textColor,
                  onTap: () async {
                    await limitController.disable(app.packageName);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ...DailyLimitConfig.availableLimits.map((minutes) {
                final label = DailyLimitConfig.formatMinutes(minutes);
                final selected = isEnabled && currentLimit == minutes;
                return OptionTile(
                  label: selected ? '✓  $label' : label,
                  color: textColor,
                  onTap: () async {
                    await limitController.setLimit(app.packageName, minutes);
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

void _showScheduleOptions(
  BuildContext context,
  AppInfo app,
  String displayName,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  final scheduleController = Get.find<ScheduleController>();
  final isEnabled = scheduleController.isEnabledFor(app.packageName);
  final config = scheduleController.configFor(app.packageName);

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
                'Schedule Block — $displayName',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              MinimalText(
                'Block app during specific recurring hours.',
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 1,
                color: secondaryColor.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 8),
              if (isEnabled)
                OptionTile(
                  label: 'Turn off',
                  color: textColor,
                  onTap: () async {
                    await scheduleController.disable(app.packageName);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ...ScheduleConfig.presets.map((preset) {
                final start = preset['start']!;
                final end = preset['end']!;
                final label = ScheduleConfig.presetLabel(start, end);
                final selected = isEnabled &&
                    config.startMinutes == start &&
                    config.endMinutes == end;
                return OptionTile(
                  label: selected ? '✓  $label' : label,
                  color: textColor,
                  onTap: () async {
                    await scheduleController.setSchedule(
                      app.packageName,
                      startMinutes: start,
                      endMinutes: end,
                    );
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
