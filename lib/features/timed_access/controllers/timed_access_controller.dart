import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/services/native_bridge.dart';
import '../../apps/controllers/apps_controller.dart';
import '../../apps/models/app_info.dart';
import '../../distraction_apps/services/distraction_app_service.dart';
import '../data/repositories/timed_access_repository_impl.dart';
import '../domain/entities/timed_access_session.dart';
import '../domain/entities/timed_access_status.dart';
import '../domain/repositories/timed_access_repository.dart';
import '../services/app_launcher.dart';
import '../services/timed_access_native_service.dart';
import '../services/timed_access_native_service_impl.dart';
import '../widgets/timed_access_bottom_sheet.dart';
import '../widgets/timed_access_expiry_dialog.dart';

class TimedAccessController extends GetxController with WidgetsBindingObserver {
  final TimedAccessRepository _repository;
  final TimedAccessNativeService _nativeService;
  final AppLauncher _appLauncher;

  TimedAccessController({
    TimedAccessRepository? repository,
    TimedAccessNativeService? nativeService,
    AppLauncher? appLauncher,
  })  : _repository = repository ?? TimedAccessRepositoryImpl(),
        _nativeService = nativeService ?? TimedAccessNativeServiceImpl(),
        _appLauncher = appLauncher ?? DefaultAppLauncher();

  static const List<int> presetDurations = [5, 10, 15, 30];
  static const List<int> extensionPresets = [5, 10, 15, 30];
  static const int maxCustomMinutes = 120;

  final Rxn<TimedAccessSession> _session = Rxn<TimedAccessSession>();
  final Rxn<AppInfo> selectedApp = Rxn<AppInfo>();
  final RxInt selectedDurationMinutes = 5.obs;
  final RxInt selectedExtensionMinutes = 5.obs;
  final RxBool isCustom = false.obs;
  final RxInt customDurationMinutes = 0.obs;
  final RxBool isStarting = false.obs;
  final RxBool isExtending = false.obs;
  final RxBool isTerminating = false.obs;
  final RxBool isExpiryDialogVisible = false.obs;
  final Rx<Duration> remainingDuration = Duration.zero.obs;

  Timer? _countdownTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // Register listener for native background notifications
    if (Get.isRegistered<NativeBridge>()) {
      final bridge = Get.find<NativeBridge>();
      bridge.onTimedAccessExpired = _handleNativeExpiryCallback;
      bridge.onSessionTerminated = _handleNativeSessionTerminated;
      bridge.onDistractionIntercepted = _handleDistractionIntercepted;
      bridge.onSessionExtended = _handleNativeSessionExtended;
    }

    restoreSession();
    syncDistractionPackages();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    if (Get.isRegistered<NativeBridge>()) {
      final bridge = Get.find<NativeBridge>();
      if (bridge.onTimedAccessExpired == _handleNativeExpiryCallback) {
        bridge.onTimedAccessExpired = null;
      }
      if (bridge.onSessionTerminated == _handleNativeSessionTerminated) {
        bridge.onSessionTerminated = null;
      }
      if (bridge.onDistractionIntercepted == _handleDistractionIntercepted) {
        bridge.onDistractionIntercepted = null;
      }
      if (bridge.onSessionExtended == _handleNativeSessionExtended) {
        bridge.onSessionExtended = null;
      }
    }
    isExpiryDialogVisible.value = false;
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final current = _session.value;
      if (current != null) {
        if (current.status == TimedAccessStatus.active) {
          final now = DateTime.now();
          if (current.isExpiredAt(now)) {
            _handleExpiryReached(current.id, current.packageName);
          } else {
            _updateCountdown(now);
          }
        } else if (current.status ==
            TimedAccessStatus.expiredWaitingForDecision) {
          showExpiryDialog();
        }
      }
    }
  }

  /// Current session model
  TimedAccessSession? get session => _session.value;

  /// Centralized session-validity rule:
  /// A session is valid only when:
  /// 1. session exists
  /// 2. status is ACTIVE
  /// 3. expiresAt is strictly after current time (expiresAt > now)
  bool isSessionValid(TimedAccessSession? session, [DateTime? currentTime]) {
    if (session == null) return false;
    return session.isValid(currentTime);
  }

  /// Evaluates whether an active session is currently running.
  bool get hasActiveSession => isSessionValid(_session.value);

  /// Formatted remaining countdown string (e.g. 04:59)
  String get formattedRemainingTime {
    final d = remainingDuration.value;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// Status of the timed access engine.
  /// Never trusts persisted status alone: if status was active but timestamp has passed,
  /// this immediately evaluates as expiredWaitingForDecision.
  TimedAccessStatus get status {
    if (isStarting.value) return TimedAccessStatus.starting;
    if (isExtending.value) return TimedAccessStatus.extending;
    if (isTerminating.value) return TimedAccessStatus.terminating;

    final current = _session.value;
    if (current == null) return TimedAccessStatus.none;

    if (current.status == TimedAccessStatus.active && current.isExpiredAt()) {
      return TimedAccessStatus.expiredWaitingForDecision;
    }

    return current.status;
  }

  int get effectiveDurationMinutes =>
      isCustom.value ? customDurationMinutes.value : selectedDurationMinutes.value;

  /// Restores session state from persistent storage upon startup or life-cycle check.
  Future<void> restoreSession([DateTime? currentTime]) async {
    if (isStarting.value) return;
    final now = currentTime ?? DateTime.now();
    try {
      final stored = await _repository.getActiveSession();

      // Case A: No session found
      if (stored == null) {
        _session.value = null;
        remainingDuration.value = Duration.zero;
        _countdownTimer?.cancel();
        return;
      }

      // Case B & C: Evaluate time validity using authoritative expiresAt
      if (stored.expiresAt.isAfter(now)) {
        // Case B: expiresAt > now -> ACTIVE
        final active = stored.copyWith(status: TimedAccessStatus.active);
        _session.value = active;

        // Re-register native monitoring with current session parameters
        try {
          await _nativeService.startSession(
            sessionId: active.id,
            packageName: active.packageName,
            expiresAt: active.expiresAt,
          );
        } catch (_) {}

        // Resume countdown based on expiresAt - now (never restart full duration)
        _startCountdown(now);
      } else {
        // Case C: expiresAt <= now -> EXPIRED_WAITING_FOR_DECISION
        // Target app remains open. Show Expiry DialogBox in Phase 5.
        final expired = stored.copyWith(
          status: TimedAccessStatus.expiredWaitingForDecision,
        );
        _session.value = expired;
        remainingDuration.value = Duration.zero;
        _countdownTimer?.cancel();
        await _repository.updateSession(expired);

        // Phase 5: Show Expiry DialogBox
        showExpiryDialog();
      }
    } catch (_) {
      // Corrupt or invalid stored data safely handled
      _session.value = null;
      remainingDuration.value = Duration.zero;
      _countdownTimer?.cancel();
      await _repository.clearSession();
    }
  }

  void setSession(TimedAccessSession session) {
    _session.value = session;
    if (session.status == TimedAccessStatus.active && !session.isExpired) {
      _startCountdown();
    } else {
      _countdownTimer?.cancel();
      remainingDuration.value = Duration.zero;
    }
  }

  Future<void> updateSession(TimedAccessSession session) async {
    _session.value = session;
    await _repository.updateSession(session);
  }

  Future<void> clearSession() async {
    final current = _session.value;
    if (current != null) {
      try {
        await _nativeService.clearSession(sessionId: current.id);
      } catch (_) {}
    }
    _session.value = null;
    remainingDuration.value = Duration.zero;
    _countdownTimer?.cancel();
    await _repository.clearSession();
  }

  void selectPresetDuration(int minutes) {
    if (presetDurations.contains(minutes)) {
      selectedDurationMinutes.value = minutes;
      isCustom.value = false;
    }
  }

  bool setCustomDuration(int minutes) {
    if (minutes <= 0 || minutes > maxCustomMinutes) {
      return false;
    }
    customDurationMinutes.value = minutes;
    selectedDurationMinutes.value = minutes;
    isCustom.value = true;
    return true;
  }

  /// Handles app launch attempt for a distraction app.
  /// 1. If a valid ACTIVE session already exists: returns true to launch immediately.
  /// 2. If no valid active session: shows duration BottomSheet and returns false.
  Future<bool> handleDistractionLaunch({
    BuildContext? context,
    required AppInfo app,
  }) async {
    if (hasActiveSession && _session.value?.packageName == app.packageName) {
      return true;
    }
    openDurationSheet(app, context: context);
    return false;
  }

  /// Starts timed access session and launches target app.
  Future<TimedAccessSession?> startSessionAndLaunch({
    required AppInfo app,
    required int durationMinutes,
  }) async {
    selectedApp.value = app;
    if (presetDurations.contains(durationMinutes)) {
      selectPresetDuration(durationMinutes);
    } else {
      setCustomDuration(durationMinutes);
    }
    return await startTimedAccess();
  }

  void openDurationSheet(AppInfo app, {BuildContext? context}) {
    // Single Session Rule: If a valid session is already active, prevent duplicate session
    if (hasActiveSession) {
      _showError(
        'A timed access session is already active for ${_session.value?.packageName}.',
      );
      return;
    }

    // Do not open duplicate bottom sheets if already open for this app
    if ((Get.isBottomSheetOpen ?? false) && selectedApp.value?.packageName == app.packageName) {
      return;
    }

    selectedApp.value = app;
    selectedDurationMinutes.value = 5;
    isCustom.value = false;
    customDurationMinutes.value = 0;

    final targetContext = context ??
        AppRouter.rootNavigatorKey.currentContext ??
        Get.context;
    if (targetContext != null) {
      showTimedAccessBottomSheet(targetContext, app: app);
    }
  }

  /// Exact Phase 4 Start Flow:
  /// 1. Validate duration & app
  /// 2. Create TimedAccessSession
  /// 3. Persist session successfully
  /// 4. Register native monitoring
  /// 5. Launch target distraction app
  /// 6. Start/update Flutter countdown state
  Future<TimedAccessSession?> startTimedAccess() async {
    // Prevent duplicate requests from rapid taps or conflicting transitions
    if (isStarting.value || isExtending.value || isTerminating.value) return null;
    isStarting.value = true;

    try {
      // Single session protection: ensure no active session exists
      if (hasActiveSession) {
        _showError(
          'A timed access session is already active for ${_session.value?.packageName}.',
        );
        return null;
      }

      final app = selectedApp.value;
      if (app == null || app.packageName.isEmpty) {
        _showError('No app selected for Timed Access.');
        return null;
      }

      final duration = effectiveDurationMinutes;
      if (duration <= 0 || duration > maxCustomMinutes) {
        _showError(
          'Please select a valid duration (1 - $maxCustomMinutes minutes).',
        );
        return null;
      }

      // Step 2: Create valid TimedAccessSession via domain factory with unique ID
      final newSession = TimedAccessSession.create(
        packageName: app.packageName,
        duration: Duration(minutes: duration),
      );

      // Step 3: Persist session successfully. If persistence fails -> do not launch target app.
      try {
        await _repository.saveSession(newSession);
      } catch (e) {
        _showError('Failed to persist timed access session.');
        return null;
      }

      // Step 4: Register native monitoring. If native fails -> rollback persisted session and abort.
      try {
        await _nativeService.startSession(
          sessionId: newSession.id,
          packageName: newSession.packageName,
          expiresAt: newSession.expiresAt,
        );
      } catch (e) {
        await _repository.clearSession();
        _showError('Failed to register native session monitoring.');
        return null;
      }

      // Step 5: Launch target distraction app. If launch fails -> rollback native and clear session.
      bool launched = false;
      try {
        launched = await _appLauncher.launch(app.packageName);
      } catch (_) {
        launched = false;
      }

      if (!launched) {
        try {
          await _nativeService.clearSession(sessionId: newSession.id);
        } catch (_) {}
        await _repository.clearSession();
        _showError('Failed to launch ${app.name}.');
        return null;
      }

      // Step 6: Start/update Flutter countdown state
      _session.value = newSession;
      _startCountdown();

      // Close BottomSheet
      if (Get.isBottomSheetOpen == true ||
          Get.isDialogOpen == true ||
          (Get.key.currentState?.canPop() ?? false)) {
        Get.back();
      }

      return newSession;
    } catch (e) {
      _showError('Failed to start timed access: $e');
      return null;
    } finally {
      isStarting.value = false;
    }
  }

  void _startCountdown([DateTime? now]) {
    _countdownTimer?.cancel();
    _updateCountdown(now);
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  void _updateCountdown([DateTime? currentTime]) {
    final current = _session.value;
    if (current == null || current.status != TimedAccessStatus.active) {
      _countdownTimer?.cancel();
      remainingDuration.value = Duration.zero;
      return;
    }

    final now = currentTime ?? DateTime.now();
    if (current.expiresAt.isAfter(now)) {
      remainingDuration.value = current.expiresAt.difference(now);
    } else {
      remainingDuration.value = Duration.zero;
      _countdownTimer?.cancel();
      _handleExpiryReached(current.id, current.packageName);
    }
  }

  /// Stale callback protection and expiry transition
  void _handleNativeExpiryCallback(String sessionId, String packageName) {
    final current = _session.value;
    if (current == null) return;

    // Stale session check: verify callback matches current session ID
    if (current.id != sessionId) {
      return;
    }

    // Verify package name
    if (current.packageName != packageName) {
      return;
    }

    // Validate actual timestamp: expiresAt <= now
    if (!current.isExpiredAt()) {
      return;
    }

    _handleExpiryReached(sessionId, packageName);
  }

  Future<void> _handleExpiryReached(String sessionId, String packageName) async {
    final current = _session.value;
    if (current == null || current.id != sessionId) return;

    if (current.status == TimedAccessStatus.active) {
      final expired = current.copyWith(
        status: TimedAccessStatus.expiredWaitingForDecision,
      );
      _session.value = expired;
      remainingDuration.value = Duration.zero;
      _countdownTimer?.cancel();
      await _repository.updateSession(expired);

      // Phase 5 Rule: Target app MUST remain open at expiry.
      // Do NOT press Home, do NOT press Back, do NOT kill process,
      // do NOT remove task. Show Expiry DialogBox over target app.
    }

    showExpiryDialog();
  }

  /// Handles session extension triggered from the native overlay
  void _handleNativeSessionExtended(
      String sessionId, String packageName, int expiresAtMillis) {
    final current = _session.value;
    if (current == null) return;
    if (current.id != sessionId || current.packageName != packageName) return;

    final newExpiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMillis);
    final updated = current.copyWith(
      status: TimedAccessStatus.active,
      expiresAt: newExpiresAt,
    );

    _session.value = updated;
    isExtending.value = false;
    _repository.updateSession(updated);

    final now = DateTime.now();
    if (newExpiresAt.isAfter(now)) {
      remainingDuration.value = newExpiresAt.difference(now);
      _startCountdown(now);
    } else {
      remainingDuration.value = Duration.zero;
      _countdownTimer?.cancel();
    }

    dismissExpiryDialog();
  }

  /// Displays the Expiry DialogBox with duplicate protection.
  void showExpiryDialog() {
    final current = _session.value;
    if (current == null) return;

    // Duplicate expiry protection: only show once for current session
    if (isExpiryDialogVisible.value || (Get.isDialogOpen ?? false) || isTerminating.value) {
      return;
    }

    isExpiryDialogVisible.value = true;

    if (Get.context != null) {
      Get.dialog(
        TimedAccessExpiryDialog(session: current),
        barrierDismissible: false,
      ).then((_) {
        isExpiryDialogVisible.value = false;
      });
    }
  }

  /// Dismisses the Expiry DialogBox if currently open.
  void dismissExpiryDialog() {
    if (isExpiryDialogVisible.value) {
      isExpiryDialogVisible.value = false;
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
  }

  /// Extends the current Timed Access session by [duration].
  /// 1. Reads current time.
  /// 2. Calculates newExpiresAt = now + duration (never adds to old expired timestamp).
  /// 3. Updates existing session preserving SAME sessionId.
  /// 4. Persists updated session (on failure: keeps expired state, keeps dialog, shows error).
  /// 5. Transitions state to ACTIVE.
  /// 6. Resumes countdown based on newExpiresAt - DateTime.now().
  /// 7. Updates native monitoring for the SAME sessionId.
  /// 8. Dismisses the Expiry DialogBox.
  Future<bool> extendSession(Duration duration) async {
    final current = _session.value;
    if (current == null) return false;

    // Strict transition & race protection:
    // Only expiredWaitingForDecision can transition to EXTENDING.
    // If already terminating or extending, reject immediately.
    if (isExtending.value || isTerminating.value) return false;
    if (current.status != TimedAccessStatus.expiredWaitingForDecision && !current.isExpiredAt()) {
      return false;
    }
    isExtending.value = true;

    try {
      final now = DateTime.now();
      final newExpiresAt = now.add(duration);

      final updated = current.copyWith(
        status: TimedAccessStatus.active,
        expiresAt: newExpiresAt,
      );

      try {
        await _repository.updateSession(updated);
      } catch (e) {
        _showError('Failed to extend session.');
        return false;
      }

      _session.value = updated;
      _startCountdown(now);

      try {
        await _nativeService.extendSession(
          sessionId: updated.id,
          packageName: updated.packageName,
          expiresAt: updated.expiresAt,
        );
      } catch (_) {}

      dismissExpiryDialog();
      return true;
    } finally {
      isExtending.value = false;
    }
  }

  /// Handles the "Take Me Out of Here" user decision in Phase 6.
  /// Executes authoritative native termination (closes app, PiP, removes tasks, stops media,
  /// returns to Unclutter) and cleans up session state.
  Future<void> takeMeOut() async {
    final current = _session.value;
    if (current == null) return;

    // Strict transition & race protection:
    // If extending or already terminating, reject immediately.
    if (isTerminating.value || isExtending.value) return;
    isTerminating.value = true;

    try {
      _countdownTimer?.cancel();
      remainingDuration.value = Duration.zero;

      // 1. Authoritative native termination sequence
      try {
        await _nativeService.takeMeOut(
          sessionId: current.id,
          packageName: current.packageName,
        );
      } catch (_) {}

      // 2. Clear native monitoring
      try {
        await _nativeService.clearSession(sessionId: current.id);
      } catch (_) {}

      // 3. Clear session from repository
      try {
        await _repository.clearSession();
      } catch (_) {}

      // 4. Transition session state to NONE
      _session.value = null;
      dismissExpiryDialog();
    } finally {
      isTerminating.value = false;
    }
  }

  void _handleNativeSessionTerminated(String sessionId, String packageName) {
    final current = _session.value;
    if (current != null && current.id == sessionId) {
      _countdownTimer?.cancel();
      remainingDuration.value = Duration.zero;
      _session.value = null;
      dismissExpiryDialog();
    }
  }

  void _handleDistractionIntercepted(String packageName) {
    // If a session is already active for this package, do not re-prompt
    if (hasActiveSession && _session.value?.packageName == packageName) {
      return;
    }

    // Debounce duplicate prompts and active modal states
    if (isStarting.value ||
        isExtending.value ||
        isTerminating.value ||
        (Get.isBottomSheetOpen ?? false) ||
        isExpiryDialogVisible.value) {
      return;
    }

    // Do not open duplicate bottom sheets if already open for this exact app
    if ((Get.isBottomSheetOpen ?? false) && selectedApp.value?.packageName == packageName) {
      return;
    }

    // Resolve AppInfo
    AppInfo? app;
    if (Get.isRegistered<AppsController>()) {
      try {
        final all = Get.find<AppsController>().allApps;
        for (final a in all) {
          if (a.packageName == packageName) {
            app = a;
            break;
          }
        }
      } catch (_) {}
    }

    app ??= AppInfo(
      name: _formatPackageName(packageName),
      packageName: packageName,
    );

    openDurationSheet(app);
  }

  /// Syncs configured distraction packages to native Android for accessibility enforcement.
  Future<void> syncDistractionPackages() async {
    if (!Get.isRegistered<NativeBridge>()) return;
    try {
      List<String> packages = [];
      if (Get.isRegistered<DistractionAppService>()) {
        packages = Get.find<DistractionAppService>().settings.enabledPackages.toList();
      }
      await Get.find<NativeBridge>().setDistractionPackages(packages);
    } catch (_) {}
  }

  String _formatPackageName(String packageName) {
    if (packageName.isEmpty) return 'App';
    final parts = packageName.split('.');
    final last = parts.isNotEmpty ? parts.last : packageName;
    if (last.isEmpty) return packageName;
    return '${last[0].toUpperCase()}${last.substring(1)}';
  }

  void _showError(String message) {
    if (Get.context != null) {
      ScaffoldMessenger.maybeOf(Get.context!)?.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
