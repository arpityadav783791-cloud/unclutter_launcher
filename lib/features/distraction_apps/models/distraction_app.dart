/// Represents an application evaluated for distraction tracking.
class DistractionApp {
  final String packageName;
  final String appName;
  final bool isAutomaticallyDetected;
  final bool isEnabled;
  final String? categoryLabel;

  const DistractionApp({
    required this.packageName,
    required this.appName,
    this.isAutomaticallyDetected = false,
    this.isEnabled = true,
    this.categoryLabel,
  });

  DistractionApp copyWith({
    String? packageName,
    String? appName,
    bool? isAutomaticallyDetected,
    bool? isEnabled,
    String? categoryLabel,
  }) {
    return DistractionApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isAutomaticallyDetected:
          isAutomaticallyDetected ?? this.isAutomaticallyDetected,
      isEnabled: isEnabled ?? this.isEnabled,
      categoryLabel: categoryLabel ?? this.categoryLabel,
    );
  }

  factory DistractionApp.fromMap(Map<String, dynamic> map) {
    return DistractionApp(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      isAutomaticallyDetected:
          map['isAutomaticallyDetected'] as bool? ?? false,
      isEnabled: map['isEnabled'] as bool? ?? true,
      categoryLabel: map['categoryLabel'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'isAutomaticallyDetected': isAutomaticallyDetected,
      'isEnabled': isEnabled,
      if (categoryLabel != null) 'categoryLabel': categoryLabel,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistractionApp &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName &&
          appName == other.appName &&
          isAutomaticallyDetected == other.isAutomaticallyDetected &&
          isEnabled == other.isEnabled &&
          categoryLabel == other.categoryLabel;

  @override
  int get hashCode => Object.hash(
        packageName,
        appName,
        isAutomaticallyDetected,
        isEnabled,
        categoryLabel,
      );
}
