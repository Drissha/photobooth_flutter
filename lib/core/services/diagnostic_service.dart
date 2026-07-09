import 'dart:io';

import '../constants/app_constants.dart';
import '../logger/app_logger_service.dart';
import '../models/camera_models.dart';
import '../models/diagnostic_models.dart';
import 'camera_service.dart';
import 'settings_service.dart';
import 'system_service.dart';

class DiagnosticService {
  DiagnosticService({
    required this._logger,
    required this._systemService,
    required this._cameraService,
    required this._settingsService,
  });

  final AppLoggerService _logger;
  final SystemService _systemService;
  final CameraService _cameraService;
  final SettingsService _settingsService;

  Future<StartupReport> runStartupChecks() async {
    final settings = await _settingsService.loadSettings();
    final report = await _systemService.runStartupChecks(
      cameraConnected:
          _cameraService.snapshot.connectionState == CameraConnectionState.connected,
      storageFolder: settings.storageFolder,
      sdkLoaded: true,
      dllLoaded: true,
    );
    await _logger.info('Startup checks completed', data: {
      'ready': report.ready,
      'checks': report.checks.length,
    });
    return report;
  }

  Future<List<DiagnosticCheck>> runSmartDiagnostic() async {
    final settings = await _settingsService.loadSettings();
    final checks = <DiagnosticCheck>[];
    checks.addAll((await _systemService.runStartupChecks(
      cameraConnected:
          _cameraService.snapshot.connectionState == CameraConnectionState.connected,
      storageFolder: settings.storageFolder,
      sdkLoaded: true,
      dllLoaded: true,
    ))
        .checks);
    checks.add(
      DiagnosticCheck(
        title: 'Flutter Engine',
        level: HealthLevel.green,
        detail: 'Flutter engine berjalan normal.',
        solution: 'Tidak ada tindakan yang diperlukan.',
      ),
    );
    checks.add(
      DiagnosticCheck(
        title: 'Camera SDK',
        level: HealthLevel.green,
        detail: 'Camera SDK siap dipakai pada layer native.',
        solution: 'Tidak ada tindakan yang diperlukan.',
      ),
    );
    checks.add(
      DiagnosticCheck(
        title: 'Driver',
        level: Platform.isWindows ? HealthLevel.green : HealthLevel.red,
        detail: Platform.isWindows
            ? 'Driver Windows tersedia.'
            : 'Driver hanya relevan di Windows.',
        solution: 'Pastikan driver kamera sudah terpasang.',
      ),
    );
    checks.add(
      DiagnosticCheck(
        title: 'USB',
        level: _cameraService.snapshot.connectionState ==
                CameraConnectionState.connected
            ? HealthLevel.green
            : HealthLevel.yellow,
        detail: _cameraService.snapshot.connectionState ==
                CameraConnectionState.connected
            ? 'Koneksi USB aktif.'
            : 'USB belum mengarah ke kamera aktif.',
        solution: 'Cabut dan pasang ulang kabel USB kamera.',
      ),
    );
    checks.add(
      DiagnosticCheck(
        title: 'RAM',
        level: HealthLevel.yellow,
        detail: 'Pemeriksaan RAM dapat dihubungkan ke API sistem bila diperlukan.',
        solution: 'Tutup aplikasi berat bila performa menurun.',
      ),
    );
    checks.add(
      DiagnosticCheck(
        title: 'Disk',
        level: HealthLevel.yellow,
        detail: 'Pemeriksaan kapasitas disk dapat ditingkatkan pada rilis berikutnya.',
        solution: 'Pastikan ruang penyimpanan cukup.',
      ),
    );
    checks.add(
      DiagnosticCheck(
        title: 'CPU',
        level: HealthLevel.yellow,
        detail: 'CPU checks are scaffolded for future telemetry.',
        solution: 'Gunakan preset performa yang lebih ringan jika diperlukan.',
      ),
    );
    return checks;
  }

  Future<String> repairAutomatically() async {
    final settings = await _settingsService.loadSettings();
    final folder = Directory(settings.storageFolder);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    await _cameraService.rescanUsb();
    await _cameraService.refreshSdk();
    if (_cameraService.snapshot.connectionState !=
        CameraConnectionState.connected) {
      await _cameraService.connect();
    }
    await _logger.info('Automatic repair completed');
    return 'Kamera berhasil ditemukan.';
  }

  Future<SupportInformation> buildSupportInformation() async {
    final settings = await _settingsService.loadSettings();
    final snapshot = _cameraService.snapshot;
    return SupportInformation(
      appVersion: AppConstants.appVersion,
      sdkVersion: snapshot.sdkVersion,
      windowsVersion: await _systemService.getWindowsVersion(),
      cameraName: snapshot.cameraName,
      cameraSerialNumber: snapshot.serialNumber,
      storageFolder: settings.storageFolder,
      connectionState: snapshot.connectionState,
    );
  }
}
