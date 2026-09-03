/// Model representing the Protected Launcher Mode state.
class ProtectedModeState {
  final bool enabled;
  final DateTime? enabledAt;
  final bool deviceOwnerActive;
  final bool defaultLauncherActive;

  const ProtectedModeState({
    this.enabled = false,
    this.enabledAt,
    this.deviceOwnerActive = false,
    this.defaultLauncherActive = false,
  });

  factory ProtectedModeState.initial() => const ProtectedModeState();

  factory ProtectedModeState.fromMap(Map<String, dynamic> map) {
    final enabledAtMillis = map['enabledAt'] as int?;
    return ProtectedModeState(
      enabled: map['enabled'] as bool? ?? false,
      enabledAt: enabledAtMillis != null && enabledAtMillis > 0
          ? DateTime.fromMillisecondsSinceEpoch(enabledAtMillis)
          : null,
      deviceOwnerActive: map['deviceOwnerActive'] as bool? ?? false,
      defaultLauncherActive: map['defaultLauncherActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'enabledAt': enabledAt?.millisecondsSinceEpoch,
      'deviceOwnerActive': deviceOwnerActive,
      'defaultLauncherActive': defaultLauncherActive,
    };
  }

  ProtectedModeState copyWith({
    bool? enabled,
    DateTime? enabledAt,
    bool? deviceOwnerActive,
    bool? defaultLauncherActive,
  }) {
    return ProtectedModeState(
      enabled: enabled ?? this.enabled,
      enabledAt: enabledAt ?? this.enabledAt,
      deviceOwnerActive: deviceOwnerActive ?? this.deviceOwnerActive,
      defaultLauncherActive:
          defaultLauncherActive ?? this.defaultLauncherActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProtectedModeState &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          enabledAt == other.enabledAt &&
          deviceOwnerActive == other.deviceOwnerActive &&
          defaultLauncherActive == other.defaultLauncherActive;

  @override
  int get hashCode =>
      enabled.hashCode ^
      enabledAt.hashCode ^
      deviceOwnerActive.hashCode ^
      defaultLauncherActive.hashCode;

  @override
  String toString() =>
      'ProtectedModeState(enabled: $enabled, enabledAt: $enabledAt, '
      'deviceOwnerActive: $deviceOwnerActive, defaultLauncherActive: $defaultLauncherActive)';
}
