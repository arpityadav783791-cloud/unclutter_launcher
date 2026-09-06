import '../entities/timed_access_session.dart';

abstract class TimedAccessRepository {
  Future<TimedAccessSession?> getActiveSession();

  Future<void> saveSession(
    TimedAccessSession session,
  );

  Future<void> updateSession(
    TimedAccessSession session,
  );

  Future<void> clearSession();
}
