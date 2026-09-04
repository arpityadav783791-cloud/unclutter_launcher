class LauncherSettings {
  final bool showClock;
  final bool showDate;
  final double textScale; // 0.85 – 1.25
  final String themeMode; // system | light | dark

  // ── Olauncher Subsystem Settings ──
  final String homeAlignment; // left | center | right
  final bool homeBottomAlignment;
  final int homeAppsCount; // 0 to 8
  final String dateTimeVisibility; // on | date_only | off
  final bool showStatusBar;
  final bool boldFont;
  final bool autoShowKeyboard;
  final bool autoLaunchSingleMatch;
  final String swipeDownAction; // notifications | search
  final String? swipeLeftPackage;
  final String? swipeRightPackage;
  final bool doubleTapToLock;
  final bool showScreenTime;
  final String? customScreenTimePackage;
  final String eInkMode; // auto | on | off
  final bool dailyWallpaperEnabled;

  const LauncherSettings({
    this.showClock = true,
    this.showDate = true,
    this.textScale = 1.0,
    this.themeMode = 'system',
    this.homeAlignment = 'left',
    this.homeBottomAlignment = false,
    this.homeAppsCount = 4,
    this.dateTimeVisibility = 'on',
    this.showStatusBar = true,
    this.boldFont = false,
    this.autoShowKeyboard = true,
    this.autoLaunchSingleMatch = true,
    this.swipeDownAction = 'notifications',
    this.swipeLeftPackage,
    this.swipeRightPackage,
    this.doubleTapToLock = false,
    this.showScreenTime = true,
    this.customScreenTimePackage,
    this.eInkMode = 'auto',
    this.dailyWallpaperEnabled = false,
  });

  factory LauncherSettings.fromMap(Map<String, dynamic> map) {
    return LauncherSettings(
      showClock: map['showClock'] as bool? ?? true,
      showDate: map['showDate'] as bool? ?? true,
      textScale: (map['textScale'] as num?)?.toDouble() ?? 1.0,
      themeMode: map['themeMode'] as String? ?? 'system',
      homeAlignment: map['homeAlignment'] as String? ?? 'left',
      homeBottomAlignment: map['homeBottomAlignment'] as bool? ?? false,
      homeAppsCount: (map['homeAppsCount'] as num?)?.toInt() ?? 4,
      dateTimeVisibility: map['dateTimeVisibility'] as String? ?? 'on',
      showStatusBar: map['showStatusBar'] as bool? ?? true,
      boldFont: map['boldFont'] as bool? ?? false,
      autoShowKeyboard: map['autoShowKeyboard'] as bool? ?? true,
      autoLaunchSingleMatch: map['autoLaunchSingleMatch'] as bool? ?? true,
      swipeDownAction: map['swipeDownAction'] as String? ?? 'notifications',
      swipeLeftPackage: map['swipeLeftPackage'] as String?,
      swipeRightPackage: map['swipeRightPackage'] as String?,
      doubleTapToLock: map['doubleTapToLock'] as bool? ?? false,
      showScreenTime: map['showScreenTime'] as bool? ?? true,
      customScreenTimePackage: map['customScreenTimePackage'] as String?,
      eInkMode: map['eInkMode'] as String? ?? 'auto',
      dailyWallpaperEnabled: map['dailyWallpaperEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'showClock': showClock,
      'showDate': showDate,
      'textScale': textScale,
      'themeMode': themeMode,
      'homeAlignment': homeAlignment,
      'homeBottomAlignment': homeBottomAlignment,
      'homeAppsCount': homeAppsCount,
      'dateTimeVisibility': dateTimeVisibility,
      'showStatusBar': showStatusBar,
      'boldFont': boldFont,
      'autoShowKeyboard': autoShowKeyboard,
      'autoLaunchSingleMatch': autoLaunchSingleMatch,
      'swipeDownAction': swipeDownAction,
      'swipeLeftPackage': swipeLeftPackage,
      'swipeRightPackage': swipeRightPackage,
      'doubleTapToLock': doubleTapToLock,
      'showScreenTime': showScreenTime,
      'customScreenTimePackage': customScreenTimePackage,
      'eInkMode': eInkMode,
      'dailyWallpaperEnabled': dailyWallpaperEnabled,
    };
  }

  LauncherSettings copyWith({
    bool? showClock,
    bool? showDate,
    double? textScale,
    String? themeMode,
    String? homeAlignment,
    bool? homeBottomAlignment,
    int? homeAppsCount,
    String? dateTimeVisibility,
    bool? showStatusBar,
    bool? boldFont,
    bool? autoShowKeyboard,
    bool? autoLaunchSingleMatch,
    String? swipeDownAction,
    String? swipeLeftPackage,
    String? swipeRightPackage,
    bool? doubleTapToLock,
    bool? showScreenTime,
    String? customScreenTimePackage,
    String? eInkMode,
    bool? dailyWallpaperEnabled,
    bool clearSwipeLeft = false,
    bool clearSwipeRight = false,
    bool clearCustomScreenTimePackage = false,
  }) {
    return LauncherSettings(
      showClock: showClock ?? this.showClock,
      showDate: showDate ?? this.showDate,
      textScale: textScale ?? this.textScale,
      themeMode: themeMode ?? this.themeMode,
      homeAlignment: homeAlignment ?? this.homeAlignment,
      homeBottomAlignment: homeBottomAlignment ?? this.homeBottomAlignment,
      homeAppsCount: homeAppsCount ?? this.homeAppsCount,
      dateTimeVisibility: dateTimeVisibility ?? this.dateTimeVisibility,
      showStatusBar: showStatusBar ?? this.showStatusBar,
      boldFont: boldFont ?? this.boldFont,
      autoShowKeyboard: autoShowKeyboard ?? this.autoShowKeyboard,
      autoLaunchSingleMatch:
          autoLaunchSingleMatch ?? this.autoLaunchSingleMatch,
      swipeDownAction: swipeDownAction ?? this.swipeDownAction,
      swipeLeftPackage:
          clearSwipeLeft ? null : (swipeLeftPackage ?? this.swipeLeftPackage),
      swipeRightPackage: clearSwipeRight
          ? null
          : (swipeRightPackage ?? this.swipeRightPackage),
      doubleTapToLock: doubleTapToLock ?? this.doubleTapToLock,
      showScreenTime: showScreenTime ?? this.showScreenTime,
      customScreenTimePackage: clearCustomScreenTimePackage
          ? null
          : (customScreenTimePackage ?? this.customScreenTimePackage),
      eInkMode: eInkMode ?? this.eInkMode,
      dailyWallpaperEnabled:
          dailyWallpaperEnabled ?? this.dailyWallpaperEnabled,
    );
  }
}
