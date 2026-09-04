import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/native_bridge.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';
import '../../apps/controllers/apps_controller.dart';
import '../../apps/services/app_config_service.dart';
import '../../onboarding/services/onboarding_service.dart';
import '../controllers/settings_controller.dart';
import '../widgets/gesture_app_picker_sheet.dart';
import '../widgets/unclutter_feature_sheets.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final RxBool isDefaultLauncher = false.obs;

  @override
  void initState() {
    super.initState();
    _checkDefaultLauncher();
  }

  Future<void> _checkDefaultLauncher() async {
    if (Get.isRegistered<PermissionService>()) {
      final isDef = await Get.find<PermissionService>().isDefaultLauncher();
      isDefaultLauncher.value = isDef;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    final controller = Get.find<SettingsController>();
    final appsController =
        Get.isRegistered<AppsController>() ? Get.find<AppsController>() : null;
    final configService = Get.isRegistered<AppConfigService>()
        ? Get.find<AppConfigService>()
        : null;

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
              const SizedBox(height: 24),
              MinimalText(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // ── Default Launcher ─────────────────────
                    _SectionLabel('DEFAULT LAUNCHER', secondaryColor),
                    const SizedBox(height: 6),
                    Obx(() {
                      final isDefault = isDefaultLauncher.value;
                      return _OlauncherSettingTile(
                        title: 'Default launcher',
                        subtitle: isDefault
                            ? 'Unclutter is your default home'
                            : 'Tap to make Unclutter your default home',
                        value: isDefault ? 'Active ✓' : 'Set default →',
                        textColor: textColor,
                        secondaryColor: secondaryColor,
                        onTap: () async {
                          if (Get.isRegistered<PermissionService>()) {
                            await Get.find<PermissionService>()
                                .openDefaultLauncherSettings();
                            await Future.delayed(
                                const Duration(milliseconds: 600));
                            await _checkDefaultLauncher();
                          }
                        },
                      );
                    }),

                    const SizedBox(height: 20),
                    _Divider(secondaryColor),
                    const SizedBox(height: 20),

                    // ── Home Screen ──────────────────────────
                    _SectionLabel('HOME SCREEN', secondaryColor),
                    const SizedBox(height: 6),
                    Obx(() => _OlauncherSettingTile(
                          title: 'Home screen apps',
                          subtitle: controller.homeAppsCount.value == 0
                              ? 'Hidden from home'
                              : '${controller.homeAppsCount.value} apps on home',
                          value: '${controller.homeAppsCount.value}',
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          onTap: controller.cycleHomeAppsCount,
                        )),
                    Obx(() => _OlauncherSettingTile(
                          title: 'Home alignment',
                          value: controller.homeAlignmentLabel,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          onTap: controller.cycleHomeAlignment,
                        )),
                    Obx(() => _OlauncherSettingTile(
                          title: 'Bottom alignment',
                          subtitle: 'Align home apps at the bottom',
                          isToggle: true,
                          toggleValue: controller.homeBottomAlignment.value,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          onTap: controller.toggleHomeBottomAlignment,
                        )),
                    Obx(() => _OlauncherSettingTile(
                          title: 'Date & time',
                          value: controller.dateTimeVisibilityLabel,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          onTap: controller.cycleDateTimeVisibility,
                        )),
                    Obx(() => _OlauncherSettingTile(
                          title: 'Show screen time on home',
                          isToggle: true,
                          toggleValue: controller.showScreenTime.value,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          onTap: controller.toggleShowScreenTime,
                        )),
                    _OlauncherSettingTile(
                      title: 'Favorite apps',
                      subtitle: 'Choose & reorder apps on home screen',
                      value: 'Manage →',
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () => showFavoritesManagerSheet(context),
                    ),

                    const SizedBox(height: 20),
                    _Divider(secondaryColor),
                    const SizedBox(height: 20),

                    // ── Appearance & Typography ───────────────
                    _SectionLabel('APPEARANCE & TYPOGRAPHY', secondaryColor),
                    const SizedBox(height: 6),
                    Obx(() => _OlauncherSettingTile(
                          title: 'Theme',
                          value: controller.themeModeLabel,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          onTap: controller.cycleThemeMode,
                        )),
                    Obx(() => _OlauncherSettingTile(
                          title: 'Text size',
                          value: controller.textScaleLabel,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          onTap: controller.cycleTextScale,
                        )),
                    Obx(() => _OlauncherSettingTile(
                          title: 'Bold font',
                          isToggle: true,
                          toggleValue: controller.boldFont.value,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          onTap: controller.toggleBoldFont,
                        )),
                    Obx(() => _OlauncherSettingTile(
                          title: 'Show status bar',
                          isToggle: true,
                          toggleValue: controller.showStatusBar.value,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          onTap: controller.toggleStatusBar,
                        )),
                    Obx(() => _OlauncherSettingTile(
                          title: 'E-Ink display mode',
                          subtitle: 'High contrast monochrome with no animations',
                          value: controller.eInkModeLabel,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          onTap: controller.cycleEInkMode,
                        )),

                    const SizedBox(height: 20),
                    _Divider(secondaryColor),
                    const SizedBox(height: 20),

                    // ── Gestures ─────────────────────────────
                    _SectionLabel('GESTURES', secondaryColor),
                    const SizedBox(height: 6),
                    Obx(() => _OlauncherSettingTile(
                          title: 'Swipe down',
                          subtitle: 'Swipe down on home screen',
                          value: controller.swipeDownActionLabel,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          onTap: controller.cycleSwipeDownAction,
                        )),
                    Obx(() {
                      final pkg = controller.swipeLeftPackage.value;
                      String appName = 'Camera';
                      if (pkg != null &&
                          pkg.isNotEmpty &&
                          appsController != null) {
                        final found = appsController.apps
                            .firstWhereOrNull((a) => a.packageName == pkg);
                        if (found != null) {
                          appName = appsController.displayName(found);
                        }
                      }
                      return _OlauncherSettingTile(
                        title: 'Swipe left',
                        subtitle: 'Quick swipe left on home screen',
                        value: '$appName →',
                        textColor: textColor,
                        secondaryColor: secondaryColor,
                        onTap: () => showGestureAppPickerSheet(
                          context,
                          isLeft: true,
                        ),
                      );
                    }),
                    Obx(() {
                      final pkg = controller.swipeRightPackage.value;
                      String appName = 'Phone';
                      if (pkg != null &&
                          pkg.isNotEmpty &&
                          appsController != null) {
                        final found = appsController.apps
                            .firstWhereOrNull((a) => a.packageName == pkg);
                        if (found != null) {
                          appName = appsController.displayName(found);
                        }
                      }
                      return _OlauncherSettingTile(
                        title: 'Swipe right',
                        subtitle: 'Quick swipe right on home screen',
                        value: '$appName →',
                        textColor: textColor,
                        secondaryColor: secondaryColor,
                        onTap: () => showGestureAppPickerSheet(
                          context,
                          isLeft: false,
                        ),
                      );
                    }),
                    Obx(() => _OlauncherSettingTile(
                          title: 'Double tap to lock screen',
                          subtitle: 'Locks screen instantly on home double tap',
                          isToggle: true,
                          toggleValue: controller.doubleTapToLock.value,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          onTap: controller.toggleDoubleTapToLock,
                        )),

                    const SizedBox(height: 20),
                    _Divider(secondaryColor),
                    const SizedBox(height: 20),

                    // ── App Drawer & Search ──────────────────
                    _SectionLabel('SEARCH & APP DRAWER', secondaryColor),
                    const SizedBox(height: 6),
                    Obx(() => _OlauncherSettingTile(
                          title: 'Auto-show keyboard',
                          subtitle: 'Open keyboard when entering app drawer',
                          isToggle: true,
                          toggleValue: controller.autoShowKeyboard.value,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          onTap: controller.toggleAutoShowKeyboard,
                        )),
                    Obx(() => _OlauncherSettingTile(
                          title: 'Auto-launch single match',
                          subtitle: 'Instantly opens when only 1 app matches search',
                          isToggle: true,
                          toggleValue: controller.autoLaunchSingleMatch.value,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          onTap: controller.toggleAutoLaunchSingleMatch,
                        )),
                    _OlauncherSettingTile(
                      title: 'Hidden apps',
                      subtitle: configService != null
                          ? '${configService.hiddenPackageNames.length} apps hidden'
                          : 'View and unhide hidden applications',
                      value: 'Manage →',
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () => showHiddenAppsManagerSheet(context),
                    ),
                    _OlauncherSettingTile(
                      title: 'Renamed apps',
                      subtitle: configService != null
                          ? '${configService.renamedPackageNames.length} apps custom labeled'
                          : 'Manage custom labels and aliases',
                      value: 'Manage →',
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () => showRenamedAppsManagerSheet(context),
                    ),

                    const SizedBox(height: 20),
                    _Divider(secondaryColor),
                    const SizedBox(height: 20),

                    // ── Productivity & Digital Wellbeing ─────
                    _SectionLabel('DIGITAL WELLBEING', secondaryColor),
                    const SizedBox(height: 6),
                    _OlauncherSettingTile(
                      title: 'Screen time stats',
                      subtitle: 'Daily usage stats & app breakdown',
                      value: 'View stats →',
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () => context.push(AppRoutes.screenTime),
                    ),
                    _OlauncherSettingTile(
                      title: 'Mindful delay',
                      subtitle: 'Configure breathing pauses before opening apps',
                      value: 'Configure →',
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () => showMindfulDelaySettingsSheet(context),
                    ),
                    _OlauncherSettingTile(
                      title: 'Daily limits',
                      subtitle: 'Configure daily usage limits per app',
                      value: 'Configure →',
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () => showDailyLimitsSettingsSheet(context),
                    ),
                    _OlauncherSettingTile(
                      title: 'Scheduled blocking',
                      subtitle: 'Configure quiet hour block rules per app',
                      value: 'Configure →',
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () => showScheduleBlockSettingsSheet(context),
                    ),
                    _OlauncherSettingTile(
                      title: 'Focus mode',
                      subtitle: 'Long-press clock on home screen to activate',
                      value: 'Info',
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const MinimalText(
                              'Tip: Long-press the clock on home screen to toggle Focus Mode.',
                            ),
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: isDark
                                ? const Color(0xFF222222)
                                : const Color(0xFFEEEEEE),
                          ),
                        );
                      },
                    ),
                    _OlauncherSettingTile(
                      title: 'Protected mode',
                      subtitle: 'Device Owner uninstall & bypass protection',
                      value: 'Configure →',
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () => context.push(AppRoutes.protectedMode),
                    ),

                    const SizedBox(height: 20),
                    _Divider(secondaryColor),
                    const SizedBox(height: 20),

                    // ── System & Onboarding ──────────────────
                    _SectionLabel('SYSTEM', secondaryColor),
                    const SizedBox(height: 6),
                    _OlauncherSettingTile(
                      title: 'Device settings',
                      subtitle: 'Open Android system settings',
                      value: 'Open →',
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () {
                        if (Get.isRegistered<NativeBridge>()) {
                          Get.find<NativeBridge>().openDeviceSettings();
                        }
                      },
                    ),
                    _OlauncherSettingTile(
                      title: 'Digital detox onboarding',
                      subtitle: 'Review initial setup and permissions',
                      value: 'Reset & view →',
                      textColor: textColor,
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

                    const SizedBox(height: 20),
                    _Divider(secondaryColor),
                    const SizedBox(height: 20),

                    // ── About ────────────────────────────────
                    _SectionLabel('ABOUT', secondaryColor),
                    const SizedBox(height: 8),
                    _OlauncherSettingTile(
                      title: 'Unclutter Launcher',
                      subtitle: 'Minimalist. Distraction-free. Open Source.\nBuilt for intentional phone use.',
                      value: 'v1.0.0',
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                      onTap: () {},
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

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: color.withValues(alpha: 0.1),
    );
  }
}

class _OlauncherSettingTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback onTap;
  final Color textColor;
  final Color secondaryColor;
  final bool isToggle;
  final bool? toggleValue;

  const _OlauncherSettingTile({
    required this.title,
    this.subtitle,
    this.value,
    required this.onTap,
    required this.textColor,
    required this.secondaryColor,
    this.isToggle = false,
    this.toggleValue,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MinimalText(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    MinimalText(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (isToggle && toggleValue != null)
              MinimalText(
                toggleValue! ? 'On' : 'Off',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: toggleValue!
                      ? AppColors.accent
                      : secondaryColor.withValues(alpha: 0.45),
                ),
              )
            else if (value != null)
              MinimalText(
                value!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: secondaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
