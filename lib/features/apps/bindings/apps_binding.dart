import 'package:get/get.dart';
import '../controllers/apps_controller.dart';
import '../services/native_app_service.dart';

class AppsBinding extends Bindings {
  @override
  void dependencies() {
    // Service is a singleton
    if (!Get.isRegistered<NativeAppService>()) {
      Get.put<NativeAppService>(NativeAppService(), permanent: true);
    }

    Get.lazyPut<AppsController>(() => AppsController());
  }
}
