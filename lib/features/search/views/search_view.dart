import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';
import '../../apps/controllers/apps_controller.dart';
import '../../productivity/controllers/productivity_controller.dart';
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
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
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

    return Scaffold(
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
                        fontWeight: FontWeight.w400,
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
                      onChanged: searchController.onQueryChanged,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) {
                        if (searchController.results.isNotEmpty) {
                          productivity.handleAppLaunch(
                            searchController.results.first.packageName,
                          );
                        }
                      },
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
                  final results = searchController.results;

                  if (query.isEmpty) {
                    return Center(
                      child: MinimalText(
                        'Type to search',
                        style: TextStyle(
                          color: secondaryColor.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  if (results.isEmpty) {
                    return Center(
                      child: MinimalText(
                        'No apps found',
                        style: TextStyle(
                          color: secondaryColor.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final app = results[index];
                      final name = appsController.displayName(app);
                      return InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          productivity.handleAppLaunch(app.packageName);
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: MinimalText(
                            name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
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
