import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../models/timed_app_session.dart';

/// Repository and persistence service for Timed Distraction App Access.
class TimedAccessService extends GetxService {
  static const String _key = 'active_timed_session';
  final StorageService _storage = Get.find<StorageService>();

  TimedAppSession? _activeSession;

  TimedAppSession? get activeSession => _activeSession;

  bool get hasActiveSession =>
      _activeSession != null && !_activeSession!.isExpired;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  void _load() {
    final raw = _storage.getString(_key);
    if (raw == null || raw.isEmpty) {
      _activeSession = null;
      return;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final session = TimedAppSession.fromMap(map);

      // Check validity on startup/resume:
      // If already expired, clear it so stale sessions are not persisted forever.
      if (session.isExpired) {
        _activeSession = null;
        _storage.remove(_key);
      } else {
        _activeSession = session;
      }
    } catch (_) {
      _activeSession = null;
      _storage.remove(_key);
    }
  }

  Future<void> _save() async {
    if (_activeSession == null) {
      await _storage.remove(_key);
    } else {
      await _storage.setString(_key, jsonEncode(_activeSession!.toMap()));
    }
  }

  /// Checks if an active (unexpired) session exists for the given package.
  bool isSessionActiveFor(String packageName) {
    if (_activeSession == null) return false;
    if (_activeSession!.packageName != packageName) return false;
    if (_activeSession!.isExpired) {
      // Lazy cleanup of expired session
      clearSession();
      return false;
    }
    return true;
  }

  /// Starts a new session with the specified duration.
  Future<TimedAppSession> startSession({
    required String packageName,
    required String appName,
    required int durationMinutes,
    DateTime? now,
  }) async {
    final session = TimedAppSession.create(
      packageName: packageName,
      appName: appName,
      durationMinutes: durationMinutes,
      now: now,
    );
    _activeSession = session;
    await _save();
    return session;
  }

  /// Extends the active session by [extraMinutes].
  /// If session is expired, extension starts from [DateTime.now()].
  Future<TimedAppSession?> extendSession({
    required int extraMinutes,
    DateTime? now,
  }) async {
    if (_activeSession == null) return null;

    final currentTime = now ?? DateTime.now();
    final baseTime =
        _activeSession!.isExpired ? currentTime : _activeSession!.expiresAt;

    final updated = _activeSession!.copyWith(
      expiresAt: baseTime.add(Duration(minutes: extraMinutes)),
      durationMinutes: _activeSession!.durationMinutes + extraMinutes,
    );

    _activeSession = updated;
    await _save();
    return updated;
  }

  /// Clears the active session and removes it from persistent storage.
  Future<void> clearSession() async {
    _activeSession = null;
    await _storage.remove(_key);
  }

  /// Re-validates current active session against current time.
  /// If expired, returns true and optionally cleans up.
  bool checkAndCleanIfExpired() {
    if (_activeSession == null) return false;
    if (_activeSession!.isExpired) {
      clearSession();
      return true;
    }
    return false;
  }
}
