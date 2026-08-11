class FocusModeConfig {
  final bool isActive;
  final DateTime? endsAt;
  final List<String> blockedPackages;

  const FocusModeConfig({
    this.isActive = false,
    this.endsAt,
    this.blockedPackages = const [],
  });

  factory FocusModeConfig.fromMap(Map<String, dynamic> map) {
    return FocusModeConfig(
      isActive: map['isActive'] as bool? ?? false,
      endsAt: map['endsAt'] != null
          ? DateTime.tryParse(map['endsAt'] as String)
          : null,
      blockedPackages: (map['blockedPackages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive,
      'endsAt': endsAt?.toIso8601String(),
      'blockedPackages': blockedPackages,
    };
  }

  FocusModeConfig copyWith({
    bool? isActive,
    DateTime? endsAt,
    List<String>? blockedPackages,
    bool clearEndsAt = false,
  }) {
    return FocusModeConfig(
      isActive: isActive ?? this.isActive,
      endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
      blockedPackages: blockedPackages ?? this.blockedPackages,
    );
  }

  /// Remaining duration. Returns Duration.zero if inactive or expired.
  Duration get remaining {
    if (!isActive || endsAt == null) return Duration.zero;
    final diff = endsAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get isCurrentlyActive {
    if (!isActive) return false;
    if (endsAt == null) return true; // indefinite
    return endsAt!.isAfter(DateTime.now());
  }

  static const List<int> availableDurationsMinutes = [
    15,
    30,
    45,
    60,
    90,
    120,
    180,
  ];

  static String formatDuration(Duration d) {
    if (d.inSeconds <= 0) return '0m';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) {
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '${m}m';
  }
}
