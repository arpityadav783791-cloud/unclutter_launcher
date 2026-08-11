import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/launcher_controller.dart';
import '../widgets/launcher_app_list.dart';
import '../widgets/launcher_clock.dart';
import '../widgets/launcher_date.dart';

class LauncherScreen extends GetView<LauncherController> {
  const LauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: LauncherClock()),

              const SizedBox(height: 4),

              const Center(child: LauncherDate()),

              const SizedBox(height: 48),

              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: Text('Loading...', style: TextStyle(fontSize: 18)),
                    );
                  }

                  if (controller.errorMessage.value.isNotEmpty) {
                    return Center(
                      child: Text(
                        controller.errorMessage.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  if (controller.apps.isEmpty) {
                    return const Center(
                      child: Text(
                        'No apps found',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  return LauncherAppList(apps: controller.apps);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
