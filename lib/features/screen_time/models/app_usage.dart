class AppUsage {
  final String packageName;
  final int totalTimeInForegroundMs;
  final int lastTimeUsed;

  const AppUsage({
    required this.packageName,
    required this.totalTimeInForegroundMs,
    this.lastTimeUsed = 0,
  });

  factory AppUsage.fromMap(Map<dynamic, dynamic> map) {
    return AppUsage(
      packageName: map['packageName'] as String? ?? '',
      totalTimeInForegroundMs:
          (map['totalTimeInForeground'] as num?)?.toInt() ?? 0,
      lastTimeUsed: (map['lastTimeUsed'] as num?)?.toInt() ?? 0,
    );
  }

  /// Human readable duration, e.g. "1h 24m", "48m", "12s"
  String get formattedDuration {
    final totalSeconds = totalTimeInForegroundMs ~/ 1000;
    if (totalSeconds < 60) return '${totalSeconds}s';

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  int get minutes => totalTimeInForegroundMs ~/ 60000;
}

class SingleAppUsage {
  final String packageName;
  final int todayMs;
  final int weekMs;

  const SingleAppUsage({
    required this.packageName,
    required this.todayMs,
    required this.weekMs,
  });

  factory SingleAppUsage.fromMap(Map<dynamic, dynamic> map) {
    return SingleAppUsage(
      packageName: map['packageName'] as String? ?? '',
      todayMs: (map['todayMs'] as num?)?.toInt() ?? 0,
      weekMs: (map['weekMs'] as num?)?.toInt() ?? 0,
    );
  }

  String get todayFormatted => _format(todayMs);
  String get weekFormatted => _format(weekMs);

  static String _format(int ms) {
    final totalSeconds = ms ~/ 1000;
    if (totalSeconds < 60) return '${totalSeconds}s';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }
}
