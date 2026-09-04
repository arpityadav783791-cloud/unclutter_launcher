import 'package:get/get.dart';
import '../../apps/models/app_info.dart';
import '../../apps/controllers/apps_controller.dart';
import '../services/favorites_service.dart';

class FavoritesController extends GetxController {
  final FavoritesService _favoritesService = Get.find<FavoritesService>();
  final AppsController _appsController = Get.find<AppsController>();

  final RxList<AppInfo> favoriteApps = <AppInfo>[].obs;

  Worker? _appsWorker;

  @override
  void onInit() {
    super.onInit();
    // React only when the visible apps list actually changes
    _appsWorker = ever(_appsController.apps, (_) => rebuildFavorites());
    rebuildFavorites();
  }

  void rebuildFavorites() {
    final favPackages = _favoritesService.getFavorites();
    final visibleApps = _appsController.apps;

    final result = <AppInfo>[];
    for (final fav in favPackages) {
      for (final app in visibleApps) {
        if (app.uniqueKey == fav.packageName ||
            app.packageName == fav.packageName) {
          result.add(app);
          break;
        }
      }
    }

    // Avoid unnecessary assignAll if identical
    if (result.length == favoriteApps.length) {
      bool same = true;
      for (var i = 0; i < result.length; i++) {
        if (result[i] != favoriteApps[i]) {
          same = false;
          break;
        }
      }
      if (same) return;
    }

    favoriteApps.assignAll(result);
  }

  Future<void> addFavorite(String packageName) async {
    await _favoritesService.addFavorite(packageName);
    rebuildFavorites();
  }

  Future<void> removeFavorite(String packageName) async {
    await _favoritesService.removeFavorite(packageName);
    rebuildFavorites();
  }

  Future<void> toggleFavorite(String packageName) async {
    await _favoritesService.toggleFavorite(packageName);
    rebuildFavorites();
  }

  bool isFavorite(String packageName) {
    return _favoritesService.isFavorite(packageName);
  }

  Future<void> moveUp(String packageName) async {
    final current = _favoritesService.getFavorites();
    final index = current.indexWhere((f) => f.packageName == packageName);
    if (index <= 0) return;
    await _favoritesService.reorder(packageName, index - 1);
    rebuildFavorites();
  }

  Future<void> moveDown(String packageName) async {
    final current = _favoritesService.getFavorites();
    final index = current.indexWhere((f) => f.packageName == packageName);
    if (index == -1 || index >= current.length - 1) return;
    await _favoritesService.reorder(packageName, index + 1);
    rebuildFavorites();
  }

  @override
  void onClose() {
    _appsWorker?.dispose();
    super.onClose();
  }
}
