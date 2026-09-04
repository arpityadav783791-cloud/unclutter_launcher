class AppInfo {
  final String name; // Original name from system
  final String packageName;
  final bool isSystemApp;
  final bool isGame;
  final int category;
  final int installTime; // Epoch millis
  final int userSerial;
  final bool isWorkProfile;
  final String activityName;

  const AppInfo({
    required this.name,
    required this.packageName,
    this.isSystemApp = false,
    this.isGame = false,
    this.category = -1,
    this.installTime = 0,
    this.userSerial = 0,
    this.isWorkProfile = false,
    this.activityName = '',
  });

  /// Unique app identifier for multi-profile resolution, favorites, and storage
  String get uniqueKey =>
      userSerial == 0 ? packageName : '$packageName|$userSerial';

  /// Whether the app was installed recently (within last 24 hours)
  bool get isRecentInstall {
    if (installTime <= 0) return false;
    final age = DateTime.now().millisecondsSinceEpoch - installTime;
    return age >= 0 && age < const Duration(hours: 24).inMilliseconds;
  }

  factory AppInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppInfo(
      name: map['name'] as String? ?? 'Unknown',
      packageName: map['packageName'] as String? ?? '',
      isSystemApp: map['isSystemApp'] as bool? ?? false,
      isGame: map['isGame'] as bool? ?? false,
      category: map['category'] as int? ?? -1,
      installTime: (map['installTime'] as num?)?.toInt() ?? 0,
      userSerial: (map['userSerial'] as num?)?.toInt() ?? 0,
      isWorkProfile: map['isWorkProfile'] as bool? ?? false,
      activityName: map['activityName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'packageName': packageName,
      'isSystemApp': isSystemApp,
      'isGame': isGame,
      'category': category,
      'installTime': installTime,
      'userSerial': userSerial,
      'isWorkProfile': isWorkProfile,
      'activityName': activityName,
    };
  }

  @override
  String toString() =>
      'AppInfo(name: $name, package: $packageName, userSerial: $userSerial)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppInfo &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName &&
          userSerial == other.userSerial;

  @override
  int get hashCode => Object.hash(packageName, userSerial);
}
