import '../../domain/entities/timed_access_session.dart';
import '../../domain/entities/timed_access_status.dart';

class TimedAccessSessionModel extends TimedAccessSession {
  const TimedAccessSessionModel({
    required super.id,
    required super.packageName,
    required super.startedAt,
    required super.expiresAt,
    required super.status,
  });

  factory TimedAccessSessionModel.fromEntity(TimedAccessSession entity) {
    return TimedAccessSessionModel(
      id: entity.id,
      packageName: entity.packageName,
      startedAt: entity.startedAt,
      expiresAt: entity.expiresAt,
      status: entity.status,
    );
  }

  /// Parses session from Map safely. Returns null if essential fields are corrupt/missing.
  static TimedAccessSessionModel? tryFromMap(dynamic map) {
    if (map == null || map is! Map) return null;
    try {
      final id = map['id']?.toString() ?? '';
      final packageName = map['packageName']?.toString() ?? '';
      final startedAtMs = map['startedAt'] as num?;
      final expiresAtMs = map['expiresAt'] as num?;

      if (id.isEmpty || packageName.isEmpty || startedAtMs == null || expiresAtMs == null) {
        return null;
      }
      if (startedAtMs <= 0 || expiresAtMs <= 0) {
        return null;
      }

      final statusStr = map['status']?.toString();
      final status = TimedAccessStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => TimedAccessStatus.none,
      );

      return TimedAccessSessionModel(
        id: id,
        packageName: packageName,
        startedAt: DateTime.fromMillisecondsSinceEpoch(startedAtMs.toInt()),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAtMs.toInt()),
        status: status,
      );
    } catch (_) {
      return null;
    }
  }

  factory TimedAccessSessionModel.fromMap(Map<String, dynamic> map) {
    final parsed = tryFromMap(map);
    if (parsed == null) {
      throw const FormatException('Invalid or corrupt TimedAccessSession data');
    }
    return parsed;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageName': packageName,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'status': status.name,
    };
  }
}
