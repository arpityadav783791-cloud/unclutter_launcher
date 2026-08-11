import 'package:get/get.dart';

import '../../features/apps/services/native_app_service.dart';
import '../../features/launcher/controllers/launcher_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NativeAppService>(() => NativeAppService(), fenix: true);

    Get.lazyPut<LauncherController>(
      () => LauncherController(nativeAppService: Get.find<NativeAppService>()),
      fenix: true,
    );
  }
}
