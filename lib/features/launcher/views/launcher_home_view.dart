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
import '../../favorites/controllers/favorites_controller.dart';
import '../../productivity/controllers/productivity_controller.dart';
import '../../search/controllers/search_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../timed_access/controllers/timed_access_controller.dart';
import '../controllers/launcher_controller.dart';
import '../services/home_gesture_service.dart';
import '../widgets/app_options_bottom_sheet.dart';
import '../widgets/home_clock_menu.dart';
import '../widgets/home_clock_widget.dart';
import '../widgets/home_favorites_widget.dart';

class LauncherHomeView extends StatefulWidget {
  const LauncherHomeView({super.key});

  @override
  State<LauncherHomeView> createState() => _LauncherHomeViewState();
}

class _LauncherHomeViewState extends State<LauncherHomeView>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  int _currentPage = 0;
  double _pullDownDistance = 0.0;
  DateTime? _lastSwipeDownTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDefaultLauncherAndSetBlackWallpaper();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDefaultLauncherAndSetBlackWallpaper();
    }
  }

  Future<void> _checkDefaultLauncherAndSetBlackWallpaper() async {
    if (Get.isRegistered<PermissionService>()) {
      await Get.find<PermissionService>().isDefaultLauncher();
    }
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
    final searchController = Get.isRegistered<AppSearchController>()
        ? Get.find<AppSearchController>()
        : Get.put(AppSearchController(), permanent: true);

    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
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
                  searchController: searchController,
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
      onLongPress: () {
        HapticFeedback.mediumImpact();
        context.push(AppRoutes.settings);
      },
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
              onLongPress: () => showHomeClockMenu(context),
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
                  showAppOptionsBottomSheet(
                    context: ctx,
                    app: app,
                    displayName: name,
                    favoritesController: favoritesController,
                    productivity: productivity,
                    isFavorite: true,
                  );
                },
              ),
            ),

            // Bottom "Swipe up for all apps"
            GestureDetector(
              onTap: () {
                final isEink = Get.find<SettingsController>().isEinkActive;
                _pageController.animateToPage(
                  1,
                  duration: isEink
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
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
    required AppSearchController searchController,
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
                  final isEink = Get.find<SettingsController>().isEinkActive;
                  _pageController.animateToPage(
                    0,
                    duration: isEink
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
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
                    _searchQuery.value = val;
                    final settings = Get.find<SettingsController>();
                    if (settings.autoLaunchSingleMatch.value) {
                      final trimmed = val.trim();
                      if (trimmed.isNotEmpty &&
                          !val.startsWith(' ') &&
                          !val.startsWith('!')) {
                        final matches = searchController.filterApps(
                          appsController.apps,
                          trimmed,
                        );
                        if (matches.length == 1) {
                          HapticFeedback.lightImpact();
                          productivity.handleAppLaunch(
                            matches.first.packageName,
                            userSerial: matches.first.userSerial,
                            activityName: matches.first.activityName,
                          );
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
                      final matches = searchController.filterApps(
                        appsController.apps,
                        trimmed,
                      );
                      if (matches.isNotEmpty) {
                        productivity.handleAppLaunch(
                          matches.first.packageName,
                          userSerial: matches.first.userSerial,
                          activityName: matches.first.activityName,
                        );
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
          // Android 15+ Private Space Row
          Obx(() {
            if (!appsController.isPrivateSpaceAvailable.value ||
                _searchQuery.value.isNotEmpty) {
              return const SizedBox.shrink();
            }
            final isLocked = appsController.isPrivateSpaceLocked.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => appsController.togglePrivateSpace(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      MinimalText(
                        'Private space ${isLocked ? "🔒" : "🔓"}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const Spacer(),
                      MinimalText(
                        isLocked ? 'Tap to unlock' : 'Tap to lock',
                        style: TextStyle(fontSize: 12, color: secondaryColor),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Pinned Shortcuts Row
          Obx(() {
            final shortcuts = appsController.pinnedShortcuts;
            if (shortcuts.isEmpty) return const SizedBox.shrink();
            final q = _searchQuery.value.trim().toLowerCase();
            final matched = q.isEmpty
                ? shortcuts
                : shortcuts
                    .where((s) => s.label.toLowerCase().contains(q))
                    .toList();
            if (matched.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...matched.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: InkWell(
                        onTap: () => appsController.launchShortcut(s),
                        onLongPress: () => appsController.unpinShortcut(s),
                        child: Row(
                          children: [
                            Expanded(
                              child: MinimalText(
                                '${s.label} 📌',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: textColor,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 6),
              ],
            );
          }),

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

              final query = _searchQuery.value;
              final allVisible = appsController.apps;
              final favorites = favoritesController.favoriteApps;
              final favPackages = favorites.map((a) => a.packageName).toSet();

              final filtered = query.trim().isEmpty
                  ? allVisible
                  : searchController.filterApps(allVisible, query);

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
                    isWorkProfile: app.isWorkProfile,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      productivity.handleAppLaunch(
                        app.packageName,
                        userSerial: app.userSerial,
                        activityName: app.activityName,
                      );
                    },
                    onLongPress: () => showAppOptionsBottomSheet(
                      context: context,
                      app: app,
                      displayName: name,
                      favoritesController: favoritesController,
                      productivity: productivity,
                      isFavorite: isFav,
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
}

class _AppTile extends StatelessWidget {
  final String name;
  final bool isFavorite;
  final bool isRecentInstall;
  final bool isWorkProfile;
  final Color textColor;
  final Color secondaryColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AppTile({
    required this.name,
    required this.isFavorite,
    this.isRecentInstall = false,
    this.isWorkProfile = false,
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
    final workBadge = isWorkProfile ? ' 💼' : '';
    final recentBadge = isRecentInstall ? ' ✦' : '';
    final badge = '$workBadge$recentBadge';

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
