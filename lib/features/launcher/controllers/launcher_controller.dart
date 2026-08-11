import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../apps/models/app_model.dart';
import '../../apps/services/native_app_service.dart';

class LauncherController extends GetxController {
  final NativeAppService _nativeAppService;

  LauncherController({required NativeAppService nativeAppService})
    : _nativeAppService = nativeAppService;

  final RxBool isLoading = false.obs;

  final RxList<AppModel> apps = <AppModel>[].obs;

  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();

    loadApps();
  }

  Future<void> loadApps() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final installedApps = await _nativeAppService.getInstalledApps();

      apps.assignAll(installedApps);
    } on PlatformException catch (e) {
      errorMessage.value = e.message ?? 'Unable to load installed apps.';
    } catch (e) {
      errorMessage.value = 'Unable to load installed apps.';
    } finally {
      isLoading.value = false;
    }
  }
}
