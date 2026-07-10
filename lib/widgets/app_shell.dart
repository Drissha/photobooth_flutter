import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/controller/app_controller.dart';
import 'app_widgets.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final selectedIndex = _indexForLocation(location);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 960;
          if (isWide) {
            return Row(
              children: [
                SizedBox(
                  width: 290,
                  child: _Sidebar(
                    selectedIndex: selectedIndex,
                    controller: controller,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: child,
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _MobileHeader(controller: controller),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: child,
                ),
              ),
              _BottomNav(selectedIndex: selectedIndex),
            ],
          );
        },
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/live-view')) {
      return 1;
    }
    if (location.startsWith('/gallery')) {
      return 2;
    }
    if (location.startsWith('/settings')) {
      return 3;
    }
    if (location.startsWith('/diagnostic')) {
      return 4;
    }
    if (location.startsWith('/support')) {
      return 5;
    }
    return 0;
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedIndex,
    required this.controller,
  });

  final int selectedIndex;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B1324), Color(0xFF111C33)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(right: BorderSide(color: Color(0x1FFFFFFF))),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(24),
              child: AppTitleBlock(
                title: 'Studio DSLR Control',
                subtitle: 'Production dashboard for studio operators',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: StatusBanner(
                title: controller.cameraStatusLabel,
                subtitle: controller.cameraSnapshot.cameraName,
                isPositive: controller.cameraSnapshot.connectionState.name ==
                    'connected',
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: NavigationRail(
                selectedIndex: selectedIndex,
                extended: true,
                backgroundColor: Colors.transparent,
                leading: const SizedBox(height: 4),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.camera_outlined),
                    selectedIcon: Icon(Icons.camera),
                    label: Text('Live View'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.photo_library_outlined),
                    selectedIcon: Icon(Icons.photo_library),
                    label: Text('Gallery'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.medical_information_outlined),
                    selectedIcon: Icon(Icons.medical_information),
                    label: Text('Diagnostic'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.support_agent_outlined),
                    selectedIcon: Icon(Icons.support_agent),
                    label: Text('Support'),
                  ),
                ],
                onDestinationSelected: (index) {
                  _goToIndex(context, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToIndex(BuildContext context, int index) {
    context.go(const [
      '/dashboard',
      '/live-view',
      '/gallery',
      '/settings',
      '/diagnostic',
      '/support',
    ][index]);
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1324),
        border: Border(bottom: BorderSide(color: Color(0x1FFFFFFF))),
      ),
      child: Row(
        children: [
          const Expanded(
            child: AppTitleBlock(
              title: 'Studio DSLR Control',
              subtitle: 'Fast workflows for photo booth operators',
            ),
          ),
          StatusDot(
            isPositive:
                controller.cameraSnapshot.connectionState.name == 'connected',
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        context.go(
          const [
            '/dashboard',
            '/live-view',
            '/gallery',
            '/settings',
            '/diagnostic',
            '/support',
          ][index],
        );
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.camera_outlined),
          selectedIcon: Icon(Icons.camera),
          label: 'Live',
        ),
        NavigationDestination(
          icon: Icon(Icons.photo_library_outlined),
          selectedIcon: Icon(Icons.photo_library),
          label: 'Gallery',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
        NavigationDestination(
          icon: Icon(Icons.medical_information_outlined),
          selectedIcon: Icon(Icons.medical_information),
          label: 'Diag',
        ),
        NavigationDestination(
          icon: Icon(Icons.support_agent_outlined),
          selectedIcon: Icon(Icons.support_agent),
          label: 'Support',
        ),
      ],
    );
  }
}
