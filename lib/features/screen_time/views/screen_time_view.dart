import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';
import '../controllers/screen_time_controller.dart';

class ScreenTimeView extends StatelessWidget {
  const ScreenTimeView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    final controller = Get.find<ScreenTimeController>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: textColor,
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          onRefresh: () => controller.refresh(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: MinimalText(
                    '← Back',
                    style: TextStyle(fontSize: 15, color: secondaryColor),
                  ),
                ),

                const SizedBox(height: 32),

                MinimalText(
                  'Screen Time',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 28),

                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return Center(
                        child: MinimalText(
                          'Loading…',
                          style:
                              TextStyle(color: secondaryColor, fontSize: 16),
                        ),
                      );
                    }

                    if (!controller.hasPermission.value) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MinimalText(
                              'Usage access is required\nto calculate screen time.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: secondaryColor,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 28),
                            GestureDetector(
                              onTap: () => controller.requestPermission(),
                              child: MinimalText(
                                'Open Settings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        // ── TODAY ──────────────────────────────
                        MinimalText(
                          'TODAY',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 1.2,
                            color: secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 12),

                        MinimalText(
                          controller.totalTodayFormatted,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            color: textColor,
                            letterSpacing: -1.5,
                          ),
                        ),

                        if (controller.comparisonText.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          MinimalText(
                            controller.comparisonText,
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryColor,
                            ),
                          ),
                        ],

                        const SizedBox(height: 36),

                        Container(
                          height: 1,
                          color: secondaryColor.withValues(alpha: 0.12),
                        ),

                        const SizedBox(height: 28),

                        // ── MOST USED ──────────────────────────
                        MinimalText(
                          'MOST USED',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 1.2,
                            color: secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (controller.todayUsage.isEmpty)
                          MinimalText(
                            'No usage data yet',
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 15,
                            ),
                          )
                        else
                          ...controller.todayUsage.take(12).map((usage) {
                            final name =
                                controller.displayNameFor(usage.packageName);
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 11),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: MinimalText(
                                      name,
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  MinimalText(
                                    usage.formattedDuration,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                        const SizedBox(height: 40),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
