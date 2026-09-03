/// Per-app configuration stored locally.
/// Keyed by packageName.
class AppConfig {
  final String packageName;
  final String? customName;
  final bool isHidden;
  final bool isDistraction;

  const AppConfig({
    required this.packageName,
    this.customName,
    this.isHidden = false,
    this.isDistraction = false,
  });

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    return AppConfig(
      packageName: map['packageName'] as String? ?? '',
      customName: map['customName'] as String?,
      isHidden: map['isHidden'] as bool? ?? false,
      isDistraction: map['isDistraction'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'customName': customName,
      'isHidden': isHidden,
      'isDistraction': isDistraction,
    };
  }

  AppConfig copyWith({
    String? packageName,
    String? customName,
    bool? isHidden,
    bool? isDistraction,
    bool clearCustomName = false,
  }) {
    return AppConfig(
      packageName: packageName ?? this.packageName,
      customName: clearCustomName ? null : (customName ?? this.customName),
      isHidden: isHidden ?? this.isHidden,
      isDistraction: isDistraction ?? this.isDistraction,
    );
  }

  /// Display name: custom name if set, otherwise original.
  String displayName(String originalName) {
    if (customName != null && customName!.trim().isNotEmpty) {
      return customName!.trim();
    }
    return originalName;
  }
}
