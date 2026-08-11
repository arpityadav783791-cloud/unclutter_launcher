class LauncherSettings {
  final bool showClock;
  final bool showDate;
  final double textScale; // 0.85 – 1.25
  final String themeMode; // system | light | dark

  const LauncherSettings({
    this.showClock = true,
    this.showDate = true,
    this.textScale = 1.0,
    this.themeMode = 'system',
  });

  factory LauncherSettings.fromMap(Map<String, dynamic> map) {
    return LauncherSettings(
      showClock: map['showClock'] as bool? ?? true,
      showDate: map['showDate'] as bool? ?? true,
      textScale: (map['textScale'] as num?)?.toDouble() ?? 1.0,
      themeMode: map['themeMode'] as String? ?? 'system',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'showClock': showClock,
      'showDate': showDate,
      'textScale': textScale,
      'themeMode': themeMode,
    };
  }

  LauncherSettings copyWith({
    bool? showClock,
    bool? showDate,
    double? textScale,
    String? themeMode,
  }) {
    return LauncherSettings(
      showClock: showClock ?? this.showClock,
      showDate: showDate ?? this.showDate,
      textScale: textScale ?? this.textScale,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
