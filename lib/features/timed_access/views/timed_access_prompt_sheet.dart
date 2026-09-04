import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/native_bridge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/minimal_text.dart';

/// Minimalist bottom sheet asking the user how long they wish to use a distraction app.
class TimedAccessPromptSheet extends StatefulWidget {
  final String appName;
  final String packageName;
  final ValueChanged<int> onConfirmDuration;
  final VoidCallback onCancel;

  const TimedAccessPromptSheet({
    super.key,
    required this.appName,
    required this.packageName,
    required this.onConfirmDuration,
    required this.onCancel,
  });

  @override
  State<TimedAccessPromptSheet> createState() => _TimedAccessPromptSheetState();
}

class _TimedAccessPromptSheetState extends State<TimedAccessPromptSheet> {
  bool _isCustomSelected = false;
  final TextEditingController _customController = TextEditingController();
  String? _errorMessage;
  bool _hasOverlayPermission = true;

  @override
  void initState() {
    super.initState();
    _checkOverlayPermission();
  }

  Future<void> _checkOverlayPermission() async {
    if (Get.isRegistered<NativeBridge>()) {
      final perm = await Get.find<NativeBridge>().hasOverlayPermission();
      if (mounted) {
        setState(() => _hasOverlayPermission = perm);
      }
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _submitCustom() {
    final text = _customController.text.trim();
    final value = int.tryParse(text);

    if (value == null || value < 1 || value > 60) {
      setState(() {
        _errorMessage = 'Please enter a duration between 1 and 60 minutes.';
      });
      return;
    }

    setState(() => _errorMessage = null);
    widget.onConfirmDuration(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final horizontalPadding = AppTheme.horizontalPadding(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 28 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MinimalText(
              'How long do you need?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            MinimalText(
              widget.appName,
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

            if (!_hasOverlayPermission) ...[
              GestureDetector(
                onTap: () async {
                  if (Get.isRegistered<NativeBridge>()) {
                    await Get.find<NativeBridge>().requestOverlayPermission();
                    await Future.delayed(const Duration(seconds: 1));
                    _checkOverlayPermission();
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Enable overlay to show timer over apps',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Enable',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],

            if (!_isCustomSelected) ...[
              _OptionTile(
                label: '5 min',
                color: textColor,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onConfirmDuration(5);
                },
              ),
              _OptionTile(
                label: '10 min',
                color: textColor,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onConfirmDuration(10);
                },
              ),
              _OptionTile(
                label: '15 min',
                color: textColor,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onConfirmDuration(15);
                },
              ),
              _OptionTile(
                label: 'Custom',
                color: secondaryColor,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isCustomSelected = true;
                    _errorMessage = null;
                  });
                },
              ),
            ] else ...[
              const SizedBox(height: 8),
              MinimalText(
                'Custom duration (1–60 min):',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      style: TextStyle(
                        fontSize: 20,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: textColor,
                      decoration: InputDecoration(
                        hintText: 'e.g. 25',
                        hintStyle: TextStyle(
                          color: secondaryColor.withValues(alpha: 0.5),
                        ),
                        suffixText: 'min',
                        suffixStyle: TextStyle(
                          color: secondaryColor,
                          fontSize: 16,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: secondaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: textColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _submitCustom(),
                      onChanged: (_) {
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _submitCustom,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E5E5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: MinimalText(
                        'Start',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                MinimalText(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.redAccent,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isCustomSelected = false;
                    _errorMessage = null;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: MinimalText(
                    '← Back to options',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryColor,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: widget.onCancel,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: MinimalText(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      color: secondaryColor,
                    ),
                  ),
                ),
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
      child: Container(
        width: double.infinity,
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
