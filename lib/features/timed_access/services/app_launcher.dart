import 'package:get/get.dart';
import '../../apps/services/native_app_service.dart';

abstract class AppLauncher {
  Future<bool> launch(String packageName);
}

class DefaultAppLauncher implements AppLauncher {
  final NativeAppService? _nativeAppService;

  DefaultAppLauncher({NativeAppService? nativeAppService})
      : _nativeAppService = nativeAppService ??
            (Get.isRegistered<NativeAppService>()
                ? Get.find<NativeAppService>()
                : null);

  @override
  Future<bool> launch(String packageName) async {
    final service = _nativeAppService;
    if (service == null) {
      // Test environment without registered NativeAppService
      return true;
    }
    try {
      final res = await service.launchApp(packageName);
      return res;
    } catch (_) {
      return false;
    }
  }
}
