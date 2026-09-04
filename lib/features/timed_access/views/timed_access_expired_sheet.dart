import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../focus_mode/controllers/focus_mode_controller.dart';
import '../../screen_time/services/usage_stats_service.dart';

/// Floating expiration dialog that matches the requested design:
/// - [ Extend ] [ TAKE ME OUT OF HERE ]
/// - [ Block <AppName> ]
/// - Time remaining: 0 min
/// - X h Y min spent today / X h Y min last 7 days
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
  bool _showExtensionOptions = false;
  bool _isCustomSelected = false;
  final TextEditingController _customController = TextEditingController();
  String? _errorMessage;

  String _todaySpent = '1 h 56 min';
  String _weekSpent = '15 h 10 min';

  @override
  void initState() {
    super.initState();
    _loadUsageStats();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _loadUsageStats() async {
    try {
      if (Get.isRegistered<UsageStatsService>()) {
        final usage = await Get.find<UsageStatsService>().getAppUsage(widget.packageName);
        if (mounted && (usage.todayMs > 0 || usage.weekMs > 0)) {
          setState(() {
            _todaySpent = _formatDuration(usage.todayMs);
            _weekSpent = _formatDuration(usage.weekMs);
          });
        }
      }
    } catch (_) {}
  }

  String _formatDuration(int ms) {
    final totalMinutes = ms ~/ 60000;
    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return mins > 0 ? '$hours h $mins min' : '$hours h';
  }

  void _submitCustom() {
    final text = _customController.text.trim();
    final value = int.tryParse(text);

    if (value == null || value < 1 || value > 60) {
      setState(() {
        _errorMessage = 'Duration must be 1 to 60 minutes.';
      });
      return;
    }

    setState(() => _errorMessage = null);
    widget.onExtendDuration(value);
  }

  void _blockApp() {
    HapticFeedback.mediumImpact();
    if (Get.isRegistered<FocusModeController>()) {
      Get.find<FocusModeController>().toggleBlockedApp(widget.packageName);
    }
    Get.rawSnackbar(
      message: '${widget.appName} blocked',
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF222222),
      borderRadius: 8,
      margin: const EdgeInsets.all(16),
    );
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF141414), // AMOLED deep black
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Row 1: Extend & TAKE ME OUT OF HERE ──────────────────
          Row(
            children: [
              // [ Extend ] Button
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _showExtensionOptions = !_showExtensionOptions;
                    _isCustomSelected = false;
                    _errorMessage = null;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _showExtensionOptions ? Colors.white24 : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Text(
                    'Extend',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // [ TAKE ME OUT OF HERE ] Button
              Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onDone();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'TAKE ME OUT OF HERE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Row 2: Block <AppName> ────────────────────────────────
          InkWell(
            onTap: _blockApp,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                'Block ${widget.appName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // ── Extension Duration Choices (when Extend clicked) ──────
          if (_showExtensionOptions) ...[
            const SizedBox(height: 16),
            if (!_isCustomSelected) ...[
              Row(
                children: [
                  _DurationPill(
                    label: '5m',
                    onTap: () => widget.onExtendDuration(5),
                  ),
                  const SizedBox(width: 8),
                  _DurationPill(
                    label: '10m',
                    onTap: () => widget.onExtendDuration(10),
                  ),
                  const SizedBox(width: 8),
                  _DurationPill(
                    label: '15m',
                    onTap: () => widget.onExtendDuration(15),
                  ),
                  const SizedBox(width: 8),
                  _DurationPill(
                    label: 'Custom',
                    onTap: () {
                      setState(() {
                        _isCustomSelected = true;
                        _errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Minutes (1-60)',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: const Color(0xFF222222),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                      ),
                      onSubmitted: (_) => _submitCustom(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _submitCustom,
                    child: const Text('Start', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 4),
                Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
              ],
            ],
          ],

          const SizedBox(height: 24),

          // ── Row 3: Time Remaining & Usage Stats ───────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Time remaining 0 min
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Time remaining',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '0 min',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              // Right: X h Y min spent today / last 7 days
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$_todaySpent ',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const TextSpan(
                          text: 'spent today',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$_weekSpent ',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const TextSpan(
                          text: 'last 7 days',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DurationPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DurationPill({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white38),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
