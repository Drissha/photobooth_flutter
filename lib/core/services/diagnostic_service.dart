import 'dart:io';

import '../constants/error_codes.dart';
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
    final sdkLoaded = await _systemService.isLibGPhoto2Available();
    final dllLoaded = await _systemService.isCameraEngineAvailable();
    final report = await _systemService.runStartupChecks(
      cameraConnected:
          _cameraService.snapshot.connectionState == CameraConnectionState.connected,
      storageFolder: settings.storageFolder,
      sdkLoaded: sdkLoaded,
      dllLoaded: dllLoaded,
    );
    await _logger.info('Startup checks completed', data: {
      'ready': report.ready,
      'checks': report.checks.length,
    });
    return report;
  }

  Future<List<DiagnosticCheck>> runSmartDiagnostic() async {
    final settings = await _settingsService.loadSettings();
    final sdkLoaded = await _systemService.isLibGPhoto2Available();
    final dllLoaded = await _systemService.isCameraEngineAvailable();
    final checks = <DiagnosticCheck>[];
    checks.addAll((await _systemService.runStartupChecks(
      cameraConnected:
          _cameraService.snapshot.connectionState == CameraConnectionState.connected,
      storageFolder: settings.storageFolder,
      sdkLoaded: sdkLoaded,
      dllLoaded: dllLoaded,
    ))
        .checks);
    checks.add(
      DiagnosticCheck(
        code: ErrorCodes.cam010,
        title: 'Flutter Engine',
        level: HealthLevel.green,
        detail: 'Flutter engine berjalan normal.',
        solution: 'Tidak ada tindakan yang diperlukan.',
      ),
    );
    checks.add(
      DiagnosticCheck(
        code: ErrorCodes.cam005,
        title: 'Webcam Backend',
        level: sdkLoaded ? HealthLevel.green : HealthLevel.red,
        detail: sdkLoaded
            ? 'Webcam backend siap dipakai pada layer native.'
            : 'Webcam backend belum ditemukan.',
        solution: sdkLoaded
            ? 'Tidak ada tindakan yang diperlukan.'
            : 'Pastikan backend capture Windows bisa dijalankan.',
        steps: const [
          DiagnosticStep(
            title: 'Langkah 1',
            detail: 'Tutup aplikasi lalu jalankan ulang.',
          ),
          DiagnosticStep(
            title: 'Langkah 2',
            detail: 'Pastikan webcam Windows terdeteksi dan binary capture tersedia.',
          ),
        ],
      ),
    );
    checks.add(
      DiagnosticCheck(
        code: ErrorCodes.cam008,
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
        code: ErrorCodes.cam003,
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
        code: ErrorCodes.cam010,
        title: 'RAM',
        level: HealthLevel.yellow,
        detail: 'Pemeriksaan RAM dapat dihubungkan ke API sistem bila diperlukan.',
        solution: 'Tutup aplikasi berat bila performa menurun.',
      ),
    );
    checks.add(
      DiagnosticCheck(
        code: ErrorCodes.cam010,
        title: 'Disk',
        level: HealthLevel.yellow,
        detail: 'Pemeriksaan kapasitas disk dapat ditingkatkan pada rilis berikutnya.',
        solution: 'Pastikan ruang penyimpanan cukup.',
      ),
    );
    checks.add(
      DiagnosticCheck(
        code: ErrorCodes.cam010,
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
    final issues = await runSmartDiagnostic();
    final dllIssue = issues.firstWhere(
      (issue) => issue.code == ErrorCodes.cam005 && issue.level == HealthLevel.red,
      orElse: () => const DiagnosticCheck(
        code: null,
        title: '',
        level: HealthLevel.green,
        detail: '',
        solution: '',
      ),
    );
    final cameraIssue = issues.firstWhere(
      (issue) => issue.code == ErrorCodes.cam001 || issue.code == ErrorCodes.cam003,
      orElse: () => const DiagnosticCheck(
        code: null,
        title: '',
        level: HealthLevel.green,
        detail: '',
        solution: '',
      ),
    );
    if (!await folder.exists()) {
      await folder.create(recursive: true);
      await _logger.info('Storage folder created during auto repair');
    }
    final hasWriteAccess = await _systemService.canWriteToFolder(settings.storageFolder);
    if (!hasWriteAccess) {
      await _logger.warn(
        'Permission issue detected during auto repair',
        data: {'code': ErrorCodes.cam007},
      );
      return '[${ErrorCodes.cam007}] Aplikasi tidak dapat menulis ke folder tersebut. Pilih folder lain atau jalankan aplikasi sebagai administrator.';
    }

    if (dllIssue.code == ErrorCodes.cam005) {
      await _logger.error(
        'Native camera engine missing',
        data: {'code': ErrorCodes.cam005},
      );
      return '[${ErrorCodes.cam005}] Camera Engine belum ditemukan. Silakan reinstall aplikasi.';
    }

    if (cameraIssue.code == ErrorCodes.cam001 || cameraIssue.code == ErrorCodes.cam003) {
      await _logger.info('Auto repair: camera reconnect sequence started');
      await _cameraService.rescanUsb();
      await _cameraService.refreshSdk();
      await _cameraService.disconnect();
      final connectedSnapshot = await _cameraService.connect();
      if (connectedSnapshot.connectionState == CameraConnectionState.connected) {
        return '[${ErrorCodes.cam001}] Kamera berhasil ditemukan.';
      }
      return '[${ErrorCodes.cam001}] Kamera masih belum terhubung. Pastikan kamera menyala dan kabel USB tersambung.';
    }

    await _cameraService.rescanUsb();
    await _cameraService.refreshSdk();
    if (_cameraService.snapshot.connectionState !=
        CameraConnectionState.connected) {
      await _cameraService.connect();
    }
    await _logger.info('Automatic repair completed');
    return '[${ErrorCodes.cam001}] Kamera berhasil ditemukan.';
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
