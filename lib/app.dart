import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_router.dart';
import 'core/controller/app_controller.dart';
import 'core/logger/app_logger_service.dart';
import 'core/repositories/camera_repository.dart';
import 'core/repositories/diagnostic_repository.dart';
import 'core/repositories/settings_repository.dart';
import 'core/services/camera_service.dart';
import 'core/services/diagnostic_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/system_service.dart';
import 'core/theme/app_theme.dart';

class PhotoboothApp extends StatelessWidget {
  const PhotoboothApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppLoggerService>(create: (_) => AppLoggerService()),
        Provider<SettingsService>(create: (_) => SettingsService()),
        Provider<SystemService>(create: (_) => SystemService()),
        Provider<CameraService>(
          create: (context) => MockCameraService(
            logger: context.read<AppLoggerService>(),
          ),
        ),
        Provider<DiagnosticService>(
          create: (context) => DiagnosticService(
            logger: context.read<AppLoggerService>(),
            systemService: context.read<SystemService>(),
            cameraService: context.read<CameraService>(),
            settingsService: context.read<SettingsService>(),
          ),
        ),
        Provider<SettingsRepository>(
          create: (context) => SettingsRepository(
            service: context.read<SettingsService>(),
            logger: context.read<AppLoggerService>(),
          ),
        ),
        Provider<CameraRepository>(
          create: (context) => CameraRepository(
            service: context.read<CameraService>(),
            logger: context.read<AppLoggerService>(),
          ),
        ),
        Provider<DiagnosticRepository>(
          create: (context) => DiagnosticRepository(
            service: context.read<DiagnosticService>(),
            logger: context.read<AppLoggerService>(),
          ),
        ),
        ChangeNotifierProvider<AppController>(
          create: (context) => AppController(
            logger: context.read<AppLoggerService>(),
            settingsRepository: context.read<SettingsRepository>(),
            cameraRepository: context.read<CameraRepository>(),
            diagnosticRepository: context.read<DiagnosticRepository>(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final controller = context.watch<AppController>();
          final router = buildAppRouter(controller);

          return MaterialApp.router(
            title: 'Studio DSLR Control',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
