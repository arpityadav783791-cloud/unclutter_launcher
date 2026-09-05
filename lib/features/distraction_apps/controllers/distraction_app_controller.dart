import 'package:get/get.dart';
import '../../apps/controllers/apps_controller.dart';
import '../../apps/models/app_info.dart';
import '../models/distraction_app.dart';
import '../services/distraction_app_service.dart';

/// Controller coordinating distraction application states, UI lists,
/// user additions, toggles, and searching.
class DistractionAppController extends GetxController {
  final DistractionAppService _service = Get.find<DistractionAppService>();

  final RxList<DistractionApp> distractionApps = <DistractionApp>[].obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    refreshList();
  }

  /// Reloads the tracked distraction list from all installed applications.
  void refreshList() {
    if (!Get.isRegistered<AppsController>()) return;
    final appsController = Get.find<AppsController>();
    final all = appsController.allApps;

    distractionApps.assignAll(_service.getDistractionApps(all));
  }

  /// Toggles an app between enabled (distraction rules enforced) and disabled (normal launch).
  Future<void> toggleApp(String packageName) async {
    final current = distractionApps.firstWhereOrNull((a) => a.packageName == packageName);
    final newState = current != null ? !current.isEnabled : true;

    await _service.toggleDistraction(packageName, enable: newState);
    refreshList();
  }

  /// Manually adds an application from the installed apps list.
  Future<void> addApp(String packageName) async {
    await _service.addManualDistraction(packageName);
    refreshList();
  }

  /// Removes an application from the active distraction list.
  Future<void> removeApp(String packageName) async {
    await _service.removeDistraction(packageName);
    refreshList();
  }

  /// Returns true if the package is currently an active distraction.
  bool isDistraction(String packageName) {
    return _service.isDistraction(packageName);
  }

  /// Available candidate apps that can be added (not currently active distractions).
  List<AppInfo> get candidateApps {
    if (!Get.isRegistered<AppsController>()) return [];
    final appsController = Get.find<AppsController>();
    final all = appsController.allApps;
    final currentPackages = distractionApps.map((a) => a.packageName).toSet();
    final query = searchQuery.value.trim().toLowerCase();

    return all.where((app) {
      if (app.packageName == 'com.minimal.launcher.settings') return false;
      if (currentPackages.contains(app.packageName)) return false;
      if (query.isNotEmpty) {
        final matchName = app.name.toLowerCase().contains(query);
        final matchPkg = app.packageName.toLowerCase().contains(query);
        return matchName || matchPkg;
      }
      return true;
    }).toList();
  }
}
