import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:minimal_launcher/core/services/native_bridge.dart';
import 'package:minimal_launcher/core/services/permission_service.dart';
import 'package:minimal_launcher/core/services/storage_service.dart';
import 'package:minimal_launcher/features/apps/models/app_info.dart';
import 'package:minimal_launcher/features/apps/controllers/apps_controller.dart';
import 'package:minimal_launcher/features/apps/services/native_app_service.dart';
import 'package:minimal_launcher/features/apps/services/app_config_service.dart';
import 'package:minimal_launcher/features/onboarding/services/onboarding_service.dart';
import 'package:minimal_launcher/features/onboarding/views/onboarding_view.dart';
import '../helpers/test_helpers.dart';
import '../unit/onboarding/permission_service_test.dart';

class FakeNativeAppService extends GetxService implements NativeAppService {
  @override
  Future<List<AppInfo>> getInstalledApps({bool forceRefresh = false}) async => [
        const AppInfo(name: 'Instagram', packageName: 'com.instagram.android'),
        const AppInfo(name: 'YouTube', packageName: 'com.google.android.youtube'),
        const AppInfo(name: 'Settings', packageName: 'com.android.settings', isSystemApp: true),
      ];

  @override
  Future<bool> launchApp(
    String packageName, {
    int? userSerial,
    String? activityName,
  }) async => true;

  @override
  Future<bool> isAppInstalled(String packageName) async => true;

  @override
  void invalidateCache() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late MockNativeBridge mockNativeBridge;
  late PermissionService permissionService;
  late OnboardingService onboardingService;
  late AppConfigService appConfigService;
  late FakeNativeAppService nativeAppService;
  late AppsController appsController;

  setUp(() async {
    Get.reset();
    await setupTestStorage();
    storage = StorageService();
    await storage.init();
    Get.put<StorageService>(storage);

    mockNativeBridge = MockNativeBridge();
    Get.put<NativeBridge>(mockNativeBridge);

    permissionService = PermissionService();
    Get.put<PermissionService>(permissionService);

    onboardingService = OnboardingService();
    Get.put<OnboardingService>(onboardingService);

    appConfigService = AppConfigService();
    Get.put<AppConfigService>(appConfigService);

    nativeAppService = FakeNativeAppService();
    Get.put<NativeAppService>(nativeAppService);

    appsController = AppsController();
    Get.put<AppsController>(appsController);
    await appsController.loadApps();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('OnboardingView renders welcome page and advances on Get Started tap',
      (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: OnboardingView(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Welcome text
    expect(find.text('Take back control of your phone.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Tap Get Started
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Step 2: How It Works should appear
    expect(find.text('How it works.'), findsOneWidget);
    expect(find.text('Choose distracting apps'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Tap Back in header
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Should return to Welcome page
    expect(find.text('Take back control of your phone.'), findsOneWidget);
  });

  testWidgets('Step 3 distraction apps page renders with installed apps without GetX errors',
      (tester) async {
    appsController.allApps.assignAll([
      const AppInfo(name: 'Instagram', packageName: 'com.instagram.android'),
      const AppInfo(name: 'YouTube', packageName: 'com.google.android.youtube'),
      const AppInfo(name: 'Settings', packageName: 'com.android.settings', isSystemApp: true),
    ]);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: OnboardingView(),
      ),
    );
    await tester.pumpAndSettle();

    // Welcome -> Step 2
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Step 2 -> Step 3 (Distraction Apps)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verify Step 3 rendered
    expect(find.text('Select distraction apps.'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    // System app 'Settings' should be excluded
    expect(find.text('Settings'), findsNothing);

    // Tap Instagram to select
    await tester.tap(find.text('Instagram'));
    await tester.pumpAndSettle();

    // Verify selection subtitle
    expect(find.text('1 app selected as distraction'), findsOneWidget);
  });
}
