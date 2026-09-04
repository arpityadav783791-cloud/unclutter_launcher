import 'package:flutter/foundation.dart';

/// Represents an Android Pinned Shortcut (PWA, contact, deep link)
/// pinned by the user to the home screen or launcher apps list.
@immutable
class PinnedShortcut {
  final String id;
  final String packageName;
  final String label;
  final int userSerial;
  final bool isEnabled;

  const PinnedShortcut({
    required this.id,
    required this.packageName,
    required this.label,
    this.userSerial = 0,
    this.isEnabled = true,
  });

  /// Unique composite key avoiding collisions across packages and users
  String get shortcutKey => 'shortcut:$packageName:$id:$userSerial';

  factory PinnedShortcut.fromMap(Map<dynamic, dynamic> map) {
    return PinnedShortcut(
      id: map['id'] as String? ?? '',
      packageName: map['packageName'] as String? ?? '',
      label: map['label'] as String? ?? (map['id'] as String? ?? ''),
      userSerial: (map['userSerial'] as num?)?.toInt() ?? 0,
      isEnabled: map['isEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageName': packageName,
      'label': label,
      'userSerial': userSerial,
      'isEnabled': isEnabled,
    };
  }

  PinnedShortcut copyWith({
    String? id,
    String? packageName,
    String? label,
    int? userSerial,
    bool? isEnabled,
  }) {
    return PinnedShortcut(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      label: label ?? this.label,
      userSerial: userSerial ?? this.userSerial,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PinnedShortcut &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          packageName == other.packageName &&
          userSerial == other.userSerial;

  @override
  int get hashCode => id.hashCode ^ packageName.hashCode ^ userSerial.hashCode;

  @override
  String toString() =>
      'PinnedShortcut(id: $id, pkg: $packageName, label: $label, user: $userSerial)';
}
