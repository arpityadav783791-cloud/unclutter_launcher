import 'package:get/get.dart';
import '../controllers/launcher_controller.dart';

class LauncherBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LauncherController>(() => LauncherController());
  }
}
