import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unclutter_launcher/core/routes/app_routes.dart';

import 'core/services/app_binding.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MinimalistLauncherApp());
}

class MinimalistLauncherApp extends StatelessWidget {
  const MinimalistLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp.router(
      debugShowCheckedModeBanner: false,

      title: 'Minimalist Launcher',

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      initialBinding: AppBinding(),

      routerDelegate: AppRouter.router.routerDelegate,
      routeInformationParser: AppRouter.router.routeInformationParser,
      routeInformationProvider: AppRouter.router.routeInformationProvider,
    );
  }
}
