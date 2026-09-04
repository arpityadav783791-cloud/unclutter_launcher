import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';
import '../../apps/controllers/apps_controller.dart';
import '../../apps/models/app_info.dart';
import '../../apps/services/app_config_service.dart';
import '../../favorites/controllers/favorites_controller.dart';

/// Displays a clean dialog to rename an application.
void showAppRenameDialog({
  required BuildContext context,
  required AppInfo app,
  required String currentDisplayName,
  required AppConfigService configService,
  required AppsController appsController,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

  final controller = TextEditingController(text: currentDisplayName);

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkBackground : const Color(0xFFF5F5F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: MinimalText(
          'Rename',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(fontSize: 17, color: textColor),
          cursorColor: textColor,
          decoration: InputDecoration(
            hintText: app.name,
            hintStyle:
                TextStyle(color: secondaryColor.withValues(alpha: 0.5)),
            border: InputBorder.none,
          ),
          onSubmitted: (value) async {
            await configService.setCustomName(app.packageName, value);
            appsController.refreshVisibility();
            if (Get.isRegistered<FavoritesController>()) {
              Get.find<FavoritesController>().rebuildFavorites();
            }
            if (ctx.mounted) Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: MinimalText(
              'Cancel',
              style: TextStyle(color: secondaryColor, fontSize: 15),
            ),
          ),
          TextButton(
            onPressed: () async {
              await configService.setCustomName(
                  app.packageName, controller.text);
              appsController.refreshVisibility();
              if (Get.isRegistered<FavoritesController>()) {
                Get.find<FavoritesController>().rebuildFavorites();
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: MinimalText(
              'Save',
              style: TextStyle(color: textColor, fontSize: 15),
            ),
          ),
        ],
      );
    },
  );
}
