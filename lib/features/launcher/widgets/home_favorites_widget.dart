import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/widgets/minimal_text.dart';
import '../../apps/controllers/apps_controller.dart';
import '../../apps/models/app_info.dart';
import '../../favorites/controllers/favorites_controller.dart';
import '../../productivity/controllers/productivity_controller.dart';
import '../../settings/controllers/settings_controller.dart';

/// Single Responsibility: Renders home screen favorite apps respecting alignment and counts.
class HomeFavoritesWidget extends StatelessWidget {
  final FavoritesController favoritesController;
  final AppsController appsController;
  final ProductivityController productivity;
  final Color textColor;
  final Color secondaryColor;
  final void Function(BuildContext context, AppInfo app, String name) onLongPressApp;

  const HomeFavoritesWidget({
    super.key,
    required this.favoritesController,
    required this.appsController,
    required this.productivity,
    required this.textColor,
    required this.secondaryColor,
    required this.onLongPressApp,
  });

  CrossAxisAlignment _resolveCrossAxis(String alignment) {
    switch (alignment) {
      case 'center':
        return CrossAxisAlignment.center;
      case 'right':
        return CrossAxisAlignment.end;
      case 'left':
      default:
        return CrossAxisAlignment.start;
    }
  }

  TextAlign _resolveTextAlign(String alignment) {
    switch (alignment) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'left':
      default:
        return TextAlign.left;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();

    return Obx(() {
      final allFavorites = favoritesController.favoriteApps;
      final maxApps = settings.homeAppsCount.value;
      final favorites = allFavorites.take(maxApps).toList();

      if (maxApps == 0) {
        // Pure Zen mode
        return const SizedBox.shrink();
      }

      final alignment = settings.homeAlignment.value;
      final isBottom = settings.homeBottomAlignment.value;
      final isBold = settings.boldFont.value;
      final crossAxis = _resolveCrossAxis(alignment);
      final textAlign = _resolveTextAlign(alignment);

      if (favorites.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinimalText(
                'No favorite apps yet',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              MinimalText(
                'Swipe up to view all apps\nLong-press an app to add to favorites',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryColor.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      }

      final items = favorites.map((app) {
        final name = appsController.displayName(app);
        final recentBadge = app.isRecentInstall ? ' ✦' : '';
        final workBadge = app.isWorkProfile ? ' 💼' : '';
        final badge = '$workBadge$recentBadge';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              productivity.handleAppLaunch(
                app.packageName,
                userSerial: app.userSerial,
                activityName: app.activityName,
              );
            },
            onLongPress: () => onLongPressApp(context, app, name),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: MinimalText(
                '$name$badge',
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                  color: textColor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        );
      }).toList();

      return Align(
        alignment: isBottom ? Alignment.bottomCenter : Alignment.center,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: crossAxis,
            children: items,
          ),
        ),
      );
    });
  }
}
