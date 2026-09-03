import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';

/// Minimalist bottom sheet displayed when a timed distraction session expires.
class TimedAccessExpiredSheet extends StatefulWidget {
  final String appName;
  final String packageName;
  final ValueChanged<int> onExtendDuration;
  final VoidCallback onDone;

  const TimedAccessExpiredSheet({
    super.key,
    required this.appName,
    required this.packageName,
    required this.onExtendDuration,
    required this.onDone,
  });

  @override
  State<TimedAccessExpiredSheet> createState() => _TimedAccessExpiredSheetState();
}

class _TimedAccessExpiredSheetState extends State<TimedAccessExpiredSheet> {
  bool _isCustomSelected = false;
  final TextEditingController _customController = TextEditingController();
  String? _errorMessage;

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
    widget.onExtendDuration(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(28, 24, 28, 28 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MinimalText(
              'Your time is up.',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            MinimalText(
              'Session ended for ${widget.appName}',
              style: TextStyle(
                fontSize: 14,
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            MinimalText(
              'Need more time?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: secondaryColor.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 8),

            if (!_isCustomSelected) ...[
              _OptionTile(
                label: '5 minutes',
                color: textColor,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onExtendDuration(5);
                },
              ),
              _OptionTile(
                label: '10 minutes',
                color: textColor,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onExtendDuration(10);
                },
              ),
              _OptionTile(
                label: '15 minutes',
                color: textColor,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onExtendDuration(15);
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
                        hintText: 'e.g. 15',
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
                onTap: widget.onDone,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: MinimalText(
                    'Cancel / Done',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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
