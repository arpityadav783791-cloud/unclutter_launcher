import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/minimal_text.dart';
import '../controllers/distraction_app_controller.dart';
import '../models/distraction_app.dart';

/// Opens the dedicated Distraction Apps management sheet from Settings.
void showDistractionAppsManagerSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF9F9F9);

  final controller = Get.isRegistered<DistractionAppController>()
      ? Get.find<DistractionAppController>()
      : Get.put(DistractionAppController(), permanent: true);

  controller.refreshList();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: bgColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (sheetContext, scrollController) {
          final horizontalPadding = AppTheme.horizontalPadding(sheetContext);

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top handle
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

                // Title row with + Add App button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MinimalText(
                      'Distraction Apps',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showAddAppPickerSheet(sheetContext, controller);
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const MinimalText(
                          '+ Add App',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Explanation Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF161616)
                        : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: secondaryColor.withValues(alpha: 0.12),
                    ),
                  ),
                  child: MinimalText(
                    'Apps marked as distractions are prioritized for digital detox and mindful usage.',
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryColor.withValues(alpha: 0.8),
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Scrollable Distraction Apps list
                Expanded(
                  child: Obx(() {
                    final apps = controller.distractionApps;
                    if (apps.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MinimalText(
                              'No distraction apps configured',
                              style: TextStyle(
                                fontSize: 15,
                                color: secondaryColor.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            MinimalText(
                              'Tap "+ Add App" above to add apps',
                              style: TextStyle(
                                fontSize: 13,
                                color: secondaryColor.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: apps.length,
                      separatorBuilder: (_, __) => Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: secondaryColor.withValues(alpha: 0.07),
                      ),
                      itemBuilder: (context, index) {
                        final app = apps[index];
                        return _DistractionAppTile(
                          app: app,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          onToggle: () => controller.toggleApp(app.packageName),
                          onRemove: () => controller.removeApp(app.packageName),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _DistractionAppTile extends StatelessWidget {
  final DistractionApp app;
  final Color textColor;
  final Color secondaryColor;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const _DistractionAppTile({
    required this.app,
    required this.textColor,
    required this.secondaryColor,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MinimalText(
                  app.appName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: app.isEnabled
                        ? textColor
                        : textColor.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 2),
                MinimalText(
                  app.isAutomaticallyDetected
                      ? 'Auto-detected${app.categoryLabel != null ? ' • ${app.categoryLabel}' : ''}'
                      : 'Manually added',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ON / OFF Toggle button
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onToggle();
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: app.isEnabled
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : secondaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: app.isEnabled
                      ? AppColors.accent.withValues(alpha: 0.3)
                      : secondaryColor.withValues(alpha: 0.15),
                ),
              ),
              child: MinimalText(
                app.isEnabled ? 'ON' : 'OFF',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: app.isEnabled
                      ? AppColors.accent
                      : secondaryColor.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to search and pick an installed app to add to Distraction Apps.
void _showAddAppPickerSheet(
  BuildContext context,
  DistractionAppController controller,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF9F9F9);

  controller.searchQuery.value = '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: bgColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (sheetContext, scrollController) {
          final horizontalPadding = AppTheme.horizontalPadding(sheetContext);

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
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
                  'Add Distraction App',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),

                // Search field
                TextField(
                  autofocus: false,
                  cursorColor: textColor,
                  style: TextStyle(fontSize: 15, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search installed apps...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: secondaryColor.withValues(alpha: 0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: secondaryColor.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF141414)
                        : const Color(0xFFEEEEEE),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => controller.searchQuery.value = val,
                ),
                const SizedBox(height: 14),

                // Candidate apps list
                Expanded(
                  child: Obx(() {
                    final candidates = controller.candidateApps;
                    if (candidates.isEmpty) {
                      return Center(
                        child: MinimalText(
                          'No apps match search',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryColor.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: candidates.length,
                      separatorBuilder: (_, __) => Container(
                        height: 1,
                        color: secondaryColor.withValues(alpha: 0.07),
                      ),
                      itemBuilder: (context, index) {
                        final app = candidates[index];
                        return InkWell(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            await controller.addApp(app.packageName);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: MinimalText(
                                    app.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: textColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                MinimalText(
                                  '+ Add',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
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
          );
        },
      );
    },
  );
}
