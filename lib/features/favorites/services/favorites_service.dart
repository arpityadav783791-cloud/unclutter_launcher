import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../models/favorite_app.dart';

class FavoritesService extends GetxService {
  static const String _key = 'favorite_apps';
  final StorageService _storage = Get.find<StorageService>();

  List<FavoriteApp> getFavorites() {
    final raw = _storage.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final favorites = list
          .map((e) => FavoriteApp.fromMap(Map<String, dynamic>.from(e as Map)))
          .where((f) => f.packageName.isNotEmpty)
          .toList();
      favorites.sort((a, b) => a.order.compareTo(b.order));
      return favorites;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFavorites(List<FavoriteApp> favorites) async {
    // Normalize order
    final normalized = <FavoriteApp>[];
    for (var i = 0; i < favorites.length; i++) {
      normalized.add(favorites[i].copyWith(order: i));
    }
    final encoded = jsonEncode(normalized.map((e) => e.toMap()).toList());
    await _storage.setString(_key, encoded);
  }

  Future<void> addFavorite(String packageName) async {
    final current = getFavorites();
    if (current.any((f) => f.packageName == packageName)) return;

    current.add(FavoriteApp(
      packageName: packageName,
      order: current.length,
    ));
    await saveFavorites(current);
  }

  Future<void> removeFavorite(String packageName) async {
    final current = getFavorites();
    current.removeWhere((f) => f.packageName == packageName);
    await saveFavorites(current);
  }

  Future<void> toggleFavorite(String packageName) async {
    if (isFavorite(packageName)) {
      await removeFavorite(packageName);
    } else {
      await addFavorite(packageName);
    }
  }

  bool isFavorite(String packageName) {
    return getFavorites().any((f) => f.packageName == packageName);
  }

  /// Move a favorite up or down in the list
  Future<void> reorder(String packageName, int newIndex) async {
    final current = getFavorites();
    final oldIndex = current.indexWhere((f) => f.packageName == packageName);
    if (oldIndex == -1 || newIndex < 0 || newIndex >= current.length) return;

    final item = current.removeAt(oldIndex);
    current.insert(newIndex, item);
    await saveFavorites(current);
  }
}
