import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/features/apps/controllers/apps_controller.dart';
import 'package:minimal_launcher/features/apps/models/app_info.dart';
import 'package:minimal_launcher/features/apps/services/app_config_service.dart';
import 'package:minimal_launcher/features/apps/services/native_app_service.dart';
import 'package:minimal_launcher/features/search/controllers/search_controller.dart';

class FakeNativeAppService extends NativeAppService {
  @override
  Future<List<AppInfo>> getInstalledApps({bool forceRefresh = false}) async => [];
}

class FakeAppConfigService extends GetxService implements AppConfigService {
  @override
  bool isHidden(String packageName) => false;

  @override
  String displayName(String packageName, String originalName) => originalName;

  @override
  Future<List<String>> autoDetectDistractions(List<AppInfo> apps) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppSearchController searchController;
  late AppsController appsController;

  setUp(() {
    Get.reset();
    Get.put<NativeAppService>(FakeNativeAppService());
    Get.put<AppConfigService>(FakeAppConfigService());
    appsController = Get.put<AppsController>(AppsController());

    appsController.allApps.assignAll([
      const AppInfo(name: 'Pokémon GO', packageName: 'com.nianticlabs.pokemongo'),
      const AppInfo(name: 'Whats-App', packageName: 'com.whatsapp'),
      const AppInfo(name: 'Camera', packageName: 'com.android.camera'),
      const AppInfo(name: 'Pro Camera', packageName: 'com.pro.camera'),
      const AppInfo(name: 'Settings', packageName: 'com.android.settings'),
    ]);
    appsController.apps.assignAll(appsController.allApps);

    searchController = Get.put<AppSearchController>(AppSearchController());
  });

  test('search matches accented app name with unaccented query', () {
    searchController.onQueryChanged('pokemon');
    expect(searchController.results.length, equals(1));
    expect(searchController.results.first.name, equals('Pokémon GO'));
  });

  test('search matches hyphenated app name with clean query', () {
    searchController.onQueryChanged('whatsapp');
    expect(searchController.results.length, equals(1));
    expect(searchController.results.first.name, equals('Whats-App'));
  });

  test('search ranks prefix match above word match', () {
    searchController.onQueryChanged('camera');
    expect(searchController.results.length, equals(2));
    expect(searchController.results[0].name, equals('Camera'));
    expect(searchController.results[1].name, equals('Pro Camera'));
  });

  test('empty query clears results', () {
    searchController.onQueryChanged('camera');
    expect(searchController.results.isNotEmpty, isTrue);

    searchController.onQueryChanged('');
    expect(searchController.results.isEmpty, isTrue);
  });
}
