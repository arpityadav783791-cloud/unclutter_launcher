class DailyLimitConfig {
  final String packageName;
  final bool enabled;
  final int limitMinutes;
  /// Extra minutes granted today via "Extend"
  final int extensionMinutesToday;
  final String? extensionDate; // yyyy-MM-dd

  const DailyLimitConfig({
    required this.packageName,
    this.enabled = false,
    this.limitMinutes = 30,
    this.extensionMinutesToday = 0,
    this.extensionDate,
  });

  factory DailyLimitConfig.fromMap(Map<String, dynamic> map) {
    return DailyLimitConfig(
      packageName: map['packageName'] as String? ?? '',
      enabled: map['enabled'] as bool? ?? false,
      limitMinutes: map['limitMinutes'] as int? ?? 30,
      extensionMinutesToday: map['extensionMinutesToday'] as int? ?? 0,
      extensionDate: map['extensionDate'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'enabled': enabled,
      'limitMinutes': limitMinutes,
      'extensionMinutesToday': extensionMinutesToday,
      'extensionDate': extensionDate,
    };
  }

  DailyLimitConfig copyWith({
    bool? enabled,
    int? limitMinutes,
    int? extensionMinutesToday,
    String? extensionDate,
    bool clearExtension = false,
  }) {
    return DailyLimitConfig(
      packageName: packageName,
      enabled: enabled ?? this.enabled,
      limitMinutes: limitMinutes ?? this.limitMinutes,
      extensionMinutesToday: clearExtension
          ? 0
          : (extensionMinutesToday ?? this.extensionMinutesToday),
      extensionDate:
          clearExtension ? null : (extensionDate ?? this.extensionDate),
    );
  }

  /// Effective limit for today (base + today's extension)
  int effectiveLimitMinutes(String todayDate) {
    if (extensionDate == todayDate) {
      return limitMinutes + extensionMinutesToday;
    }
    return limitMinutes;
  }

  static const List<int> availableLimits = [
    5,
    10,
    15,
    30,
    45,
    60,
    90,
    120,
  ];

  static String formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return h == 1 ? '1 hour' : '$h hours';
    return '${h}h ${m}m';
  }
}
