import 'camera_models.dart';

class DiagnosticCheck {
  const DiagnosticCheck({
    required this.title,
    required this.level,
    required this.detail,
    required this.solution,
  });

  final String title;
  final HealthLevel level;
  final String detail;
  final String solution;
}

class StartupReport {
  const StartupReport({
    required this.ready,
    required this.checks,
  });

  final bool ready;
  final List<DiagnosticCheck> checks;
}

class SupportInformation {
  const SupportInformation({
    required this.appVersion,
    required this.sdkVersion,
    required this.windowsVersion,
    required this.cameraName,
    required this.cameraSerialNumber,
    required this.storageFolder,
    required this.connectionState,
  });

  final String appVersion;
  final String sdkVersion;
  final String windowsVersion;
  final String cameraName;
  final String cameraSerialNumber;
  final String storageFolder;
  final CameraConnectionState connectionState;
}
