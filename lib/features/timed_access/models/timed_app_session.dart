/// Model representing an active or completed timed distraction app session.
class TimedAppSession {
  final String packageName;
  final String appName;
  final DateTime startedAt;
  final DateTime expiresAt;
  final int durationMinutes;

  const TimedAppSession({
    required this.packageName,
    required this.appName,
    required this.startedAt,
    required this.expiresAt,
    required this.durationMinutes,
  });

  /// True if current time has passed the expiration time.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Remaining duration until expiration. Returns [Duration.zero] if expired.
  Duration get remainingDuration {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Total seconds remaining in the session.
  int get remainingSeconds => remainingDuration.inSeconds;

  /// Remaining minutes (rounded up to nearest minute so 59s still counts as 1m).
  int get remainingMinutes {
    final secs = remainingDuration.inSeconds;
    if (secs <= 0) return 0;
    return (secs + 59) ~/ 60;
  }

  factory TimedAppSession.create({
    required String packageName,
    required String appName,
    required int durationMinutes,
    DateTime? now,
  }) {
    final start = now ?? DateTime.now();
    return TimedAppSession(
      packageName: packageName,
      appName: appName,
      startedAt: start,
      expiresAt: start.add(Duration(minutes: durationMinutes)),
      durationMinutes: durationMinutes,
    );
  }

  factory TimedAppSession.fromMap(Map<String, dynamic> map) {
    return TimedAppSession(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      startedAt: DateTime.parse(
        map['startedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      expiresAt: DateTime.parse(
        map['expiresAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      durationMinutes: map['durationMinutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'startedAt': startedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'durationMinutes': durationMinutes,
    };
  }

  TimedAppSession copyWith({
    String? packageName,
    String? appName,
    DateTime? startedAt,
    DateTime? expiresAt,
    int? durationMinutes,
  }) {
    return TimedAppSession(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimedAppSession &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName &&
          appName == other.appName &&
          startedAt == other.startedAt &&
          expiresAt == other.expiresAt &&
          durationMinutes == other.durationMinutes;

  @override
  int get hashCode =>
      packageName.hashCode ^
      appName.hashCode ^
      startedAt.hashCode ^
      expiresAt.hashCode ^
      durationMinutes.hashCode;

  @override
  String toString() =>
      'TimedAppSession(packageName: $packageName, appName: $appName, '
      'startedAt: $startedAt, expiresAt: $expiresAt, durationMinutes: $durationMinutes)';
}
