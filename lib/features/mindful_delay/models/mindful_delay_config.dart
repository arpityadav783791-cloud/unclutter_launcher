class MindfulDelayConfig {
  final String packageName;
  final bool enabled;
  final int durationSeconds;

  const MindfulDelayConfig({
    required this.packageName,
    this.enabled = false,
    this.durationSeconds = 5,
  });

  factory MindfulDelayConfig.fromMap(Map<String, dynamic> map) {
    return MindfulDelayConfig(
      packageName: map['packageName'] as String? ?? '',
      enabled: map['enabled'] as bool? ?? false,
      durationSeconds: map['durationSeconds'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'enabled': enabled,
      'durationSeconds': durationSeconds,
    };
  }

  MindfulDelayConfig copyWith({
    bool? enabled,
    int? durationSeconds,
  }) {
    return MindfulDelayConfig(
      packageName: packageName,
      enabled: enabled ?? this.enabled,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  static const List<int> availableDurations = [
    5,    // 5 seconds
    10,
    15,
    30,
    60,   // 1 minute
    300,  // 5 minutes
    600,  // 10 minutes
  ];

  static String formatDuration(int seconds) {
    if (seconds < 60) return '$seconds seconds';
    final minutes = seconds ~/ 60;
    return minutes == 1 ? '1 minute' : '$minutes minutes';
  }
}
