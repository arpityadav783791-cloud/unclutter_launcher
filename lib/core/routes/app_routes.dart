import 'package:go_router/go_router.dart';

import '../../features/launcher/views/launcher_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',

    routes: [
      GoRoute(
        path: '/',
        name: 'launcher',
        builder: (context, state) {
          return const LauncherScreen();
        },
      ),
    ],
  );
}
