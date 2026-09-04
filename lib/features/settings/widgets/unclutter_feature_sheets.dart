import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';
import '../../apps/controllers/apps_controller.dart';
import '../../apps/models/app_info.dart';
import '../../apps/services/app_config_service.dart';
import '../../favorites/controllers/favorites_controller.dart';
import '../../mindful_delay/services/mindful_delay_service.dart';
import '../../daily_limits/services/daily_limit_service.dart';
import '../../scheduled_block/services/schedule_service.dart';
import '../../launcher/widgets/app_rename_dialog.dart';

/// Bottom sheets for configuring Unclutter's productivity features:
/// Mindful Delay, Daily Limits, Scheduled Block, Hidden Apps, Renamed Apps, and Favorites.

void showMindfulDelaySettingsSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF9F9F9);

  final delayService = Get.find<MindfulDelayService>();
  final appsController = Get.find<AppsController>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: bgColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final apps = appsController.allApps
              .where((a) => a.packageName != 'com.minimal.launcher.settings')
              .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      'Mindful Delay Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MinimalText(
                      'Adds a breathing pause before an app opens to prevent mindless clicking.',
                      style: TextStyle(fontSize: 13, color: secondaryColor),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: apps.length,
                        separatorBuilder: (_, __) => Divider(
                          color: secondaryColor.withValues(alpha: 0.1),
                          height: 1,
                        ),
                        itemBuilder: (context, i) {
                          final app = apps[i];
                          final isEnabled =
                              delayService.isEnabled(app.packageName);
                          final duration =
                              delayService.getDuration(app.packageName);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: MinimalText(
                              app.name,
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor,
                                fontWeight:
                                    isEnabled ? FontWeight.w500 : FontWeight.w400,
                              ),
                            ),
                            subtitle: isEnabled
                                ? MinimalText(
                                    '$duration seconds delay',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: secondaryColor,
                                    ),
                                  )
                                : null,
                            trailing: DropdownButton<int>(
                              value: isEnabled ? duration : 0,
                              dropdownColor: bgColor,
                              underline: const SizedBox.shrink(),
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('Off')),
                                DropdownMenuItem(value: 5, child: Text('5s')),
                                DropdownMenuItem(value: 10, child: Text('10s')),
                                DropdownMenuItem(value: 15, child: Text('15s')),
                                DropdownMenuItem(value: 30, child: Text('30s')),
                              ],
                              onChanged: (val) async {
                                if (val == null || val == 0) {
                                  await delayService.disable(app.packageName);
                                } else {
                                  await delayService.setDuration(
                                      app.packageName, val);
                                }
                                setSheetState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

void showDailyLimitsSettingsSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF9F9F9);

  final limitService = Get.find<DailyLimitService>();
  final appsController = Get.find<AppsController>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: bgColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final apps = appsController.allApps
              .where((a) => a.packageName != 'com.minimal.launcher.settings')
              .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      'Daily App Limits',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MinimalText(
                      'Set daily usage limits to protect focus and screen time.',
                      style: TextStyle(fontSize: 13, color: secondaryColor),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: apps.length,
                        separatorBuilder: (_, __) => Divider(
                          color: secondaryColor.withValues(alpha: 0.1),
                          height: 1,
                        ),
                        itemBuilder: (context, i) {
                          final app = apps[i];
                          final isEnabled =
                              limitService.isEnabled(app.packageName);
                          final limitMins = isEnabled
                              ? limitService.effectiveLimitMinutes(app.packageName)
                              : 0;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: MinimalText(
                              app.name,
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor,
                                fontWeight:
                                    isEnabled ? FontWeight.w500 : FontWeight.w400,
                              ),
                            ),
                            subtitle: isEnabled
                                ? MinimalText(
                                    '$limitMins mins allowed daily',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: secondaryColor,
                                    ),
                                  )
                                : null,
                            trailing: DropdownButton<int>(
                              value: isEnabled ? limitMins : 0,
                              dropdownColor: bgColor,
                              underline: const SizedBox.shrink(),
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('No limit')),
                                DropdownMenuItem(value: 15, child: Text('15m')),
                                DropdownMenuItem(value: 30, child: Text('30m')),
                                DropdownMenuItem(value: 45, child: Text('45m')),
                                DropdownMenuItem(value: 60, child: Text('1 hour')),
                                DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                                DropdownMenuItem(value: 120, child: Text('2 hours')),
                              ],
                              onChanged: (val) async {
                                if (val == null || val == 0) {
                                  await limitService.disable(app.packageName);
                                } else {
                                  await limitService.setLimit(
                                      app.packageName, val);
                                }
                                setSheetState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

void showScheduleBlockSettingsSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  final bgColor = isDark ? const Color(0xFF111111) : const Color(0xFFF9F9F9);

  final scheduleService = Get.find<ScheduleService>();
  final appsController = Get.find<AppsController>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: bgColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final apps = appsController.allApps
              .where((a) => a.packageName != 'com.minimal.launcher.settings')
              .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      'Scheduled App Blocking',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MinimalText(
                      'Blocks selected apps during quiet / bedtime hours (default 22:00 - 07:00).',
                      style: TextStyle(fontSize: 13, color: secondaryColor),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: apps.length,
                        separatorBuilder: (_, __) => Divider(
                          color: secondaryColor.withValues(alpha: 0.1),
                          height: 1,
                        ),
                        itemBuilder: (context, i) {
                          final app = apps[i];
                          final isEnabled =
                              scheduleService.isEnabled(app.packageName);

                          return SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: MinimalText(
                              app.name,
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor,
                                fontWeight:
                                    isEnabled ? FontWeight.w500 : FontWeight.w400,
                              ),
                            ),
                            subtitle: isEnabled
                                ? MinimalText(
                                    'Blocked 22:00 – 07:00',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: secondaryColor,
                                    ),
                                  )
                                : null,
                            value: isEnabled,
                            activeThumbColor: textColor,
                            onChanged: (val) async {
                              if (val) {
                                // Default overnight 22:00 (1320m) to 07:00 (420m)
                                await scheduleService.setSchedule(
                                  app.packageName,
                                  startMinutes: 22 * 60,
                                  endMinutes: 7 * 60,
                                );
                              } else {
                                await scheduleService.disable(app.packageName);
                              }
                              setSheetState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

void showHiddenAppsManagerSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF9F9F9);

  final configService = Get.find<AppConfigService>();
  final appsController = Get.find<AppsController>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: bgColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final hiddenPackages = configService.hiddenPackageNames;
          final hiddenApps = appsController.allApps
              .where((a) => hiddenPackages.contains(a.packageName))
              .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      'Hidden Apps (${hiddenApps.length})',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MinimalText(
                      'These apps are hidden from the app drawer. Tap unhide to restore them.',
                      style: TextStyle(fontSize: 13, color: secondaryColor),
                    ),
                    const SizedBox(height: 16),
                    if (hiddenApps.isEmpty)
                      Expanded(
                        child: Center(
                          child: MinimalText(
                            'No apps are hidden',
                            style: TextStyle(
                              fontSize: 15,
                              color: secondaryColor,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: hiddenApps.length,
                          separatorBuilder: (_, __) => Divider(
                            color: secondaryColor.withValues(alpha: 0.1),
                            height: 1,
                          ),
                          itemBuilder: (context, i) {
                            final app = hiddenApps[i];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: MinimalText(
                                app.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                              subtitle: MinimalText(
                                app.packageName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryColor,
                                ),
                              ),
                              trailing: TextButton(
                                onPressed: () async {
                                  await configService.setHidden(
                                      app.packageName, false);
                                  appsController.refreshVisibility();
                                  setSheetState(() {});
                                },
                                child: MinimalText(
                                  'Unhide',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

void showFavoritesManagerSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF9F9F9);

  final favoritesController = Get.find<FavoritesController>();
  final appsController = Get.find<AppsController>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: bgColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final favs = favoritesController.favoriteApps;
          final allApps = appsController.apps
              .where((a) => a.packageName != 'com.minimal.launcher.settings')
              .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    Row(
                      children: [
                        MinimalText(
                          'Home Favorites (${favs.length})',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            _showAddFavoritePicker(
                              context,
                              allApps,
                              favoritesController,
                              () => setSheetState(() {}),
                            );
                          },
                          child: MinimalText(
                            '+ Add App',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    MinimalText(
                      'Applications shown on your minimalist home screen.',
                      style: TextStyle(fontSize: 13, color: secondaryColor),
                    ),
                    const SizedBox(height: 16),
                    if (favs.isEmpty)
                      Expanded(
                        child: Center(
                          child: MinimalText(
                            'No favorites added yet',
                            style: TextStyle(
                              fontSize: 15,
                              color: secondaryColor,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ReorderableListView.builder(
                          scrollController: scrollController,
                          itemCount: favs.length,
                          onReorderItem: (oldIndex, newIndex) async {
                            final item = favs[oldIndex];
                            await favoritesController.reorderFavorite(
                                item.packageName, newIndex);
                            setSheetState(() {});
                          },
                          itemBuilder: (context, i) {
                            final app = favs[i];
                            return ListTile(
                              key: ValueKey(app.uniqueKey),
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.drag_handle,
                                  color: secondaryColor.withValues(alpha: 0.5)),
                              title: MinimalText(
                                app.isWorkProfile ? '${app.name} 💼' : app.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.close,
                                    color: secondaryColor, size: 20),
                                onPressed: () async {
                                  await favoritesController
                                      .removeFavorite(app.packageName);
                                  setSheetState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

void _showAddFavoritePicker(
  BuildContext context,
  List<AppInfo> apps,
  FavoritesController favoritesController,
  VoidCallback onUpdated,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final bgColor = isDark ? AppColors.darkBackground : Colors.white;

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: bgColor,
        title: MinimalText(
          'Select App for Home',
          style: TextStyle(color: textColor, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: ListView.builder(
            itemCount: apps.length,
            itemBuilder: (context, i) {
              final app = apps[i];
              final isFav = favoritesController.isFavorite(app.packageName);
              return ListTile(
                title: MinimalText(
                  app.isWorkProfile ? '${app.name} 💼' : app.name,
                  style: TextStyle(
                    color: isFav ? textColor.withValues(alpha: 0.4) : textColor,
                  ),
                ),
                trailing: isFav
                    ? const Icon(Icons.check, size: 18, color: Colors.green)
                    : null,
                onTap: isFav
                    ? null
                    : () async {
                        await favoritesController.addFavorite(app.uniqueKey);
                        onUpdated();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
              );
            },
          ),
        ),
      );
    },
  );
}

void showRenamedAppsManagerSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.darkText : AppColors.lightText;
  final secondaryColor =
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF9F9F9);

  final configService = Get.find<AppConfigService>();
  final appsController = Get.find<AppsController>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: bgColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final apps = appsController.allApps
              .where((a) => a.packageName != 'com.minimal.launcher.settings')
              .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      'Renamed Apps',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MinimalText(
                      'Customize app labels to make them more intentional or discreet.',
                      style: TextStyle(fontSize: 13, color: secondaryColor),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: apps.length,
                        separatorBuilder: (_, __) => Divider(
                          color: secondaryColor.withValues(alpha: 0.1),
                          height: 1,
                        ),
                        itemBuilder: (context, i) {
                          final app = apps[i];
                          final cfg =
                              configService.getConfig(app.packageName);
                          final hasCustomName = cfg.customName != null &&
                              cfg.customName!.isNotEmpty;
                          final currentDisplayName =
                              configService.displayName(
                                  app.packageName, app.name);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: MinimalText(
                              currentDisplayName,
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor,
                                fontWeight: hasCustomName
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            subtitle: hasCustomName
                                ? MinimalText(
                                    'Original: ${app.name}',
                                    style: TextStyle(
                                        fontSize: 12, color: secondaryColor),
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasCustomName)
                                  IconButton(
                                    icon: Icon(Icons.undo,
                                        size: 18, color: secondaryColor),
                                    tooltip: 'Reset name',
                                    onPressed: () async {
                                      await configService.setCustomName(
                                          app.packageName, null);
                                      appsController.refreshVisibility();
                                      if (Get.isRegistered<
                                          FavoritesController>()) {
                                        Get.find<FavoritesController>()
                                            .rebuildFavorites();
                                      }
                                      setSheetState(() {});
                                    },
                                  ),
                                TextButton(
                                  onPressed: () {
                                    showAppRenameDialog(
                                      context: context,
                                      app: app,
                                      currentDisplayName:
                                          currentDisplayName,
                                      configService: configService,
                                      appsController: appsController,
                                    );
                                  },
                                  child: MinimalText(
                                    'Rename',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
