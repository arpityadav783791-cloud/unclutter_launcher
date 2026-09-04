import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/native_bridge.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
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
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _appsScrollController = ScrollController();
  final RxString _searchQuery = ''.obs;
  int _currentPage = 0;
  double _pullDownDistance = 0.0;
  DateTime? _lastSwipeDownTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDefaultLauncherAndSetBlackWallpaper();
    if (Get.isRegistered<NativeBridge>()) {
      Get.find<NativeBridge>().onHomePressed = _returnToHomeScreen;
    }
  }

  void _returnToHomeScreen() {
    if (!mounted) return;
    if (_pageController.hasClients && _currentPage != 0) {
      _searchFocusNode.unfocus();
      _searchController.clear();
      _searchQuery.value = '';
      if (Get.isRegistered<AppSearchController>()) {
        Get.find<AppSearchController>().clear();
      }
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else if (_appsScrollController.hasClients && _appsScrollController.offset > 0) {
      _appsScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Get.isRegistered<NativeBridge>()) {
      final bridge = Get.find<NativeBridge>();
      if (bridge.onHomePressed == _returnToHomeScreen) {
        bridge.onHomePressed = null;
      }
    }
    _pageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _appsScrollController.dispose();
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
    const backgroundColor = AppColors.darkBackground;
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
                final settings = Get.find<SettingsController>();
                if (index == 1) {
                  if (settings.autoShowKeyboard.value) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _searchFocusNode.requestFocus();
                      }
                    });
                  }
                } else {
                  _searchFocusNode.unfocus();
                  _searchController.clear();
                  _searchQuery.value = '';
                  searchController.clear();
                }
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
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.horizontalPadding(context),
          vertical: AppTheme.verticalPadding(context),
        ),
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
                    borderRadius: AppRadius.borderSm,
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
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          timedAccess.cancelSession();
                        },
                        child: MinimalText(
                          'End',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 16),

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
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.horizontalPadding(context),
        vertical: AppTheme.verticalPadding(context),
      ),
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
                  focusNode: _searchFocusNode,
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
                    searchController.onQueryChanged(val);
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
                            context: context,
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
                          context: context,
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
                    searchController.clear();
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

              final settings = Get.find<SettingsController>();
              final isBold = settings.boldFont.value;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _appsScrollController,
                      physics: const BouncingScrollPhysics(),
                      // ignore: deprecated_member_use
                      cacheExtent: 350.0,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final app = filtered[index];
                        final isFav = favPackages.contains(app.packageName);
                        final name = appsController.displayName(app);

                        return _AppTile(
                          key: ValueKey('${app.packageName}_${app.userSerial}'),
                          name: name,
                          isFavorite: isFav,
                          isRecentInstall: app.isRecentInstall,
                          isWorkProfile: app.isWorkProfile,
                          isBold: isBold,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            productivity.handleAppLaunch(
                              app.packageName,
                              userSerial: app.userSerial,
                              activityName: app.activityName,
                              context: context,
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
                    ),
                  ),
                  if (query.trim().isEmpty && filtered.isNotEmpty)
                    _AlphabetScroller(
                      secondaryColor: secondaryColor,
                      onLetterSelected: (letter) {
                        final idx = filtered.indexWhere((app) =>
                            appsController.displayName(app).toUpperCase().startsWith(letter));
                        if (idx != -1 && _appsScrollController.hasClients) {
                          final target = (idx * 48.0).clamp(
                            0.0,
                            _appsScrollController.position.maxScrollExtent,
                          );
                          _appsScrollController.jumpTo(target);
                          HapticFeedback.selectionClick();
                        }
                      },
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _AlphabetScroller extends StatelessWidget {
  final Color secondaryColor;
  final ValueChanged<String> onLetterSelected;

  static const _letters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  const _AlphabetScroller({
    required this.secondaryColor,
    required this.onLetterSelected,
  });

  void _handleTouch(Offset localPosition, double height) {
    final itemHeight = height / _letters.length;
    final index = (localPosition.dy / itemHeight).floor().clamp(0, _letters.length - 1);
    onLetterSelected(_letters[index]);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (details) =>
              _handleTouch(details.localPosition, constraints.maxHeight),
          onVerticalDragDown: (details) =>
              _handleTouch(details.localPosition, constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _letters.map((letter) {
                return MinimalText(
                  letter,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: secondaryColor.withValues(alpha: 0.5),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _AppTile extends StatelessWidget {
  final String name;
  final bool isFavorite;
  final bool isRecentInstall;
  final bool isWorkProfile;
  final bool isBold;
  final Color textColor;
  final Color secondaryColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AppTile({
    super.key,
    required this.name,
    required this.isFavorite,
    this.isRecentInstall = false,
    this.isWorkProfile = false,
    this.isBold = false,
    required this.textColor,
    required this.secondaryColor,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final workBadge = isWorkProfile ? ' 💼' : '';
    final recentBadge = isRecentInstall ? ' ✦' : '';
    final badge = '$workBadge$recentBadge';

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: AppRadius.borderXs,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: MinimalText(
                '$name$badge',
                style: (isBold ? AppTypography.appTitleBold : AppTypography.appTitle).copyWith(
                  color: textColor,
                ),
              ),
            ),
            if (isFavorite)
              MinimalText(
                '★',
                style: AppTypography.favoriteStar.copyWith(
                  color: secondaryColor.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
