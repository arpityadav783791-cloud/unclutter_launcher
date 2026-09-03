import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/minimal_text.dart';
import '../controllers/protected_mode_controller.dart';

/// Minimalist Settings view for Protected Mode.
class ProtectedModeView extends StatelessWidget {
  const ProtectedModeView({super.key});

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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: MinimalText(
                    '← Back',
                    style: TextStyle(fontSize: 15, color: secondaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              MinimalText(
                'Protected Mode',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 1,
                color: secondaryColor.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Obx(() {
                  final state = controller.state.value;

                  if (controller.isLoading.value) {
                    return Center(
                      child: MinimalText(
                        'Checking protection status…',
                        style: TextStyle(fontSize: 15, color: secondaryColor),
                      ),
                    );
                  }

                  if (state.enabled) {
                    // ── Active State ──────────────────────────────
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MinimalText(
                          'Your Digital Detox launcher is protected.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: textColor,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _StatusRow(
                          label: 'Device Owner',
                          status: state.deviceOwnerActive ? 'Active' : 'Inactive',
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                        ),
                        const SizedBox(height: 16),
                        _StatusRow(
                          label: 'Default Launcher',
                          status: state.defaultLauncherActive ? 'Active' : 'Not Set',
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                        ),
                        if (!state.defaultLauncherActive) ...[
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => controller.requestDefaultLauncher(),
                            child: MinimalText(
                              'Set as Default Launcher →',
                              style: TextStyle(
                                fontSize: 15,
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161616),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF262626)),
                          ),
                          child: MinimalText(
                            'Uninstall and disable protection are enforced at the Android OS management level.\nUse the designated emergency recovery trigger to unlock.',
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // ── Inactive State ────────────────────────────
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MinimalText(
                        'Keep your Digital Detox launcher protected from accidental removal.',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: textColor,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!state.deviceOwnerActive) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161616),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF262626)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MinimalText(
                                'Device Owner: Inactive',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              MinimalText(
                                'Android requires provisioning this app as Device Owner to enforce uninstallation restrictions. Provision via ADB:\n\nadb shell dpm set-device-owner com.minimal.launcher/.ProtectedDeviceAdminReceiver',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryColor,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          controller.enableProtection();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222222),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: MinimalText(
                              'Enable Protection',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (controller.statusMessage.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        MinimalText(
                          controller.statusMessage.value,
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ],
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

class _StatusRow extends StatelessWidget {
  final String label;
  final String status;
  final Color textColor;
  final Color secondaryColor;

  const _StatusRow({
    required this.label,
    required this.status,
    required this.textColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MinimalText(
            label,
            style: TextStyle(fontSize: 16, color: textColor),
          ),
        ),
        MinimalText(
          status,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: status == 'Active' ? textColor : secondaryColor,
          ),
        ),
      ],
    );
  }
}
