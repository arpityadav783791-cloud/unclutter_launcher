import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';
import '../../apps/controllers/apps_controller.dart';
import '../../apps/models/app_info.dart';
import '../controllers/settings_controller.dart';

/// Bottom sheet to pick any installed application for Swipe Left / Swipe Right gesture,
/// matching the exact capability in Olauncher.
void showGestureAppPickerSheet(
  BuildContext context, {
  required bool isLeft,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  final appsController = Get.find<AppsController>();
  final settings = Get.find<SettingsController>();

  final currentPkg = isLeft
      ? settings.swipeLeftPackage.value
      : settings.swipeRightPackage.value;
  final title = isLeft ? 'Swipe left app' : 'Swipe right app';
  final defaultName = isLeft ? 'Camera (default)' : 'Phone (default)';

  final RxString searchQuery = ''.obs;

  showModalBottomSheet(
    context: context,
    backgroundColor:
        isDark ? AppColors.darkBackground : const Color(0xFFF5F5F5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (sheetContext, scrollController) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MinimalText(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: MinimalText(
                          '✕',
                          style: TextStyle(
                            fontSize: 18,
                            color: secondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (v) => searchQuery.value = v.trim().toLowerCase(),
                    style: TextStyle(fontSize: 15, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Search apps...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: secondaryColor.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFFEBEBEB),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      if (isLeft) {
                        await settings.setSwipeLeftPackage(null);
                      } else {
                        await settings.setSwipeRightPackage(null);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          MinimalText(
                            defaultName,
                            style: TextStyle(
                              fontSize: 15,
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (currentPkg == null || currentPkg.isEmpty)
                            const MinimalText(
                              '✓',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 1,
                    color: secondaryColor.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Obx(() {
                      final query = searchQuery.value;
                      final allApps = List<AppInfo>.from(appsController.apps)
                        ..sort((a, b) => appsController
                            .displayName(a)
                            .toLowerCase()
                            .compareTo(appsController.displayName(b).toLowerCase()));

                      final filtered = query.isEmpty
                          ? allApps
                          : allApps
                              .where((a) => appsController
                                  .displayName(a)
                                  .toLowerCase()
                                  .contains(query))
                              .toList();

                      return ListView.builder(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (itemCtx, index) {
                          final app = filtered[index];
                          final name = appsController.displayName(app);
                          final isSelected = currentPkg == app.packageName;

                          return InkWell(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              if (isLeft) {
                                await settings.setSwipeLeftPackage(app.packageName);
                              } else {
                                await settings.setSwipeRightPackage(app.packageName);
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: MinimalText(
                                      name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const MinimalText(
                                      '✓',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
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
