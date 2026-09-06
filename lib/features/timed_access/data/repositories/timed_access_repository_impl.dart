import 'dart:convert';
import 'package:get/get.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/entities/timed_access_session.dart';
import '../../domain/repositories/timed_access_repository.dart';
import '../models/timed_access_session_model.dart';

class TimedAccessRepositoryImpl implements TimedAccessRepository {
  static const String _storageKey = 'active_timed_access_session';
  final StorageService _storageService;

  TimedAccessRepositoryImpl({StorageService? storageService})
      : _storageService = storageService ??
            (Get.isRegistered<StorageService>()
                ? Get.find<StorageService>()
                : StorageService());

  @override
  Future<TimedAccessSession?> getActiveSession() async {
    final raw = _storageService.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await clearSession();
        return null;
      }
      final model = TimedAccessSessionModel.tryFromMap(decoded);
      if (model == null) {
        await clearSession();
        return null;
      }
      return model;
    } catch (_) {
      // Corrupt data safely discarded
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> saveSession(TimedAccessSession session) async {
    final model = TimedAccessSessionModel.fromEntity(session);
    final raw = jsonEncode(model.toMap());
    await _storageService.setString(_storageKey, raw);
  }

  @override
  Future<void> updateSession(TimedAccessSession session) async {
    await saveSession(session);
  }

  @override
  Future<void> clearSession() async {
    await _storageService.remove(_storageKey);
  }
}
