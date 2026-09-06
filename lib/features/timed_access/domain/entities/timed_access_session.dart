import 'timed_access_status.dart';

class TimedAccessSession {
  static int _idCounter = 0;

  final String id;
  final String packageName;
  final DateTime startedAt;
  final DateTime expiresAt;
  final TimedAccessStatus status;

  const TimedAccessSession({
    required this.id,
    required this.packageName,
    required this.startedAt,
    required this.expiresAt,
    required this.status,
  });

  factory TimedAccessSession.create({
    required String packageName,
    required Duration duration,
    String? id,
    DateTime? now,
  }) {
    final start = now ?? DateTime.now();
    _idCounter++;
    final uniqueId =
        id ?? '${packageName}_${start.microsecondsSinceEpoch}_$_idCounter';
    return TimedAccessSession(
      id: uniqueId,
      packageName: packageName,
      startedAt: start,
      expiresAt: start.add(duration),
      status: TimedAccessStatus.active,
    );
  }

  /// Centralized session-validity rule:
  /// A session is valid only when:
  /// - status is ACTIVE
  /// - expiresAt is strictly after current time (expiresAt > now)
  bool isValid([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    return status == TimedAccessStatus.active && expiresAt.isAfter(now);
  }

  /// Whether the session has passed its expiration timestamp.
  /// (expiresAt <= now)
  bool isExpiredAt([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    return !expiresAt.isAfter(now);
  }

  /// Backward-compatible getter checking current system clock
  bool get isExpired => isExpiredAt();

  /// Backward-compatible getter checking current system clock and status
  bool get isActive => isValid();

  /// Calculates remaining duration strictly from expiresAt - now.
  /// Never negative.
  Duration remainingDuration([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    if (!expiresAt.isAfter(now)) {
      return Duration.zero;
    }
    return expiresAt.difference(now);
  }

  TimedAccessSession copyWith({
    String? id,
    String? packageName,
    DateTime? startedAt,
    DateTime? expiresAt,
    TimedAccessStatus? status,
  }) {
    return TimedAccessSession(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimedAccessSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          packageName == other.packageName &&
          startedAt.millisecondsSinceEpoch ==
              other.startedAt.millisecondsSinceEpoch &&
          expiresAt.millisecondsSinceEpoch ==
              other.expiresAt.millisecondsSinceEpoch &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      packageName.hashCode ^
      startedAt.millisecondsSinceEpoch.hashCode ^
      expiresAt.millisecondsSinceEpoch.hashCode ^
      status.hashCode;

  @override
  String toString() {
    return 'TimedAccessSession(id: $id, pkg: $packageName, status: $status, expiresAt: $expiresAt)';
  }
}
