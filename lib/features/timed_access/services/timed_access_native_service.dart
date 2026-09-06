abstract class TimedAccessNativeService {
  Future<void> startSession({
    required String sessionId,
    required String packageName,
    required DateTime expiresAt,
  });

  Future<void> extendSession({
    required String sessionId,
    required String packageName,
    required DateTime expiresAt,
  });

  Future<void> showExpiryDialog({
    required String sessionId,
    required String packageName,
  });

  Future<void> takeMeOut({
    required String sessionId,
    required String packageName,
  });

  Future<void> clearSession({
    required String sessionId,
  });
}
