import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/native_bridge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';
import '../../apps/controllers/apps_controller.dart';
import '../../productivity/controllers/productivity_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/search_controller.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Get.isRegistered<SettingsController>()
          ? Get.find<SettingsController>()
          : null;
      if (settings?.autoShowKeyboard.value ?? true) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleAutoLaunch(String query, AppSearchController searchController,
      ProductivityController productivity, SettingsController settings) {
    if (!settings.autoLaunchSingleMatch.value) return;

    final trimmed = query.trim();
    if (trimmed.isEmpty || query.startsWith(' ') || query.startsWith('!')) {
      return;
    }

    if (searchController.results.length == 1) {
      final targetApp = searchController.results.first;
      HapticFeedback.lightImpact();
      productivity.handleAppLaunch(targetApp.packageName);
    }
  }

  void _handleSubmit(String query, AppSearchController searchController,
      ProductivityController productivity) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    if (query.startsWith('!')) {
      // DuckDuckGo Bang Search
      if (Get.isRegistered<NativeBridge>()) {
        Get.find<NativeBridge>().openWebSearch(
          'https://duckduckgo.com/?q=${Uri.encodeComponent(query)}',
        );
      }
      return;
    }

    if (searchController.results.isNotEmpty) {
      productivity.handleAppLaunch(
        searchController.results.first.packageName,
      );
    } else {
      // Web search fallback when no apps match
      if (Get.isRegistered<NativeBridge>()) {
        Get.find<NativeBridge>().openWebSearch(trimmed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    final searchController = Get.find<AppSearchController>();
    final productivity = Get.find<ProductivityController>();
    final appsController = Get.find<AppsController>();
    final settings = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: settings.boldFont.value
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: textColor,
                      ),
                      cursorColor: textColor,
                      cursorWidth: 1.5,
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          fontSize: 22,
                          color: secondaryColor.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: (val) {
                        searchController.onQueryChanged(val);
                        _handleAutoLaunch(
                          val,
                          searchController,
                          productivity,
                          settings,
                        );
                      },
                      textInputAction: TextInputAction.search,
                      onSubmitted: (val) => _handleSubmit(
                        val,
                        searchController,
                        productivity,
                      ),
                    ),
                  ),
                  Obx(() {
                    if (searchController.query.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return GestureDetector(
                      onTap: () {
                        _textController.clear();
                        searchController.clear();
                        _focusNode.requestFocus();
                      },
                      child: MinimalText(
                        'Clear',
                        style: TextStyle(
                          fontSize: 15,
                          color: secondaryColor,
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: secondaryColor.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  final query = searchController.query.value;
                  final displayList = query.isEmpty
                      ? appsController.apps
                      : searchController.results;

                  if (displayList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MinimalText(
                            'No apps found',
                            style: TextStyle(
                              color: secondaryColor.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
                          ),
                          if (query.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _handleSubmit(
                                query,
                                searchController,
                                productivity,
                              ),
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
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final app = displayList[index];
                      final name = appsController.displayName(app);
                      final badge = app.isRecentInstall ? ' ✦' : '';

                      return InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          productivity.handleAppLaunch(app.packageName);
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: MinimalText(
                            '$name$badge',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: settings.boldFont.value
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: textColor,
                              letterSpacing: 0.15,
                            ),
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
      ),
    );
  }
}
