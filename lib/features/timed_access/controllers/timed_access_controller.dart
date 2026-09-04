import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/native_bridge.dart';
import '../../apps/controllers/apps_controller.dart';
import '../../apps/models/app_info.dart';
import '../../apps/services/native_app_service.dart';
import '../../focus_mode/controllers/focus_mode_controller.dart';
import '../models/timed_app_session.dart';
import '../services/timed_access_service.dart';
import '../views/timed_access_expired_sheet.dart';
import '../views/timed_access_prompt_sheet.dart';

/// Controller orchestrating Timed Distraction App Access, UI sheets,
/// countdown timers, lifecycle updates, and native enforcement.
class TimedAccessController extends GetxController with WidgetsBindingObserver {
  final TimedAccessService _service = Get.find<TimedAccessService>();
  final NativeBridge _nativeBridge = Get.find<NativeBridge>();
  final NativeAppService _nativeAppService = Get.find<NativeAppService>();

  final Rx<TimedAppSession?> currentSession = Rx<TimedAppSession?>(null);
  final RxInt remainingSeconds = 0.obs;
  final RxBool isExpired = false.obs;

  TimedAppSession? _lastExpiredSession;
  Timer? _countdownTicker;
  bool _isExpiredSheetShowing = false;
  String? _pendingExpiredPackage;
  String? _pendingExpiredAppName;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // Wire up native callback
    _nativeBridge.onSessionExpired = (packageName) {
      handleSessionExpired(expiredPackage: packageName);
    };

    // Wire up native callback when user taps [Extend] in the overlay
    _nativeBridge.onSessionExtended = (packageName, durationMinutes) async {
      final appName = currentSession.value?.appName ?? _lastExpiredSession?.appName ?? packageName;
      final session = await _service.startSession(
        packageName: packageName,
        appName: appName,
        durationMinutes: durationMinutes,
      );
      currentSession.value = session;
      remainingSeconds.value = session.remainingSeconds;
      isExpired.value = false;
      _lastExpiredSession = null;
      _startCountdownTicker();
    };

    // Wire up native callback when user taps [Block App] in the overlay
    _nativeBridge.onBlockAppRequested = (packageName) async {
      if (Get.isRegistered<FocusModeController>()) {
        final focusCtrl = Get.find<FocusModeController>();
        await focusCtrl.toggleBlockedApp(packageName);
      }
    };

    // Wire up native callback for notification interception of distraction apps
    _nativeBridge.onDistractionIntercepted = (packageName) {
      if (hasActiveSessionFor(packageName)) return;
      final appsCtrl = Get.isRegistered<AppsController>() ? Get.find<AppsController>() : null;
      final app = appsCtrl?.findByPackage(packageName);
      if (app != null) {
        final context = AppRouter.rootNavigatorKey.currentContext ?? Get.context;
        if (context != null && context.mounted) {
          handleDistractionLaunch(context: context, app: app);
        }
      }
    };

    // Restore any active session
    _restoreSession();
  }

  void _restoreSession() {
    final session = _service.activeSession;
    if (session != null) {
      if (session.isExpired) {
        _handleStoredExpiredSession(session);
      } else {
        currentSession.value = session;
        remainingSeconds.value = session.remainingSeconds;
        isExpired.value = false;
        _startCountdownTicker();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      recalculateRemainingTime();
      if (_pendingExpiredPackage != null) {
        final pkg = _pendingExpiredPackage!;
        final name = _pendingExpiredAppName ?? pkg;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showExpiredSheet(packageName: pkg, appName: name);
        });
      }
    }
  }

  /// Recalculates remaining session time from stored timestamp on resume/lifecycle change.
  void recalculateRemainingTime() {
    final session = currentSession.value ?? _service.activeSession;
    if (session == null) return;

    if (session.isExpired) {
      handleSessionExpired(expiredPackage: session.packageName);
    } else {
      currentSession.value = session;
      remainingSeconds.value = session.remainingSeconds;
      isExpired.value = false;
      _startCountdownTicker();
    }
  }

  void _startCountdownTicker() {
    _countdownTicker?.cancel();
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = currentSession.value;
      if (session == null) {
        _countdownTicker?.cancel();
        return;
      }

      final secs = session.remainingSeconds;
      remainingSeconds.value = secs;

      if (secs <= 0) {
        _countdownTicker?.cancel();
        remainingSeconds.value = 0;
        isExpired.value = true;
      }
    });
  }

  /// Returns true if an active, unexpired session is already running for this package.
  bool hasActiveSessionFor(String packageName) {
    if (currentSession.value != null &&
        currentSession.value!.packageName == packageName &&
        !currentSession.value!.isExpired) {
      return true;
    }
    return _service.isSessionActiveFor(packageName);
  }

  /// Handles app launch attempt for a distraction app.
  /// If session is already active: returns true to launch immediately.
  /// If no session or expired: shows prompt sheet and returns false.
  Future<bool> handleDistractionLaunch({
    required BuildContext context,
    required AppInfo app,
  }) async {
    // Edge case: active session already exists and is not expired
    if (hasActiveSessionFor(app.packageName)) {
      return true;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appsController = Get.isRegistered<AppsController>()
        ? Get.find<AppsController>()
        : null;
    final displayName =
        appsController != null ? appsController.displayName(app) : app.name;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return TimedAccessPromptSheet(
          appName: displayName,
          packageName: app.packageName,
          onConfirmDuration: (minutes) async {
            Navigator.pop(sheetContext);
            await startSessionAndLaunch(
              app: app,
              displayName: displayName,
              durationMinutes: minutes,
            );
          },
          onCancel: () {
            Navigator.pop(sheetContext);
          },
        );
      },
    );

    return false;
  }

  /// Launches the target app first, and starts session and native timer only on success.
  Future<bool> startSessionAndLaunch({
    required AppInfo app,
    required String displayName,
    required int durationMinutes,
  }) async {
    // Validate duration: 1 to 60 minutes
    final sanitizedMinutes = durationMinutes.clamp(1, 60);

    // Launch target app
    final success = await _nativeAppService.launchApp(app.packageName);
    if (!success) {
      Get.rawSnackbar(
        message: 'Could not open $displayName',
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF222222),
        borderRadius: 8,
        margin: const EdgeInsets.all(16),
      );
      return false;
    }

    // Start session
    final session = await _service.startSession(
      packageName: app.packageName,
      appName: displayName,
      durationMinutes: sanitizedMinutes,
    );

    currentSession.value = session;
    remainingSeconds.value = session.remainingSeconds;
    isExpired.value = false;
    _lastExpiredSession = null;

    // Start native monitoring timer with ongoing live countdown notification and usage overlay
    await _nativeBridge.startTimedSession(
      packageName: app.packageName,
      appName: displayName,
      durationSeconds: sanitizedMinutes * 60,
      startedAtMillis: session.startedAt.millisecondsSinceEpoch,
      expiresAtMillis: session.expiresAt.millisecondsSinceEpoch,
    );

    _startCountdownTicker();
    return true;
  }

  /// Triggered when the timed session expires (from native bridge, ticker, or resume).
  void handleSessionExpired({String? expiredPackage, bool showSheet = false}) {
    _countdownTicker?.cancel();

    final session = currentSession.value ??
        _service.activeSession ??
        _lastExpiredSession;

    final pkg = expiredPackage ?? session?.packageName ?? '';
    final name = session?.appName ?? pkg;

    _lastExpiredSession = session ??
        TimedAppSession.create(
          packageName: pkg,
          appName: name,
          durationMinutes: 0,
        );

    currentSession.value = null;
    remainingSeconds.value = 0;
    isExpired.value = true;

    // Clear active session in storage
    _service.clearSession();

    // Cancel native timer & return to launcher
    _nativeBridge.cancelTimedSession();
    _nativeBridge.returnToLauncher();

    // Show "Your time is up. Need more time?" sheet only if requested
    if (showSheet) {
      _showExpiredSheet(packageName: pkg, appName: name);
    }
  }

  void _handleStoredExpiredSession(TimedAppSession session) {
    _lastExpiredSession = session;
    _service.clearSession();
    currentSession.value = null;
    remainingSeconds.value = 0;
    isExpired.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showExpiredSheet(packageName: session.packageName, appName: session.appName);
    });
  }

  void _showExpiredSheet({
    required String packageName,
    required String appName,
  }) {
    if (_isExpiredSheetShowing) return;

    final context = AppRouter.rootNavigatorKey.currentContext ?? Get.context;
    if (context == null || !context.mounted) {
      _pendingExpiredPackage = packageName;
      _pendingExpiredAppName = appName;
      return;
    }

    _isExpiredSheetShowing = true;
    _pendingExpiredPackage = null;
    _pendingExpiredAppName = null;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: TimedAccessExpiredSheet(
            appName: appName,
            packageName: packageName,
            onExtendDuration: (extraMinutes) async {
              Navigator.pop(dialogContext);
              _isExpiredSheetShowing = false;
              await _extendSessionAndLaunch(
                packageName: packageName,
                appName: appName,
                durationMinutes: extraMinutes,
              );
            },
            onDone: () {
              Navigator.pop(dialogContext);
              _isExpiredSheetShowing = false;
              dismissExpiredSession();
            },
          ),
        );
      },
    ).then((_) {
      _isExpiredSheetShowing = false;
    });
  }

  Future<void> _extendSessionAndLaunch({
    required String packageName,
    required String appName,
    required int durationMinutes,
  }) async {
    final sanitizedMinutes = durationMinutes.clamp(1, 60);

    final app = AppInfo(packageName: packageName, name: appName);
    await startSessionAndLaunch(
      app: app,
      displayName: appName,
      durationMinutes: sanitizedMinutes,
    );
  }

  /// Cancels an active session and stops native & Flutter timers.
  Future<void> cancelSession() async {
    _countdownTicker?.cancel();
    currentSession.value = null;
    remainingSeconds.value = 0;
    isExpired.value = false;
    _lastExpiredSession = null;

    await _service.clearSession();
    await _nativeBridge.cancelTimedSession();
  }

  /// Dismisses the expired session state and returns to normal launcher state.
  void dismissExpiredSession() {
    isExpired.value = false;
    _lastExpiredSession = null;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTicker?.cancel();
    super.onClose();
  }
}
