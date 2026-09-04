import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/features/apps/controllers/apps_controller.dart';
import 'package:minimal_launcher/features/apps/models/app_info.dart';
import 'package:minimal_launcher/features/apps/services/app_config_service.dart';
import 'package:minimal_launcher/features/apps/services/native_app_service.dart';
import 'package:minimal_launcher/features/favorites/controllers/favorites_controller.dart';
import 'package:minimal_launcher/features/favorites/models/favorite_app.dart';
import 'package:minimal_launcher/features/favorites/services/favorites_service.dart';

import 'package:minimal_launcher/core/services/storage_service.dart';
import '../../helpers/test_helpers.dart';

class FakeMultiUserAppService extends GetxService implements NativeAppService {
  List<AppInfo> mockApps = [];

  @override
  Future<List<AppInfo>> getInstalledApps({bool forceRefresh = false}) async =>
      mockApps;

  @override
  Future<bool> launchApp(
    String packageName, {
    int? userSerial,
    String? activityName,
  }) async =>
      true;

  @override
  Future<bool> isAppInstalled(String packageName) async => true;

  @override
  void invalidateCache() {}
}

class FakeFavoritesService extends GetxService implements FavoritesService {
  List<FavoriteApp> favs = [];

  @override
  List<FavoriteApp> getFavorites() => favs;

  @override
  Future<void> addFavorite(String packageName) async {
    favs.add(FavoriteApp(packageName: packageName, order: favs.length));
  }

  @override
  Future<void> removeFavorite(String packageName) async {
    favs.removeWhere((f) => f.packageName == packageName);
  }

  @override
  Future<void> toggleFavorite(String packageName) async {
    if (isFavorite(packageName)) {
      await removeFavorite(packageName);
    } else {
      await addFavorite(packageName);
    }
  }

  @override
  Future<void> saveFavorites(List<FavoriteApp> favorites) async {
    favs = List.from(favorites);
  }

  @override
  bool isFavorite(String packageName) =>
      favs.any((f) => f.packageName == packageName);

  @override
  Future<void> reorder(String packageName, int newIndex) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppInfo Multi-User Support', () {
    test('defaults are personal profile userSerial 0 and not work profile', () {
      const app = AppInfo(name: 'Chrome', packageName: 'com.android.chrome');
      expect(app.userSerial, 0);
      expect(app.isWorkProfile, false);
      expect(app.activityName, '');
      expect(app.uniqueKey, 'com.android.chrome');
    });

    test('uniqueKey appends userSerial for secondary/work profiles', () {
      const personal = AppInfo(
        name: 'Slack',
        packageName: 'com.Slack',
        userSerial: 0,
      );
      const work = AppInfo(
        name: 'Slack',
        packageName: 'com.Slack',
        userSerial: 10,
        isWorkProfile: true,
      );

      expect(personal.uniqueKey, 'com.Slack');
      expect(work.uniqueKey, 'com.Slack|10');
    });

    test('equality differentiates between personal and work profile instances',
        () {
      const personal = AppInfo(
        name: 'Slack',
        packageName: 'com.Slack',
        userSerial: 0,
      );
      const work = AppInfo(
        name: 'Slack',
        packageName: 'com.Slack',
        userSerial: 10,
        isWorkProfile: true,
      );
      const workDuplicate = AppInfo(
        name: 'Slack (Work)',
        packageName: 'com.Slack',
        userSerial: 10,
        isWorkProfile: true,
      );

      expect(personal == work, isFalse);
      expect(work == workDuplicate, isTrue);
      expect(personal.hashCode == work.hashCode, isFalse);
    });

    test('serialization round-trip preserves multi-user attributes', () {
      const original = AppInfo(
        name: 'Gmail',
        packageName: 'com.google.android.gm',
        userSerial: 12,
        isWorkProfile: true,
        activityName: 'com.google.android.gm.ConversationListActivityGmail',
        installTime: 1700000000000,
      );

      final map = original.toMap();
      final restored = AppInfo.fromMap(map);

      expect(restored.name, 'Gmail');
      expect(restored.packageName, 'com.google.android.gm');
      expect(restored.userSerial, 12);
      expect(restored.isWorkProfile, true);
      expect(restored.activityName,
          'com.google.android.gm.ConversationListActivityGmail');
      expect(restored.uniqueKey, 'com.google.android.gm|12');
      expect(restored, equals(original));
    });
  });

  group('FavoritesController - Multi-User Profile Resolution', () {
    late FakeMultiUserAppService fakeNativeApps;
    late FakeFavoritesService fakeFavService;

    setUp(() async {
      Get.reset();
      await setupTestStorage();
      await Get.putAsync(() => StorageService().init());
      fakeNativeApps = FakeMultiUserAppService();
      fakeFavService = FakeFavoritesService();

      Get.put<NativeAppService>(fakeNativeApps);
      Get.put<AppConfigService>(AppConfigService());
      Get.put<FavoritesService>(fakeFavService);
    });

    tearDown(() {
      Get.reset();
    });

    test('resolves personal and work versions of same package independently',
        () async {
      const personalSlack = AppInfo(
        name: 'Slack',
        packageName: 'com.Slack',
        userSerial: 0,
      );
      const workSlack = AppInfo(
        name: 'Slack',
        packageName: 'com.Slack',
        userSerial: 10,
        isWorkProfile: true,
      );

      fakeNativeApps.mockApps = [personalSlack, workSlack];
      final appsController = Get.put(AppsController());
      await appsController.loadApps();

      // Favorite work slack using unique key
      fakeFavService.favs = [
        const FavoriteApp(packageName: 'com.Slack|10', order: 0),
      ];

      final favoritesController = Get.put(FavoritesController());
      favoritesController.rebuildFavorites();

      expect(favoritesController.favoriteApps.length, 1);
      expect(favoritesController.favoriteApps.first.userSerial, 10);
      expect(favoritesController.favoriteApps.first.isWorkProfile, true);
    });
  });
}
