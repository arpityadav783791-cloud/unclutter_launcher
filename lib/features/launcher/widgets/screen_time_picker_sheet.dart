import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';
import '../../apps/controllers/apps_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import 'app_options_bottom_sheet.dart';

/// Opens the options bottom sheet for the Home Screen Time widget.
void showScreenTimeOptionsBottomSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  final settings = Get.find<SettingsController>();

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
                'Screen Time options',
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
              const SizedBox(height: 8),
              OptionTile(
                label: 'View detailed stats',
                color: textColor,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.screenTime);
                },
              ),
              OptionTile(
                label: 'Select custom screen time app',
                color: textColor,
                onTap: () {
                  Navigator.pop(ctx);
                  _showSelectCustomAppSheet(context);
                },
              ),
              Obx(() {
                final customPkg = settings.customScreenTimePackage.value;
                if (customPkg == null || customPkg.isEmpty) {
                  return const SizedBox.shrink();
                }
                return OptionTile(
                  label: 'Reset to Digital Wellbeing default',
                  color: textColor,
                  onTap: () async {
                    await settings.setCustomScreenTimePackage(null);
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

void _showSelectCustomAppSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  final appsController = Get.find<AppsController>();
  final settings = Get.find<SettingsController>();

  showModalBottomSheet(
    context: context,
    backgroundColor:
        isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final apps = appsController.apps;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MinimalText(
                    'Assign Screen Time App',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: secondaryColor.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: apps.length,
                      itemBuilder: (context, index) {
                        final app = apps[index];
                        final name = appsController.displayName(app);
                        final isSelected =
                            settings.customScreenTimePackage.value ==
                                app.packageName;

                        return InkWell(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            await settings
                                .setCustomScreenTimePackage(app.packageName);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: MinimalText(
                                    name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  MinimalText(
                                    '✓',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
