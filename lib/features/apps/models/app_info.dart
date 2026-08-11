class AppInfo {
  final String name;          // Original name from system
  final String packageName;
  final bool isSystemApp;

  const AppInfo({
    required this.name,
    required this.packageName,
    this.isSystemApp = false,
  });

  factory AppInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppInfo(
      name: map['name'] as String? ?? 'Unknown',
      packageName: map['packageName'] as String? ?? '',
      isSystemApp: map['isSystemApp'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'packageName': packageName,
      'isSystemApp': isSystemApp,
    };
  }

  @override
  String toString() => 'AppInfo(name: $name, package: $packageName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppInfo &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;
}
