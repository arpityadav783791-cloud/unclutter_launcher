import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';
import '../controllers/protected_mode_controller.dart';

/// Dedicated recovery confirmation screen triggered via the secret dialer code.
class ProtectedModeRecoveryView extends StatefulWidget {
  const ProtectedModeRecoveryView({super.key});

  @override
  State<ProtectedModeRecoveryView> createState() =>
      _ProtectedModeRecoveryViewState();
}

class _ProtectedModeRecoveryViewState extends State<ProtectedModeRecoveryView> {
  bool _protectionDisabled = false;

  void _confirmAndDisable(BuildContext context, ProtectedModeController controller) {
    const textColor = AppColors.darkText;
    const secondaryColor = AppColors.darkSecondary;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161616),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: MinimalText(
            'Disable Protection?',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          content: MinimalText(
            'This will remove Android device-management uninstall restrictions from Minimalist Launcher.',
            style: TextStyle(
              fontSize: 14,
              color: secondaryColor,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: MinimalText(
                'Cancel',
                style: TextStyle(color: secondaryColor, fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                HapticFeedback.mediumImpact();
                final success = await controller.disableProtection();
                if (success) {
                  setState(() {
                    _protectionDisabled = true;
                  });
                }
              },
              child: MinimalText(
                'Disable Protection',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Colors.black;
    const textColor = AppColors.darkText;
    const secondaryColor = AppColors.darkSecondary;

    final controller = Get.find<ProtectedModeController>();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MinimalText(
                'Protected Mode Recovery',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 1,
                color: secondaryColor.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 36),

              if (!_protectionDisabled) ...[
                MinimalText(
                  'Protection is currently enabled.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                MinimalText(
                  'Disabling protection will remove Device-Owner uninstall and modification restrictions.',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryColor,
                    height: 1.4,
                  ),
                ),
                const Spacer(),

                GestureDetector(
                  onTap: () => _confirmAndDisable(context, controller),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: MinimalText(
                        'Disable Protection',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: MinimalText(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                MinimalText(
                  'Protection disabled.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                MinimalText(
                  'You can now manage or uninstall Minimalist normally.',
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryColor,
                    height: 1.4,
                  ),
                ),
                const Spacer(),

                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: MinimalText(
                        'Done',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
