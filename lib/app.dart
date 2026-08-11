import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/controllers/settings_controller.dart';

class MinimalLauncherApp extends StatelessWidget {
  const MinimalLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    // SettingsController may not be ready on first frame
    final settingsController = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : null;

    return Obx(() {
      final themeMode = settingsController?.flutterThemeMode ?? ThemeMode.system;
      final textScale = settingsController?.textScale.value ?? 1.0;

      return GetMaterialApp.router(
        title: 'Minimal Launcher',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerDelegate: AppRouter.router.routerDelegate,
        routeInformationParser: AppRouter.router.routeInformationParser,
        routeInformationProvider: AppRouter.router.routeInformationProvider,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      );
    });
  }
}
