import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/native_bridge.dart';
import 'package:minimal_launcher/features/apps/controllers/apps_controller.dart';
import 'package:minimal_launcher/features/apps/models/app_info.dart';
import 'package:minimal_launcher/features/apps/services/app_config_service.dart';
import 'package:minimal_launcher/features/apps/services/native_app_service.dart';

class TestNativeAppService extends NativeAppService {
  int getInstalledAppsCallCount = 0;
  bool cacheInvalidated = false;

  @override
  Future<List<AppInfo>> getInstalledApps({bool forceRefresh = false}) async {
    getInstalledAppsCallCount++;
    return [
      const AppInfo(
        name: 'Test App',
        packageName: 'com.test.app',
      ),
    ];
  }

  @override
  void invalidateCache() {
    cacheInvalidated = true;
    super.invalidateCache();
  }
}

class TestAppConfigService extends GetxService implements AppConfigService {
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

  const channel = MethodChannel('com.minimal.launcher/native');

  setUp(() {
    Get.reset();
  });

  test('NativeBridge dispatches onPackagesChanged callback on native invocation', () async {
    final bridge = NativeBridge();
    bridge.onInit();

    String? changedPackage;
    String? changedAction;

    bridge.onPackagesChanged = (pkg, action) {
      changedPackage = pkg;
      changedAction = action;
    };

    final binding = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const codec = StandardMethodCodec();
    final data = codec.encodeMethodCall(
      const MethodCall('onPackagesChanged', {
        'packageName': 'com.example.newapp',
        'action': 'android.intent.action.PACKAGE_ADDED',
      }),
    );

    await binding.handlePlatformMessage(
      'com.minimal.launcher/native',
      data,
      (ByteData? reply) {},
    );

    expect(changedPackage, equals('com.example.newapp'));
    expect(changedAction, equals('android.intent.action.PACKAGE_ADDED'));
  });

  test('AppsController invalidates cache and reloads apps on onPackagesChanged event', () async {
    final bridge = NativeBridge();
    Get.put<NativeBridge>(bridge);

    final mockNativeAppService = TestNativeAppService();
    Get.put<NativeAppService>(mockNativeAppService);

    final mockConfigService = TestAppConfigService();
    Get.put<AppConfigService>(mockConfigService);

    final controller = AppsController();
    Get.put<AppsController>(controller);

    // Initial load
    expect(mockNativeAppService.getInstalledAppsCallCount, equals(1));
    expect(mockNativeAppService.cacheInvalidated, isFalse);

    // Simulate package added
    bridge.onPackagesChanged?.call('com.example.newapp', 'android.intent.action.PACKAGE_ADDED');

    expect(mockNativeAppService.cacheInvalidated, isTrue);
    expect(mockNativeAppService.getInstalledAppsCallCount, equals(2));
  });

  test('NativeBridge accessibility checks invoke native channel correctly', () async {
    final binding = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    binding.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'isAccessibilityServiceEnabled') {
        return true;
      }
      if (methodCall.method == 'openAccessibilitySettings') {
        return null;
      }
      return null;
    });

    final bridge = NativeBridge();
    bridge.onInit();

    final isEnabled = await bridge.isAccessibilityServiceEnabled();
    expect(isEnabled, isTrue);

    await bridge.openAccessibilitySettings();
    // Verify no exception thrown
  });
}
