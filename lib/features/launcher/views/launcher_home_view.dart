import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';
import '../../../core/routes/app_routes.dart';
import '../../apps/controllers/apps_controller.dart';
import '../../apps/models/app_info.dart';
import '../../apps/services/app_config_service.dart';
import '../../favorites/controllers/favorites_controller.dart';
import '../../productivity/controllers/productivity_controller.dart';
import '../../mindful_delay/controllers/mindful_delay_controller.dart';
import '../../mindful_delay/models/mindful_delay_config.dart';
import '../../daily_limits/controllers/daily_limit_controller.dart';
import '../../daily_limits/models/daily_limit_config.dart';
import '../../focus_mode/controllers/focus_mode_controller.dart';
import '../../focus_mode/models/focus_mode_config.dart';
import '../../scheduled_block/controllers/schedule_controller.dart';
import '../../scheduled_block/models/schedule_config.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../timed_access/controllers/timed_access_controller.dart';
import '../../../core/services/native_bridge.dart';
import '../controllers/launcher_controller.dart';
import '../services/home_gesture_service.dart';
import '../widgets/home_clock_widget.dart';
import '../widgets/home_favorites_widget.dart';

class LauncherHomeView extends StatefulWidget {
  const LauncherHomeView({super.key});

  @override
  State<LauncherHomeView> createState() => _LauncherHomeViewState();
}

class _LauncherHomeViewState extends State<LauncherHomeView> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  int _currentPage = 0;
  double _pullDownDistance = 0.0;
  DateTime? _lastSwipeDownTime;

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Colors.black;
    const textColor = AppColors.darkText;
    const secondaryColor = AppColors.darkSecondary;

    final controller = Get.find<LauncherController>();
    final appsController = Get.find<AppsController>();
    final favoritesController = Get.find<FavoritesController>();
    final productivity = Get.find<ProductivityController>();
    final timedAccess = Get.isRegistered<TimedAccessController>()
        ? Get.find<TimedAccessController>()
        : null;

    return PopScope(
      canPop: _currentPage == 0,
      onPopInvoked: (didPop) {
        if (!didPop && _pageController.hasClients && _currentPage != 0) {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (_currentPage == 0) {
                if (notification is ScrollUpdateNotification) {
                  if (notification.metrics.pixels <= 0 &&
                      (notification.scrollDelta ?? 0) < 0) {
                    _pullDownDistance += -(notification.scrollDelta ?? 0);
                  }
                } else if (notification is OverscrollNotification) {
                  if (notification.overscroll < 0) {
                    _pullDownDistance += -notification.overscroll;
                  }
                } else if (notification is ScrollEndNotification) {
                  final velocity =
                      notification.dragDetails?.primaryVelocity ?? 0;
                  final now = DateTime.now();
                  final canTrigger = _lastSwipeDownTime == null ||
                      now.difference(_lastSwipeDownTime!) >
                          const Duration(milliseconds: 600);

                  if (canTrigger &&
                      (_pullDownDistance > 30 || velocity > 250)) {
                    _lastSwipeDownTime = now;
                    _pullDownDistance = 0;
                    final gestureService = Get.find<HomeGestureService>();
                    gestureService.handleSwipeDown(context);
                  }
                  _pullDownDistance = 0;
                }
              }
              return false;
            },
            child: PageView(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                // ── PAGE 0: DEDICATED MINIMALIST HOME SCREEN (Black wallpaper, Clock, Favorites only) ──
                _buildHomeScreen(
                  context: context,
                  controller: controller,
                  appsController: appsController,
                  favoritesController: favoritesController,
                  productivity: productivity,
                  timedAccess: timedAccess,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                ),

                // ── PAGE 1: ALL APPS DRAWER (Search + Complete installed apps list) ──
                _buildAllAppsDrawer(
                  context: context,
                  appsController: appsController,
                  favoritesController: favoritesController,
                  productivity: productivity,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeScreen({
    required BuildContext context,
    required LauncherController controller,
    required AppsController appsController,
    required FavoritesController favoritesController,
    required ProductivityController productivity,
    required TimedAccessController? timedAccess,
    required Color textColor,
    required Color secondaryColor,
  }) {
    final gestureService = Get.find<HomeGestureService>();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () => gestureService.handleDoubleTap(),
      onHorizontalDragEnd: (details) {
        final vx = details.primaryVelocity ?? 0;
        if (vx < -200) {
          gestureService.handleSwipeLeft();
        } else if (vx > 200) {
          gestureService.handleSwipeRight();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modular Clock, Date & Battery Widget
            HomeClockWidget(
              controller: controller,
              textColor: textColor,
              secondaryColor: secondaryColor,
              onLongPress: () => _showClockMenu(context),
            ),

            // Active Distraction Session Indicator (if any)
            if (timedAccess != null)
              Obx(() {
                final session = timedAccess.currentSession.value;
                if (session == null || session.isExpired) {
                  return const SizedBox.shrink();
                }
                final secs = timedAccess.remainingSeconds.value;
                final m = secs ~/ 60;
                final s = (secs % 60).toString().padLeft(2, '0');
                return Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF262626)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MinimalText(
                        '⏳ ${session.appName}: $m:$s remaining',
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 28),
            Container(
              height: 1,
              color: secondaryColor.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 24),

            // Modular Favorites Widget (Alignment, Count Limits, Badges)
            Expanded(
              child: HomeFavoritesWidget(
                favoritesController: favoritesController,
                appsController: appsController,
                productivity: productivity,
                textColor: textColor,
                secondaryColor: secondaryColor,
                onLongPressApp: (ctx, app, name) {
                  _showAppOptions(
                    ctx,
                    app,
                    name,
                    favoritesController,
                    productivity,
                    true,
                  );
                },
              ),
            ),

            // Bottom "Swipe up for all apps"
            GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MinimalText(
                        'Swipe up for all apps',
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryColor.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 4),
                      MinimalText(
                        '↑',
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllAppsDrawer({
    required BuildContext context,
    required AppsController appsController,
    required FavoritesController favoritesController,
    required ProductivityController productivity,
    required Color textColor,
    required Color secondaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drawer Header: "↓ Home" button and search field
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 14, top: 8, bottom: 8),
                  child: MinimalText(
                    '↓ Home',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: secondaryColor,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  cursorColor: textColor,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search apps…',
                    hintStyle: TextStyle(
                      fontSize: 18,
                      color: secondaryColor.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (val) {
                    _searchQuery.value = val.trim();
                    final settings = Get.find<SettingsController>();
                    if (settings.autoLaunchSingleMatch.value) {
                      final trimmed = val.trim();
                      if (trimmed.isNotEmpty &&
                          !val.startsWith(' ') &&
                          !val.startsWith('!')) {
                        final matches = appsController.apps.where((app) {
                          final name =
                              appsController.displayName(app).toLowerCase();
                          return name.contains(trimmed.toLowerCase()) ||
                              app.packageName
                                  .toLowerCase()
                                  .contains(trimmed.toLowerCase());
                        }).toList();
                        if (matches.length == 1) {
                          HapticFeedback.lightImpact();
                          productivity
                              .handleAppLaunch(matches.first.packageName);
                        }
                      }
                    }
                  },
                  textInputAction: TextInputAction.search,
                  onSubmitted: (val) {
                    final trimmed = val.trim();
                    if (trimmed.isEmpty) return;
                    if (trimmed.startsWith('!')) {
                      if (Get.isRegistered<NativeBridge>()) {
                        Get.find<NativeBridge>().openWebSearch(
                            'https://duckduckgo.com/?q=${Uri.encodeComponent(trimmed)}');
                      }
                    } else {
                      final matches = appsController.apps.where((app) {
                        final name =
                            appsController.displayName(app).toLowerCase();
                        return name.contains(trimmed.toLowerCase()) ||
                            app.packageName
                                .toLowerCase()
                                .contains(trimmed.toLowerCase());
                      }).toList();
                      if (matches.isNotEmpty) {
                        productivity
                            .handleAppLaunch(matches.first.packageName);
                      } else {
                        if (Get.isRegistered<NativeBridge>()) {
                          Get.find<NativeBridge>().openWebSearch(trimmed);
                        }
                      }
                    }
                  },
                ),
              ),
              Obx(() {
                if (_searchQuery.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _searchQuery.value = '';
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: MinimalText(
                      'Clear',
                      style: TextStyle(fontSize: 14, color: secondaryColor),
                    ),
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 12),
          Container(
            height: 1,
            color: secondaryColor.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),

          // Complete list of apps
          Expanded(
            child: Obx(() {
              if (appsController.isLoading.value) {
                return Center(
                  child: MinimalText(
                    'Loading…',
                    style: TextStyle(color: secondaryColor, fontSize: 16),
                  ),
                );
              }

              final query = _searchQuery.value.toLowerCase();
              final allVisible = appsController.apps;
              final favorites = favoritesController.favoriteApps;
              final favPackages = favorites.map((a) => a.packageName).toSet();

              final filtered = query.isEmpty
                  ? allVisible
                  : allVisible.where((app) {
                      final name =
                          appsController.displayName(app).toLowerCase();
                      return name.contains(query) ||
                          app.packageName.toLowerCase().contains(query);
                    }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MinimalText(
                        'No apps found',
                        style: TextStyle(color: secondaryColor, fontSize: 16),
                      ),
                      if (query.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            if (Get.isRegistered<NativeBridge>()) {
                              Get.find<NativeBridge>()
                                  .openWebSearch(query.trim());
                            }
                          },
                          child: MinimalText(
                            'Search web for "$query" ↵',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final app = filtered[index];
                  final isFav = favPackages.contains(app.packageName);
                  final name = appsController.displayName(app);

                  return _AppTile(
                    name: name,
                    isFavorite: isFav,
                    isRecentInstall: app.isRecentInstall,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      productivity.handleAppLaunch(app.packageName);
                    },
                    onLongPress: () => _showAppOptions(
                      context,
                      app,
                      name,
                      favoritesController,
                      productivity,
                      isFav,
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showAppOptions(
    BuildContext context,
    AppInfo app,
    String displayName,
    FavoritesController favoritesController,
    ProductivityController productivity,
    bool isFavorite,
  ) {
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
          isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5),
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
                _OptionTile(
                  label: 'Open',
                  color: textColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    productivity.handleAppLaunch(app.packageName);
                  },
                ),
                _OptionTile(
                  label: isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  color: textColor,
                  onTap: () {
                    favoritesController.toggleFavorite(app.packageName);
                    Navigator.pop(ctx);
                  },
                ),
                if (isFavorite) ...[
                  _OptionTile(
                    label: 'Move up',
                    color: textColor,
                    onTap: () {
                      favoritesController.moveUp(app.packageName);
                      Navigator.pop(ctx);
                    },
                  ),
                  _OptionTile(
                    label: 'Move down',
                    color: textColor,
                    onTap: () {
                      favoritesController.moveDown(app.packageName);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
                _OptionTile(
                  label: 'Rename',
                  color: textColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showRenameDialog(
                      context,
                      app,
                      displayName,
                      configService,
                      appsController,
                    );
                  },
                ),
                _OptionTile(
                  label: hasDelay ? 'Mindful Delay (on)' : 'Mindful Delay',
                  color: textColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showMindfulDelayOptions(
                      context,
                      app,
                      displayName,
                      delayController,
                    );
                  },
                ),
                _OptionTile(
                  label: Get.find<DailyLimitController>().isEnabledFor(app.packageName)
                      ? 'Daily Limit (on)'
                      : 'Daily Limit',
                  color: textColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDailyLimitOptions(
                      context,
                      app,
                      displayName,
                    );
                  },
                ),
                _OptionTile(
                  label: Get.find<ScheduleController>().isEnabledFor(app.packageName)
                      ? 'Schedule Block (on)'
                      : 'Schedule Block',
                  color: textColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showScheduleOptions(context, app, displayName);
                  },
                ),
                _OptionTile(
                  label: Get.find<FocusModeController>().isAppInBlockList(app.packageName)
                      ? 'Remove from Focus block list'
                      : 'Add to Focus block list',
                  color: textColor,
                  onTap: () async {
                    await Get.find<FocusModeController>().toggleBlockedApp(app.packageName);
                    Navigator.pop(ctx);
                  },
                ),
                _OptionTile(
                  label: configService.isDistraction(app.packageName)
                      ? 'Distraction App (on)'
                      : 'Mark as Distraction App',
                  color: textColor,
                  onTap: () async {
                    await configService.toggleDistraction(app.packageName);
                    Navigator.pop(ctx);
                  },
                ),
                _OptionTile(
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
                  _OptionTile(
                    label: 'Uninstall',
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(ctx);
                      if (Get.isRegistered<NativeBridge>()) {
                        Get.find<NativeBridge>().uninstallApp(app.packageName);
                      }
                    },
                  ),
                _OptionTile(
                  label: 'Hide',
                  color: textColor,
                  onTap: () async {
                    await configService.setHidden(app.packageName, true);
                    if (isFavorite) {
                      await favoritesController
                          .removeFavorite(app.packageName);
                    }
                    appsController.refreshVisibility();
                    favoritesController.rebuildFavorites();
                    Navigator.pop(ctx);
                  },
                ),
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
                  'Mindful Delay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                MinimalText(
                  displayName,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  color: secondaryColor.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 8),

                // Disable option
                if (isEnabled)
                  _OptionTile(
                    label: 'Turn off',
                    color: textColor,
                    onTap: () async {
                      await delayController.disable(app.packageName);
                      Navigator.pop(ctx);
                    },
                  ),

                // Duration options
                ...MindfulDelayConfig.availableDurations.map((seconds) {
                  final label = MindfulDelayConfig.formatDuration(seconds);
                  final selected = isEnabled && currentDuration == seconds;
                  return _OptionTile(
                    label: selected ? '✓  $label' : label,
                    color: textColor,
                    onTap: () async {
                      await delayController.setDuration(
                          app.packageName, seconds);
                      Navigator.pop(ctx);
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



  void _showClockMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final focusController = Get.find<FocusModeController>();

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
                  'Quick actions',
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
                _OptionTile(
                  label: 'Clock',
                  color: textColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (Get.isRegistered<NativeBridge>()) {
                      Get.find<NativeBridge>().openClock();
                    }
                  },
                ),
                _OptionTile(
                  label: 'Calendar',
                  color: textColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (Get.isRegistered<NativeBridge>()) {
                      Get.find<NativeBridge>().openCalendar();
                    }
                  },
                ),
                _OptionTile(
                  label: 'Screen Time',
                  color: textColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(AppRoutes.screenTime);
                  },
                ),
                _OptionTile(
                  label: 'Settings',
                  color: textColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(AppRoutes.settings);
                  },
                ),
                Obx(() {
                  final active = focusController.isActive.value;
                  return _OptionTile(
                    label: active
                        ? 'Stop Focus Mode (${focusController.remainingText.value})'
                        : 'Start Focus Mode',
                    color: textColor,
                    onTap: () {
                      Navigator.pop(ctx);
                      if (active) {
                        focusController.stop();
                      } else {
                        _showStartFocusMode(context);
                      }
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

  void _showStartFocusMode(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final focusController = Get.find<FocusModeController>();

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
                  'Start Focus Mode',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                MinimalText(
                  'Apps in your block list will be locked',
                  style: TextStyle(fontSize: 13, color: secondaryColor),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  color: secondaryColor.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 8),
                ...FocusModeConfig.availableDurationsMinutes.map((minutes) {
                  final label = minutes < 60
                      ? '$minutes min'
                      : (minutes == 60
                          ? '1 hour'
                          : '${minutes ~/ 60} hours');
                  return _OptionTile(
                    label: label,
                    color: textColor,
                    onTap: () async {
                      await focusController.start(minutes);
                      Navigator.pop(ctx);
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
                  'Schedule Block',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                MinimalText(
                  displayName,
                  style: TextStyle(fontSize: 14, color: secondaryColor),
                ),
                if (isEnabled) ...[
                  const SizedBox(height: 8),
                  MinimalText(
                    '${config.startFormatted} → ${config.endFormatted}',
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  color: secondaryColor.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 8),
                if (isEnabled)
                  _OptionTile(
                    label: 'Turn off',
                    color: textColor,
                    onTap: () async {
                      await scheduleController.disable(app.packageName);
                      Navigator.pop(ctx);
                    },
                  ),
                ...ScheduleConfig.presets.map((preset) {
                  final start = preset['start']!;
                  final end = preset['end']!;
                  final label = ScheduleConfig.presetLabel(start, end);
                  final selected = isEnabled &&
                      config.startMinutes == start &&
                      config.endMinutes == end;
                  return _OptionTile(
                    label: selected ? '✓  $label' : label,
                    color: textColor,
                    onTap: () async {
                      await scheduleController.setSchedule(
                        app.packageName,
                        startMinutes: start,
                        endMinutes: end,
                      );
                      Navigator.pop(ctx);
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
                  'Daily Limit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                MinimalText(
                  displayName,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  color: secondaryColor.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 8),
                if (isEnabled)
                  _OptionTile(
                    label: 'Turn off',
                    color: textColor,
                    onTap: () async {
                      await limitController.disable(app.packageName);
                      Navigator.pop(ctx);
                    },
                  ),
                ...DailyLimitConfig.availableLimits.map((minutes) {
                  final label = DailyLimitConfig.formatMinutes(minutes);
                  final selected = isEnabled && currentLimit == minutes;
                  return _OptionTile(
                    label: selected ? '✓  $label' : label,
                    color: textColor,
                    onTap: () async {
                      await limitController.setLimit(app.packageName, minutes);
                      Navigator.pop(ctx);
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

  void _showRenameDialog(
    BuildContext context,
    AppInfo app,
    String currentDisplayName,
    AppConfigService configService,
    AppsController appsController,
  ) {
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
              isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              Get.find<FavoritesController>().rebuildFavorites();
              Navigator.pop(ctx);
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
                Get.find<FavoritesController>().rebuildFavorites();
                Navigator.pop(ctx);
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
}

class _AppTile extends StatelessWidget {
  final String name;
  final bool isFavorite;
  final bool isRecentInstall;
  final Color textColor;
  final Color secondaryColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AppTile({
    required this.name,
    required this.isFavorite,
    this.isRecentInstall = false,
    required this.textColor,
    required this.secondaryColor,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : null;
    final isBold = settings?.boldFont.value ?? false;
    final badge = isRecentInstall ? ' ✦' : '';

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: MinimalText(
                '$name$badge',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                  color: textColor,
                  letterSpacing: 0.15,
                ),
              ),
            ),
            if (isFavorite)
              MinimalText(
                '★',
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryColor.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
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
