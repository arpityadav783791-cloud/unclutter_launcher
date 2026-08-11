class FavoriteApp {
  final String packageName;
  final int order;

  const FavoriteApp({
    required this.packageName,
    required this.order,
  });

  factory FavoriteApp.fromMap(Map<String, dynamic> map) {
    return FavoriteApp(
      packageName: map['packageName'] as String? ?? '',
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'order': order,
    };
  }

  FavoriteApp copyWith({String? packageName, int? order}) {
    return FavoriteApp(
      packageName: packageName ?? this.packageName,
      order: order ?? this.order,
    );
  }
}
