import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/permission_service.dart';
import '../../onboarding/services/onboarding_service.dart';
import '../controllers/settings_controller.dart';
import '../services/daily_wallpaper_service.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    final controller = Get.find<SettingsController>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: MinimalText(
                  '← Back',
                  style: TextStyle(fontSize: 15, color: secondaryColor),
                ),
              ),

              const SizedBox(height: 28),

              MinimalText(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 32),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // ── Appearance ───────────────────────────
                    _SectionLabel('APPEARANCE & TYPOGRAPHY', secondaryColor),
                    const SizedBox(height: 12),

                    Obx(() => _ToggleRow(
                          label: 'Show status bar',
                          value: controller.showStatusBar.value,
                          textColor: textColor,
                          onTap: controller.toggleStatusBar,
                        )),
                    Obx(() => _ToggleRow(
                          label: 'Bold font',
                          value: controller.boldFont.value,
                          textColor: textColor,
                          onTap: controller.toggleBoldFont,
                        )),
                    Obx(() => _ToggleRow(
                          label: 'Show clock',
                          value: controller.showClock.value,
                          textColor: textColor,
                          onTap: controller.toggleClock,
                        )),
                    Obx(() => _ToggleRow(
                          label: 'Show date',
                          value: controller.showDate.value,
                          textColor: textColor,
                          onTap: controller.toggleDate,
                        )),

                    const SizedBox(height: 12),
                    MinimalText(
                      'Date & time visibility',
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final v = controller.dateTimeVisibility.value;
                      return Column(
                        children: [
                          _SelectRow(
                            label: 'Clock & Date',
                            selected: v == 'on',
                            textColor: textColor,
                            onTap: () => controller.setDateTimeVisibility('on'),
                          ),
                          _SelectRow(
                            label: 'Date only',
                            selected: v == 'date_only',
                            textColor: textColor,
                            onTap: () =>
                                controller.setDateTimeVisibility('date_only'),
                          ),
                          _SelectRow(
                            label: 'Hidden',
                            selected: v == 'off',
                            textColor: textColor,
                            onTap: () =>
                                controller.setDateTimeVisibility('off'),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 12),
                    MinimalText(
                      'Theme',
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final mode = controller.themeMode.value;
                      return Column(
                        children: [
                          _SelectRow(
                            label: 'System',
                            selected: mode == 'system',
                            textColor: textColor,
                            onTap: () => controller.setThemeMode('system'),
                          ),
                          _SelectRow(
                            label: 'Light',
                            selected: mode == 'light',
                            textColor: textColor,
                            onTap: () => controller.setThemeMode('light'),
                          ),
                          _SelectRow(
                            label: 'Dark',
                            selected: mode == 'dark',
                            textColor: textColor,
                            onTap: () => controller.setThemeMode('dark'),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 12),
                    MinimalText(
                      'E-Ink display mode',
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final eInk = controller.eInkMode.value;
                      final isHw = controller.isHardwareEink.value;
                      return Column(
                        children: [
                          _SelectRow(
                            label: isHw ? 'Auto (E-Ink detected)' : 'Auto',
                            selected: eInk == 'auto',
                            textColor: textColor,
                            onTap: () => controller.setEInkMode('auto'),
                          ),
                          _SelectRow(
                            label: 'Always on (monochrome, zero animations)',
                            selected: eInk == 'on',
                            textColor: textColor,
                            onTap: () => controller.setEInkMode('on'),
                          ),
                          _SelectRow(
                            label: 'Off',
                            selected: eInk == 'off',
                            textColor: textColor,
                            onTap: () => controller.setEInkMode('off'),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 12),
                    MinimalText(
                      'Text size',
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final scale = controller.textScale.value;
                      return Column(
                        children: [
                          _SelectRow(
                            label: 'Small',
                            selected: scale < 0.95,
                            textColor: textColor,
                            onTap: () => controller.setTextScale(0.9),
                          ),
                          _SelectRow(
                            label: 'Normal',
                            selected: scale >= 0.95 && scale <= 1.05,
                            textColor: textColor,
                            onTap: () => controller.setTextScale(1.0),
                          ),
                          _SelectRow(
                            label: 'Large',
                            selected: scale > 1.05,
                            textColor: textColor,
                            onTap: () => controller.setTextScale(1.15),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 28),
                    Container(
                      height: 1,
                      color: secondaryColor.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 28),

                    // ── Home Customization ───────────────────
                    _SectionLabel('HOME SCREEN', secondaryColor),
                    const SizedBox(height: 12),

                    MinimalText(
                      'Alignment',
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final align = controller.homeAlignment.value;
                      return Column(
                        children: [
                          _SelectRow(
                            label: 'Left',
                            selected: align == 'left',
                            textColor: textColor,
                            onTap: () => controller.setHomeAlignment('left'),
                          ),
                          _SelectRow(
                            label: 'Center',
                            selected: align == 'center',
                            textColor: textColor,
                            onTap: () => controller.setHomeAlignment('center'),
                          ),
                          _SelectRow(
                            label: 'Right',
                            selected: align == 'right',
                            textColor: textColor,
                            onTap: () => controller.setHomeAlignment('right'),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 8),
                    Obx(() => _ToggleRow(
                          label: 'Bottom alignment',
                          value: controller.homeBottomAlignment.value,
                          textColor: textColor,
                          onTap: controller.toggleHomeBottomAlignment,
                        )),

                    const SizedBox(height: 12),
                    Obx(() {
                      final count = controller.homeAppsCount.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MinimalText(
                            'Home apps count: $count',
                            style: TextStyle(fontSize: 16, color: textColor),
                          ),
                          Slider(
                            value: count.toDouble(),
                            min: 0,
                            max: 8,
                            divisions: 8,
                            activeColor: textColor,
                            inactiveColor:
                                secondaryColor.withValues(alpha: 0.2),
                            onChanged: (val) =>
                                controller.setHomeAppsCount(val.toInt()),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 8),
                    Obx(() => _ToggleRow(
                          label: 'Show screen time on home',
                          value: controller.showScreenTime.value,
                          textColor: textColor,
                          onTap: controller.toggleShowScreenTime,
                        )),
                    const SizedBox(height: 8),
                    Obx(() {
                      final enabled = controller.dailyWallpaperEnabled.value;
                      return Column(
                        children: [
                          _ToggleRow(
                            label: 'Daily curated wallpaper',
                            value: enabled,
                            textColor: textColor,
                            onTap: () async {
                              await controller.toggleDailyWallpaper();
                              if (controller.dailyWallpaperEnabled.value &&
                                  Get.isRegistered<DailyWallpaperService>()) {
                                Get.find<DailyWallpaperService>()
                                    .updateDailyWallpaper(isDark: isDark);
                              }
                            },
                          ),
                          if (enabled)
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 16, top: 4, bottom: 8),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (Get.isRegistered<
                                          DailyWallpaperService>()) {
                                        Get.find<DailyWallpaperService>()
                                            .updateDailyWallpaper(
                                          isDark: isDark,
                                          force: true,
                                        );
                                      }
                                    },
                                    child: MinimalText(
                                      'Refresh wallpaper',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: secondaryColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: () {
                                      if (Get.isRegistered<
                                          DailyWallpaperService>()) {
                                        Get.find<DailyWallpaperService>()
                                            .resetWallpaper();
                                      }
                                    },
                                    child: MinimalText(
                                      'Reset to black',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: secondaryColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    }),

                    const SizedBox(height: 28),
                    Container(
                      height: 1,
                      color: secondaryColor.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 28),

                    // ── Gestures ─────────────────────────────
                    _SectionLabel('GESTURES', secondaryColor),
                    const SizedBox(height: 12),

                    MinimalText(
                      'Swipe down action',
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final action = controller.swipeDownAction.value;
                      return Column(
                        children: [
                          _SelectRow(
                            label: 'Notifications',
                            selected: action == 'notifications',
                            textColor: textColor,
                            onTap: () =>
                                controller.setSwipeDownAction('notifications'),
                          ),
                          _SelectRow(
                            label: 'Search',
                            selected: action == 'search',
                            textColor: textColor,
                            onTap: () => controller.setSwipeDownAction('search'),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 8),
                    Obx(() => _ToggleRow(
                          label: 'Double tap to lock screen',
                          value: controller.doubleTapToLock.value,
                          textColor: textColor,
                          onTap: controller.toggleDoubleTapToLock,
                        )),

                    _InfoRow('Swipe left', 'Camera (or configured)', textColor,
                        secondaryColor),
                    _InfoRow('Swipe right', 'Phone (or configured)', textColor,
                        secondaryColor),

                    const SizedBox(height: 28),
                    Container(
                      height: 1,
                      color: secondaryColor.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 28),

                    // ── Search & Drawer ──────────────────────
                    _SectionLabel('SEARCH & APP DRAWER', secondaryColor),
                    const SizedBox(height: 12),

                    Obx(() => _ToggleRow(
                          label: 'Auto-show keyboard',
                          value: controller.autoShowKeyboard.value,
                          textColor: textColor,
                          onTap: controller.toggleAutoShowKeyboard,
                        )),
                    Obx(() => _ToggleRow(
                          label: 'Auto-launch single match',
                          value: controller.autoLaunchSingleMatch.value,
                          textColor: textColor,
                          onTap: controller.toggleAutoLaunchSingleMatch,
                        )),
                    _InfoRow('!query', 'DuckDuckGo Bang search', textColor,
                        secondaryColor),
                    _InfoRow(
                        '0 matches', 'Web search fallback', textColor, secondaryColor),
                    _InfoRow(' ✦ badge', 'Newly installed (< 24h)', textColor,
                        secondaryColor),

                    const SizedBox(height: 28),
                    Container(
                      height: 1,
                      color: secondaryColor.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 28),

                    // ── Productivity ─────────────────────────
                    _SectionLabel('PRODUCTIVITY', secondaryColor),
                    const SizedBox(height: 12),

                    _LinkRow(
                      label: 'Screen Time',
                      textColor: textColor,
                      onTap: () => context.push(AppRoutes.screenTime),
                    ),
                    _LinkRow(
                      label: 'Focus Mode',
                      textColor: textColor,
                      subtitle: 'Long-press clock to start/stop',
                      secondaryColor: secondaryColor,
                    ),
                    _LinkRow(
                      label: 'Mindful Delay',
                      textColor: textColor,
                      subtitle: 'Long-press app → Mindful Delay',
                      secondaryColor: secondaryColor,
                    ),
                    _LinkRow(
                      label: 'Daily Limits',
                      textColor: textColor,
                      subtitle: 'Long-press app → Daily Limit',
                      secondaryColor: secondaryColor,
                    ),
                    _LinkRow(
                      label: 'Scheduled Blocking',
                      textColor: textColor,
                      subtitle: 'Long-press app → Schedule Block',
                      secondaryColor: secondaryColor,
                    ),
                    _LinkRow(
                      label: 'Timed Distraction Access',
                      textColor: textColor,
                      subtitle: 'Long-press app → Mark as Distraction App',
                      secondaryColor: secondaryColor,
                    ),

                    const SizedBox(height: 28),
                    Container(
                      height: 1,
                      color: secondaryColor.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 28),

                    // ── System & Protection ──────────────────
                    _SectionLabel('SYSTEM & PROTECTION', secondaryColor),
                    const SizedBox(height: 12),
                    _LinkRow(
                      label: 'Default Launcher',
                      textColor: textColor,
                      subtitle: 'Set Minimalist as home screen',
                      secondaryColor: secondaryColor,
                      onTap: () {
                        if (Get.isRegistered<PermissionService>()) {
                          Get.find<PermissionService>()
                              .openDefaultLauncherSettings();
                        }
                      },
                    ),
                    _LinkRow(
                      label: 'Digital Detox Onboarding',
                      textColor: textColor,
                      subtitle: 'Review setup and permissions',
                      secondaryColor: secondaryColor,
                      onTap: () async {
                        if (Get.isRegistered<OnboardingService>()) {
                          await Get.find<OnboardingService>().resetOnboarding();
                        }
                        if (context.mounted) {
                          context.push(AppRoutes.onboarding);
                        }
                      },
                    ),
                    _LinkRow(
                      label: 'Protected Mode',
                      textColor: textColor,
                      subtitle: 'Device Owner uninstall protection',
                      secondaryColor: secondaryColor,
                      onTap: () => context.push(AppRoutes.protectedMode),
                    ),

                    const SizedBox(height: 28),
                    Container(
                      height: 1,
                      color: secondaryColor.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 28),

                    // ── About ────────────────────────────────
                    _SectionLabel('ABOUT', secondaryColor),
                    const SizedBox(height: 12),
                    MinimalText(
                      'Minimal Launcher',
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    MinimalText(
                      'Text-first. Distraction-free.\nBuilt for intentional phone use.',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionLabel(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return MinimalText(
      label,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
        color: color.withValues(alpha: 0.5),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final Color textColor;
  final VoidCallback onTap;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MinimalText(
              label,
              style: TextStyle(fontSize: 16, color: textColor),
            ),
            MinimalText(
              value ? 'On' : 'Off',
              style: TextStyle(
                fontSize: 14,
                color: value ? AppColors.accent : textColor.withValues(alpha: 0.4),
                fontWeight: value ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  final String label;
  final bool selected;
  final Color textColor;
  final VoidCallback onTap;

  const _SelectRow({
    required this.label,
    required this.selected,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MinimalText(
              label,
              style: TextStyle(
                fontSize: 15,
                color: selected ? textColor : textColor.withValues(alpha: 0.4),
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
            if (selected)
              const MinimalText(
                '✓',
                style: TextStyle(fontSize: 14, color: AppColors.accent),
              ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final Color textColor;
  final String? subtitle;
  final Color? secondaryColor;
  final VoidCallback? onTap;

  const _LinkRow({
    required this.label,
    required this.textColor,
    this.subtitle,
    this.secondaryColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MinimalText(
                  label,
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  MinimalText(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryColor?.withValues(alpha: 0.5) ??
                          textColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
            if (onTap != null)
              MinimalText(
                '→',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withValues(alpha: 0.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color secondaryColor;

  const _InfoRow(this.label, this.value, this.textColor, this.secondaryColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MinimalText(
            label,
            style: TextStyle(fontSize: 15, color: textColor),
          ),
          MinimalText(
            value,
            style: TextStyle(fontSize: 14, color: secondaryColor),
          ),
        ],
      ),
    );
  }
}
