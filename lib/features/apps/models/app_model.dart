class AppModel {
  final String name;
  final String packageName;
  final bool isLaunchable;

  const AppModel({
    required this.name,
    required this.packageName,
    required this.isLaunchable,
  });

  AppModel copyWith({String? name, String? packageName, bool? isLaunchable}) {
    return AppModel(
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      isLaunchable: isLaunchable ?? this.isLaunchable,
    );
  }

  factory AppModel.fromMap(Map<dynamic, dynamic> map) {
    return AppModel(
      name: map['name'] as String? ?? '',
      packageName: map['packageName'] as String? ?? '',
      isLaunchable: map['isLaunchable'] as bool? ?? false,
    );
  }
}
