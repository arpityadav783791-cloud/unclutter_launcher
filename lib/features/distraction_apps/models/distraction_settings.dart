/// Represents persistent configuration for distraction app management,
/// tracking enabled, user-excluded, and manually added apps.
class DistractionSettings {
  final Set<String> enabledPackages;
  final Set<String> excludedPackages;
  final Set<String> manuallyAddedPackages;

  const DistractionSettings({
    this.enabledPackages = const {},
    this.excludedPackages = const {},
    this.manuallyAddedPackages = const {},
  });

  DistractionSettings copyWith({
    Set<String>? enabledPackages,
    Set<String>? excludedPackages,
    Set<String>? manuallyAddedPackages,
  }) {
    return DistractionSettings(
      enabledPackages: enabledPackages ?? this.enabledPackages,
      excludedPackages: excludedPackages ?? this.excludedPackages,
      manuallyAddedPackages:
          manuallyAddedPackages ?? this.manuallyAddedPackages,
    );
  }

  factory DistractionSettings.fromMap(Map<String, dynamic> map) {
    return DistractionSettings(
      enabledPackages: (map['enabledPackages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      excludedPackages: (map['excludedPackages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      manuallyAddedPackages:
          (map['manuallyAddedPackages'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabledPackages': enabledPackages.toList(),
      'excludedPackages': excludedPackages.toList(),
      'manuallyAddedPackages': manuallyAddedPackages.toList(),
    };
  }

  /// Evaluates whether an app is considered a distraction according to the priority:
  /// 1. User exclusion (highest priority -> OFF)
  /// 2. User addition (next priority -> ON)
  /// 3. Automatic classification (fallback)
  bool isDistraction({
    required String packageName,
    required bool isAutomaticallyDetected,
  }) {
    if (excludedPackages.contains(packageName)) {
      return false;
    }
    if (manuallyAddedPackages.contains(packageName)) {
      return true;
    }
    if (enabledPackages.contains(packageName)) {
      return true;
    }
    return isAutomaticallyDetected;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistractionSettings &&
          runtimeType == other.runtimeType &&
          _setEquals(enabledPackages, other.enabledPackages) &&
          _setEquals(excludedPackages, other.excludedPackages) &&
          _setEquals(manuallyAddedPackages, other.manuallyAddedPackages);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(enabledPackages),
        Object.hashAll(excludedPackages),
        Object.hashAll(manuallyAddedPackages),
      );

  static bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
