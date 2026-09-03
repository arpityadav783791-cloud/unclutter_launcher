import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';
import '../../../core/routes/app_routes.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    final controller = Get.find<SettingsController>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: MinimalText(
                  '← Back',
                  style: TextStyle(fontSize: 15, color: secondaryColor),
                ),
              ),

              const SizedBox(height: 28),

              MinimalText(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 32),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // ── Appearance ───────────────────────────
                    _SectionLabel('APPEARANCE', secondaryColor),
                    const SizedBox(height: 12),

                    Obx(() => _ToggleRow(
                          label: 'Show clock',
                          value: controller.showClock.value,
                          textColor: textColor,
                          onTap: controller.toggleClock,
                        )),
                    Obx(() => _ToggleRow(
                          label: 'Show date',
                          value: controller.showDate.value,
                          textColor: textColor,
                          onTap: controller.toggleDate,
                        )),

                    const SizedBox(height: 8),
                    MinimalText(
                      'Theme',
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final mode = controller.themeMode.value;
                      return Column(
                        children: [
                          _SelectRow(
                            label: 'System',
                            selected: mode == 'system',
                            textColor: textColor,
                            onTap: () => controller.setThemeMode('system'),
                          ),
                          _SelectRow(
                            label: 'Light',
                            selected: mode == 'light',
                            textColor: textColor,
                            onTap: () => controller.setThemeMode('light'),
                          ),
                          _SelectRow(
                            label: 'Dark',
                            selected: mode == 'dark',
                            textColor: textColor,
                            onTap: () => controller.setThemeMode('dark'),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 8),
                    MinimalText(
                      'Text size',
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final scale = controller.textScale.value;
                      return Column(
                        children: [
                          _SelectRow(
                            label: 'Small',
                            selected: scale < 0.95,
                            textColor: textColor,
                            onTap: () => controller.setTextScale(0.9),
                          ),
                          _SelectRow(
                            label: 'Normal',
                            selected: scale >= 0.95 && scale <= 1.05,
                            textColor: textColor,
                            onTap: () => controller.setTextScale(1.0),
                          ),
                          _SelectRow(
                            label: 'Large',
                            selected: scale > 1.05,
                            textColor: textColor,
                            onTap: () => controller.setTextScale(1.15),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 28),
                    Container(
                      height: 1,
                      color: secondaryColor.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 28),

                    // ── Productivity ─────────────────────────
                    _SectionLabel('PRODUCTIVITY', secondaryColor),
                    const SizedBox(height: 12),

                    _LinkRow(
                      label: 'Screen Time',
                      textColor: textColor,
                      onTap: () => context.push(AppRoutes.screenTime),
                    ),
                    _LinkRow(
                      label: 'Focus Mode',
                      textColor: textColor,
                      subtitle: 'Long-press clock to start/stop',
                      secondaryColor: secondaryColor,
                    ),
                    _LinkRow(
                      label: 'Mindful Delay',
                      textColor: textColor,
                      subtitle: 'Long-press app → Mindful Delay',
                      secondaryColor: secondaryColor,
                    ),
                    _LinkRow(
                      label: 'Daily Limits',
                      textColor: textColor,
                      subtitle: 'Long-press app → Daily Limit',
                      secondaryColor: secondaryColor,
                    ),
                    _LinkRow(
                      label: 'Scheduled Blocking',
                      textColor: textColor,
                      subtitle: 'Long-press app → Schedule Block',
                      secondaryColor: secondaryColor,
                    ),
                    _LinkRow(
                      label: 'Timed Distraction Access',
                      textColor: textColor,
                      subtitle: 'Long-press app → Mark as Distraction App',
                      secondaryColor: secondaryColor,
                    ),

                    const SizedBox(height: 28),
                    Container(
                      height: 1,
                      color: secondaryColor.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 28),

                    // ── Apps ─────────────────────────────────
                    _SectionLabel('APPS', secondaryColor),
                    const SizedBox(height: 12),
                    _LinkRow(
                      label: 'Favorites',
                      textColor: textColor,
                      subtitle: 'Long-press app → Add to favorites',
                      secondaryColor: secondaryColor,
                    ),
                    _LinkRow(
                      label: 'Hidden apps',
                      textColor: textColor,
                      subtitle: 'Long-press app → Hide',
                      secondaryColor: secondaryColor,
                    ),
                    _LinkRow(
                      label: 'Rename apps',
                      textColor: textColor,
                      subtitle: 'Long-press app → Rename',
                      secondaryColor: secondaryColor,
                    ),

                    const SizedBox(height: 28),
                    Container(
                      height: 1,
                      color: secondaryColor.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 28),

                    // ── Gestures ─────────────────────────────
                    _SectionLabel('GESTURES', secondaryColor),
                    const SizedBox(height: 12),
                    _InfoRow('Tap app', 'Launch', textColor, secondaryColor),
                    _InfoRow('Long-press app', 'Options', textColor, secondaryColor),
                    _InfoRow('Swipe up', 'Search', textColor, secondaryColor),
                    _InfoRow('Long-press clock', 'Screen Time / Focus', textColor, secondaryColor),

                    // ── Protection ──────────────────────────
                    _SectionLabel('PROTECTION', secondaryColor),
                    const SizedBox(height: 12),
                    _LinkRow(
                      label: 'Protected Mode',
                      textColor: textColor,
                      subtitle: 'Device Owner uninstall protection',
                      secondaryColor: secondaryColor,
                      onTap: () => context.push(AppRoutes.protectedMode),
                    ),

                    const SizedBox(height: 28),
                    Container(
                      height: 1,
                      color: secondaryColor.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 28),

                    // ── About ────────────────────────────────
                    _SectionLabel('ABOUT', secondaryColor),
                    const SizedBox(height: 12),
                    MinimalText(
                      'Minimal Launcher',
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    MinimalText(
                      'Text-first. Distraction-free.\nBuilt for intentional phone use.',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return MinimalText(
      text,
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final Color textColor;
  final VoidCallback onTap;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: MinimalText(
                label,
                style: TextStyle(fontSize: 16, color: textColor),
              ),
            ),
            MinimalText(
              value ? 'On' : 'Off',
              style: TextStyle(fontSize: 15, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  final String label;
  final bool selected;
  final Color textColor;
  final VoidCallback onTap;

  const _SelectRow({
    required this.label,
    required this.selected,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: MinimalText(
          selected ? '✓  $label' : '    $label',
          style: TextStyle(fontSize: 16, color: textColor),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final Color textColor;
  final String? subtitle;
  final Color? secondaryColor;
  final VoidCallback? onTap;

  const _LinkRow({
    required this.label,
    required this.textColor,
    this.subtitle,
    this.secondaryColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MinimalText(
              label,
              style: TextStyle(fontSize: 16, color: textColor),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              MinimalText(
                subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryColor?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String left;
  final String right;
  final Color textColor;
  final Color secondaryColor;

  const _InfoRow(this.left, this.right, this.textColor, this.secondaryColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: MinimalText(
              left,
              style: TextStyle(fontSize: 15, color: textColor),
            ),
          ),
          MinimalText(
            right,
            style: TextStyle(fontSize: 14, color: secondaryColor),
          ),
        ],
      ),
    );
  }
}
