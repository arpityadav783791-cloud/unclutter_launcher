class ScheduleConfig {
  final String packageName;
  final bool enabled;
  /// Minutes from midnight (0–1439)
  final int startMinutes;
  /// Minutes from midnight (0–1439)
  final int endMinutes;

  const ScheduleConfig({
    required this.packageName,
    this.enabled = false,
    this.startMinutes = 22 * 60, // 10:00 PM
    this.endMinutes = 7 * 60,    // 7:00 AM
  });

  factory ScheduleConfig.fromMap(Map<String, dynamic> map) {
    return ScheduleConfig(
      packageName: map['packageName'] as String? ?? '',
      enabled: map['enabled'] as bool? ?? false,
      startMinutes: map['startMinutes'] as int? ?? 22 * 60,
      endMinutes: map['endMinutes'] as int? ?? 7 * 60,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'enabled': enabled,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
    };
  }

  ScheduleConfig copyWith({
    bool? enabled,
    int? startMinutes,
    int? endMinutes,
  }) {
    return ScheduleConfig(
      packageName: packageName,
      enabled: enabled ?? this.enabled,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
    );
  }

  String get startFormatted => _format(startMinutes);
  String get endFormatted => _format(endMinutes);

  static String _format(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final mm = m.toString().padLeft(2, '0');
    return '$hour12:$mm $period';
  }

  /// Returns true if the current time falls inside the blocked window.
  /// Supports overnight ranges (e.g. 10 PM → 7 AM).
  bool isCurrentlyBlocked() {
    if (!enabled) return false;

    final now = DateTime.now();
    final current = now.hour * 60 + now.minute;

    if (startMinutes == endMinutes) return false; // invalid

    if (startMinutes < endMinutes) {
      // Same-day range (e.g. 9 AM → 12 PM)
      return current >= startMinutes && current < endMinutes;
    } else {
      // Overnight range (e.g. 10 PM → 7 AM)
      return current >= startMinutes || current < endMinutes;
    }
  }

  /// Common presets for quick selection
  static const List<Map<String, int>> presets = [
    {'start': 21 * 60, 'end': 7 * 60},   // 9 PM – 7 AM
    {'start': 22 * 60, 'end': 7 * 60},   // 10 PM – 7 AM
    {'start': 23 * 60, 'end': 6 * 60},   // 11 PM – 6 AM
    {'start': 9 * 60, 'end': 12 * 60},   // 9 AM – 12 PM
    {'start': 12 * 60, 'end': 13 * 60},  // 12 PM – 1 PM
    {'start': 18 * 60, 'end': 20 * 60},  // 6 PM – 8 PM
  ];

  static String presetLabel(int start, int end) {
    return '${_format(start)} → ${_format(end)}';
  }
}
