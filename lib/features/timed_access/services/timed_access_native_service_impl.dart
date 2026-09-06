import 'package:get/get.dart';
import '../../../../core/services/native_bridge.dart';
import '../controllers/timed_access_controller.dart';
import 'timed_access_native_service.dart';

class TimedAccessNativeServiceImpl implements TimedAccessNativeService {
  final NativeBridge? _bridge;

  TimedAccessNativeServiceImpl({NativeBridge? bridge})
      : _bridge = bridge ??
            (Get.isRegistered<NativeBridge>()
                ? Get.find<NativeBridge>()
                : null);

  @override
  Future<void> startSession({
    required String sessionId,
    required String packageName,
    required DateTime expiresAt,
  }) async {
    final bridge = _bridge;
    if (bridge == null) return;

    final success = await bridge.startTimedAccessMonitoring(
      sessionId: sessionId,
      packageName: packageName,
      expiresAtMillis: expiresAt.millisecondsSinceEpoch,
    );
    if (!success) {
      throw Exception('Failed to register native monitoring for session $sessionId');
    }
  }

  @override
  Future<void> clearSession({required String sessionId}) async {
    final bridge = _bridge;
    if (bridge == null) return;
    await bridge.stopTimedAccessMonitoring(sessionId: sessionId);
  }

  @override
  Future<void> extendSession({
    required String sessionId,
    required String packageName,
    required DateTime expiresAt,
  }) async {
    await startSession(
      sessionId: sessionId,
      packageName: packageName,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> showExpiryDialog({
    required String sessionId,
    required String packageName,
  }) async {
    if (Get.isRegistered<TimedAccessController>()) {
      Get.find<TimedAccessController>().showExpiryDialog();
    }
  }

  @override
  Future<void> takeMeOut({
    required String sessionId,
    required String packageName,
  }) async {
    final bridge = _bridge;
    if (bridge == null) return;
    await bridge.terminateTimedSession(sessionId: sessionId);
  }
}
