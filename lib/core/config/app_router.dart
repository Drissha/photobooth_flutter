import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/camera/presentation/live_view_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/diagnostic/presentation/diagnostic_page.dart';
import '../../features/gallery/presentation/gallery_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../features/support/presentation/support_page.dart';
import '../../widgets/app_shell.dart';
import '../controller/app_controller.dart';

GoRouter buildAppRouter(AppController controller) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: controller,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (!controller.bootstrapped && location != '/') {
        return '/';
      }
      if (controller.bootstrapped && location == '/') {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/live-view',
            builder: (context, state) => const LiveViewPage(),
          ),
          GoRoute(
            path: '/gallery',
            builder: (context, state) => const GalleryPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/diagnostic',
            builder: (context, state) => const DiagnosticPage(),
          ),
          GoRoute(
            path: '/support',
            builder: (context, state) => const SupportPage(),
          ),
        ],
      ),
    ],
  );
}

AppController appControllerOf(BuildContext context) {
  return context.read<AppController>();
}
