import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/native_bridge.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/minimal_text.dart';
import '../../apps/controllers/apps_controller.dart';
import '../../focus_mode/controllers/focus_mode_controller.dart';
import '../../launcher/widgets/home_clock_menu.dart';
import '../../onboarding/services/onboarding_service.dart';
import '../controllers/settings_controller.dart';
import '../widgets/gesture_app_picker_sheet.dart';
import '../widgets/unclutter_feature_sheets.dart';
import '../../distraction_apps/views/distraction_apps_sheet.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with WidgetsBindingObserver {
  final RxBool isDefaultLauncher = false.obs;
  final RxBool hasUsageAccess = false.obs;
  final RxBool hasNotificationAccess = false.obs;
  final RxBool hasAccessibility = false.obs;
  final RxBool hasEnforcement = false.obs;
  final RxBool isEnforcementRequired = false.obs;
  final RxBool isOwner = false.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    if (Get.isRegistered<PermissionService>()) {
      final perm = Get.find<PermissionService>();
      isDefaultLauncher.value = await perm.isDefaultLauncher();
      hasUsageAccess.value = await perm.checkUsageAccess();
      hasNotificationAccess.value = await perm.checkNotificationPermission();
      hasAccessibility.value = await perm.checkAccessibilityPermission();
      hasEnforcement.value = await perm.checkEnforcementPermission();
      isEnforcementRequired.value = await perm.isEnforcementPermissionRequired();
      isOwner.value = await perm.isDeviceOwner();
    }
  }

  void _handleFocusMode(BuildContext context) {
    final focusController = Get.isRegistered<FocusModeController>()
        ? Get.find<FocusModeController>()
        : null;

    if (focusController == null) {
      showStartFocusModeBottomSheet(context);
      return;
    }

    if (focusController.isActive.value) {
      final textColor = AppColors.darkText;
      final secondaryColor = AppColors.darkSecondary;

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.darkBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.horizontalPadding(context),
              vertical: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MinimalText(
                  'Focus Mode is Active',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => MinimalText(
                      'Time remaining: ${focusController.remainingText.value}',
                      style: TextStyle(fontSize: 14, color: secondaryColor),
                    )),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    focusController.stop();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: MinimalText(
                      'Stop Focus Mode',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      showStartFocusModeBottomSheet(context);
    }
  }

  void _showAppearanceSheet(BuildContext context) {
    final textColor = AppColors.darkText;
    final secondaryColor = AppColors.darkSecondary;
    final controller = Get.find<SettingsController>();
    final appsController =
        Get.isRegistered<AppsController>() ? Get.find<AppsController>() : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.horizontalPadding(context),
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 16),
                  MinimalText(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  MinimalText(
                    'Typography, layout & gestures',
                    style: TextStyle(fontSize: 13, color: secondaryColor),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _SubSectionHeader('TYPOGRAPHY', secondaryColor),
                        Obx(() => _SettingRow(
                              title: 'Text size',
                              value: controller.textScaleLabel,
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              onTap: controller.cycleTextScale,
                            )),
                        Obx(() => _SettingRow(
                              title: 'Bold font',
                              isToggle: true,
                              toggleValue: controller.boldFont.value,
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              onTap: controller.toggleBoldFont,
                            )),
                        Obx(() => _SettingRow(
                              title: 'E-Ink display mode',
                              subtitle:
                                  'High contrast monochrome with no animations',
                              value: controller.eInkModeLabel,
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              onTap: controller.cycleEInkMode,
                            )),
                        _SubDivider(secondaryColor),
                        _SubSectionHeader('HOME SCREEN', secondaryColor),
                        Obx(() => _SettingRow(
                              title: 'Home screen apps',
                              subtitle: controller.homeAppsCount.value == 0
                                  ? 'Hidden from home'
                                  : '${controller.homeAppsCount.value} apps on home',
                              value: '${controller.homeAppsCount.value}',
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              onTap: controller.cycleHomeAppsCount,
                            )),
                        Obx(() => _SettingRow(
                              title: 'Home alignment',
                              value: controller.homeAlignmentLabel,
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              onTap: controller.cycleHomeAlignment,
                            )),
                        Obx(() => _SettingRow(
                              title: 'Bottom alignment',
                              subtitle: 'Align home apps at the bottom',
                              isToggle: true,
                              toggleValue:
                                  controller.homeBottomAlignment.value,
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              onTap: controller.toggleHomeBottomAlignment,
                            )),
                        Obx(() => _SettingRow(
                              title: 'Date & time display',
                              value: controller.dateTimeVisibilityLabel,
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              onTap: controller.cycleDateTimeVisibility,
                            )),
                        Obx(() => _SettingRow(
                              title: 'Show status bar',
                              isToggle: true,
                              toggleValue: controller.showStatusBar.value,
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              onTap: controller.toggleStatusBar,
                            )),
                        Obx(() => _SettingRow(
                              title: 'Show screen time on home',
                              isToggle: true,
                              toggleValue: controller.showScreenTime.value,
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              onTap: controller.toggleShowScreenTime,
                            )),
                        _SettingRow(
                          title: 'Favorite apps',
                          subtitle: 'Choose & reorder apps on home screen',
                          value: 'Manage →',
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          onTap: () => showFavoritesManagerSheet(context),
                        ),
                        _SubDivider(secondaryColor),
                        _SubSectionHeader('GESTURES', secondaryColor),
                        Obx(() => _SettingRow(
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
                          return _SettingRow(
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
                          return _SettingRow(
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
                        Obx(() => _SettingRow(
                              title: 'Double tap to lock screen',
                              subtitle:
                                  'Locks screen instantly on home double tap',
                              isToggle: true,
                              toggleValue: controller.doubleTapToLock.value,
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              onTap: controller.toggleDoubleTapToLock,
                            )),
                        _SubDivider(secondaryColor),
                        _SubSectionHeader('APP DRAWER', secondaryColor),
                        Obx(() => _SettingRow(
                              title: 'Auto-show keyboard',
                              subtitle:
                                  'Open keyboard when entering app drawer',
                              isToggle: true,
                              toggleValue: controller.autoShowKeyboard.value,
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              onTap: controller.toggleAutoShowKeyboard,
                            )),
                        Obx(() => _SettingRow(
                              title: 'Auto-launch single match',
                              subtitle:
                                  'Instantly opens when only 1 app matches search',
                              isToggle: true,
                              toggleValue:
                                  controller.autoLaunchSingleMatch.value,
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              onTap: controller.toggleAutoLaunchSingleMatch,
                            )),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTamperProtectionDialog(BuildContext context) {
    final textColor = AppColors.darkText;
    final secondaryColor = AppColors.darkSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.horizontalPadding(context),
            vertical: AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MinimalText(
                'Tamper Protection',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              MinimalText(
                'Tamper Protection prevents uninstalling Unclutter or bypassing daily app limits and focus sessions.',
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              MinimalText(
                '• All protection operates 100% locally on device.\n• No network activity or personal data access.\n• Can be disabled at any time from device administration settings.',
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryColor.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Obx(() {
                if (isOwner.value) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    alignment: Alignment.center,
                    child: MinimalText(
                      '✓ Protection is Active',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          child: MinimalText(
                            'Dismiss',
                            style: TextStyle(
                              color: secondaryColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(ctx);
                          if (Get.isRegistered<PermissionService>()) {
                            await Get.find<PermissionService>().enableProtection();
                            await _checkAllPermissions();
                          }
                        },
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: textColor,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          alignment: Alignment.center,
                          child: MinimalText(
                            'Enable Protection',
                            style: TextStyle(
                              color: AppColors.darkBackground,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showPermissionsSheet(BuildContext context) {
    final textColor = AppColors.darkText;
    final secondaryColor = AppColors.darkSecondary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.horizontalPadding(context),
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: secondaryColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MinimalText(
                    'Permissions & Health',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  MinimalText(
                    'Essential system permissions and operational diagnostics',
                    style: TextStyle(fontSize: 13, color: secondaryColor),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Obx(() {
                    final allOperational = isDefaultLauncher.value &&
                        hasUsageAccess.value &&
                        hasNotificationAccess.value &&
                        (!isEnforcementRequired.value || hasEnforcement.value);
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: textColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            allOperational
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            size: 22,
                            color: textColor,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MinimalText(
                                  allOperational
                                      ? 'All systems operational'
                                      : 'Permission setup required',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                MinimalText(
                                  allOperational
                                      ? 'Unclutter has all required permissions to run smoothly.'
                                      : 'Grant the highlighted permissions to enable full functionality.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _SubSectionHeader('CORE LAUNCHER', secondaryColor),
                        Obx(() => _SettingRow(
                              title: 'Default home launcher',
                              subtitle: isDefaultLauncher.value
                                  ? 'Unclutter is your active default launcher'
                                  : 'Required to make Unclutter your main home screen',
                              value: isDefaultLauncher.value
                                  ? '✓ Enabled'
                                  : '⚠ Needs setup →',
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              onTap: () async {
                                if (Get.isRegistered<PermissionService>()) {
                                  await Get.find<PermissionService>()
                                      .openDefaultLauncherSettings();
                                }
                              },
                            )),
                        _SubDivider(secondaryColor),
                        _SubSectionHeader('LIMITS & USAGE', secondaryColor),
                        Obx(() => _SettingRow(
                              title: 'Usage access',
                              subtitle: hasUsageAccess.value
                                  ? 'Screen time & app tracking active'
                                  : 'Required for screen time insights & daily limits',
                              value: hasUsageAccess.value
                                  ? '✓ Enabled'
                                  : '⚠ Needs setup →',
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              onTap: () async {
                                if (Get.isRegistered<PermissionService>()) {
                                  await Get.find<PermissionService>()
                                      .openUsageAccessSettings();
                                }
                              },
                            )),
                        _SubDivider(secondaryColor),
                        _SubSectionHeader('NOTIFICATIONS', secondaryColor),
                        Obx(() => _SettingRow(
                              title: 'Notification access',
                              subtitle: hasNotificationAccess.value
                                  ? 'Notification alerts active'
                                  : 'Required for focus & system alerts',
                              value: hasNotificationAccess.value
                                  ? '✓ Enabled'
                                  : '⚠ Needs setup →',
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              onTap: () async {
                                if (Get.isRegistered<PermissionService>()) {
                                  await Get.find<PermissionService>()
                                      .openNotificationSettings();
                                }
                              },
                            )),
                        _SubDivider(secondaryColor),
                        _SubSectionHeader('GESTURES (OPTIONAL)', secondaryColor),
                        Obx(() => _SettingRow(
                              title: 'Accessibility service',
                              subtitle: hasAccessibility.value
                                  ? 'Double-tap screen lock active'
                                  : 'Optional: Required for double-tap to lock screen',
                              value: hasAccessibility.value
                                  ? '✓ Enabled'
                                  : 'Optional →',
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              onTap: () async {
                                if (Get.isRegistered<PermissionService>()) {
                                  await Get.find<PermissionService>()
                                      .openAccessibilitySettings();
                                }
                              },
                            )),
                        Obx(() {
                          if (!isEnforcementRequired.value) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SubDivider(secondaryColor),
                              _SubSectionHeader('OVERLAY ENFORCEMENT', secondaryColor),
                              _SettingRow(
                                title: 'App blocking enforcement',
                                subtitle: hasEnforcement.value
                                    ? 'Screen overlay blocking enabled'
                                    : 'Required on this device to reliably block apps',
                                value: hasEnforcement.value
                                    ? '✓ Enabled'
                                    : '⚠ Needs setup →',
                                textColor: textColor,
                                secondaryColor: secondaryColor,
                                onTap: () async {
                                  if (Get.isRegistered<PermissionService>()) {
                                    await Get.find<PermissionService>()
                                        .openEnforcementSettings();
                                  }
                                },
                              ),
                            ],
                          );
                        }),
                        _SubDivider(secondaryColor),
                        _SubSectionHeader('TAMPER PROTECTION', secondaryColor),
                        Obx(() => _SettingRow(
                              title: 'Tamper Protection',
                              subtitle: isOwner.value
                                  ? 'Uninstall & limit bypass protection active'
                                  : 'Prevents bypassing limits or uninstalling during focus',
                              value: isOwner.value ? '✓ Protected' : 'Inactive (Optional)',
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              onTap: () => _showTamperProtectionDialog(context),
                            )),
                        const SizedBox(height: AppSpacing.xxxl),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAboutSheet(BuildContext context) {
    final textColor = AppColors.darkText;
    final secondaryColor = AppColors.darkSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.horizontalPadding(context),
              vertical: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 16),
                MinimalText(
                  'About',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                MinimalText(
                  'Unclutter Launcher v1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                MinimalText(
                  'Minimalist. Distraction-free. Open Source.\nBuilt for intentional phone use.',
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryColor.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                _SubDivider(secondaryColor),
                _SettingRow(
                  title: 'Device system settings',
                  subtitle: 'Open Android operating system settings',
                  value: 'Open →',
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (Get.isRegistered<NativeBridge>()) {
                      Get.find<NativeBridge>().openDeviceSettings();
                    }
                  },
                ),
                _SettingRow(
                  title: 'Screen time statistics',
                  subtitle: 'Daily phone usage and app breakdown',
                  value: 'View stats →',
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(AppRoutes.screenTime);
                  },
                ),
                _SettingRow(
                  title: 'Reset onboarding setup',
                  subtitle: 'Restart digital detox initial guide',
                  value: 'Reset →',
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (Get.isRegistered<OnboardingService>()) {
                      await Get.find<OnboardingService>().resetOnboarding();
                    }
                    if (context.mounted) {
                      context.push(AppRoutes.onboarding);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.darkText;
    final secondaryColor = AppColors.darkSecondary;

    final horizontalPadding = AppTheme.horizontalPadding(context);
    final verticalPadding = AppTheme.verticalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Back arrow and "Unclutter Settings" on the same row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  MinimalText(
                    'Unclutter Settings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Settings List with clean logical grouping matching prompt specification
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _SubSectionHeader('APPEARANCE', secondaryColor),
                    _UnclutterSettingTile(
                      title: 'Appearance',
                      subtitle: 'Text size, home screen layout & gestures',
                      onTap: () => _showAppearanceSheet(context),
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                    ),
                    _SubDivider(secondaryColor),

                    _SubSectionHeader('DISTRACTION CONTROL', secondaryColor),
                    _UnclutterSettingTile(
                      title: 'Distraction Apps',
                      subtitle: 'Choose and manage distracting apps',
                      onTap: () => showDistractionAppsManagerSheet(context),
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                    ),
                    _UnclutterSettingTile(
                      title: 'App Limits',
                      subtitle: 'Daily usage caps & restrictions',
                      onTap: () => showDailyLimitsSettingsSheet(context),
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                    ),
                    _UnclutterSettingTile(
                      title: 'Focus Mode',
                      subtitle: 'Instant distraction-free focus session',
                      onTap: () => _handleFocusMode(context),
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                    ),
                    _UnclutterSettingTile(
                      title: 'Schedule',
                      subtitle: 'Automated time-based app restrictions',
                      onTap: () => showScheduleBlockSettingsSheet(context),
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                    ),
                    _UnclutterSettingTile(
                      title: 'Hidden Apps',
                      subtitle: 'Hide apps from drawer',
                      onTap: () => showHiddenAppsManagerSheet(context),
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                    ),
                    _UnclutterSettingTile(
                      title: 'App Names',
                      subtitle: 'Rename apps for less temptation',
                      onTap: () => showRenamedAppsManagerSheet(context),
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                    ),
                    _SubDivider(secondaryColor),

                    _SubSectionHeader('SCREEN TIME', secondaryColor),
                    _UnclutterSettingTile(
                      title: 'Screen Time Statistics',
                      subtitle: 'Daily phone usage, unlocks & app breakdown',
                      onTap: () => context.push(AppRoutes.screenTime),
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                    ),
                    _SubDivider(secondaryColor),

                    _SubSectionHeader('LAUNCHER & SYSTEM', secondaryColor),
                    Obx(() => _UnclutterSettingTile(
                          title: 'Default Launcher',
                          subtitle: isDefaultLauncher.value
                              ? 'Unclutter is active as your home launcher'
                              : 'Tap to make Unclutter your default launcher',
                          trailingText: isDefaultLauncher.value ? '✓ Default' : 'Set default',
                          onTap: () async {
                            if (Get.isRegistered<PermissionService>()) {
                              await Get.find<PermissionService>()
                                  .openDefaultLauncherSettings();
                            }
                          },
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                        )),
                    Obx(() {
                      final allOperational = isDefaultLauncher.value &&
                          hasUsageAccess.value &&
                          hasNotificationAccess.value &&
                          (!isEnforcementRequired.value || hasEnforcement.value);
                      return _UnclutterSettingTile(
                        title: 'Permissions & System Health',
                        subtitle: allOperational
                            ? 'All required system permissions granted'
                            : 'Required permissions need setup',
                        trailingText: allOperational ? '✓ Operational' : '⚠ Setup',
                        onTap: () => _showPermissionsSheet(context),
                        textColor: textColor,
                        secondaryColor: secondaryColor,
                      );
                    }),
                    Obx(() => _UnclutterSettingTile(
                          title: 'Tamper Protection',
                          subtitle: isOwner.value
                              ? 'Tamper & uninstall protection active'
                              : 'Prevent bypassing limits or uninstalling during focus',
                          trailingText: isOwner.value ? '✓ Protected' : 'Inactive',
                          onTap: () => _showTamperProtectionDialog(context),
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                        )),
                    _SubDivider(secondaryColor),

                    _SubSectionHeader('ABOUT', secondaryColor),
                    _UnclutterSettingTile(
                      title: 'About Unclutter',
                      subtitle: 'Version 1.0.0 · Minimalist & intentional',
                      onTap: () => _showAboutSheet(context),
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
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

/// A clean setting tile matching the user's design:
/// Title + Subtitle on the left, optional trailing status text, chevron > on the right.
class _UnclutterSettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailingText;
  final VoidCallback onTap;
  final Color textColor;
  final Color secondaryColor;

  const _UnclutterSettingTile({
    required this.title,
    required this.subtitle,
    this.trailingText,
    required this.onTap,
    required this.textColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MinimalText(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  MinimalText(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryColor.withValues(alpha: 0.65),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingText != null) ...[
              const SizedBox(width: AppSpacing.sm),
              MinimalText(
                trailingText!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: trailingText!.contains('✓')
                      ? textColor
                      : secondaryColor.withValues(alpha: 0.75),
                ),
              ),
            ],
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: secondaryColor.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback onTap;
  final Color textColor;
  final Color secondaryColor;
  final bool isToggle;
  final bool? toggleValue;

  const _SettingRow({
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
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
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
                      fontSize: 15,
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
                      ? textColor
                      : secondaryColor.withValues(alpha: 0.45),
                ),
              )
            else if (value != null)
              MinimalText(
                value!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: value!.contains('✓') ? textColor : secondaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SubSectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _SubSectionHeader(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: MinimalText(
        label,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _SubDivider extends StatelessWidget {
  final Color color;
  const _SubDivider(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: color.withValues(alpha: 0.08),
    );
  }
}
