import 'dart:io';

import '../constants/app_constants.dart';
import '../constants/error_codes.dart';
import '../models/camera_models.dart';
import '../models/diagnostic_models.dart';
import '../../native/windows/camera_ffi.dart';

class SystemService {
  SystemService({CameraNativeBridge? cameraNativeBridge})
      : _cameraNativeBridge = cameraNativeBridge ?? CameraNativeBridge();

  final CameraNativeBridge _cameraNativeBridge;

  Future<bool> isCameraEngineAvailable() async {
    return _cameraNativeBridge.isAvailable;
  }

  Future<bool> isLibGPhoto2Available() async {
    return _cameraNativeBridge.isAvailable;
  }

  Future<bool> isVendorSdkAvailable() async => isLibGPhoto2Available();

  Future<String> getWindowsVersion() async {
    if (!Platform.isWindows) {
      return 'Windows-only';
    }

    return Platform.operatingSystemVersion;
  }

  Future<bool> canWriteToFolder(String folderPath) async {
    final directory = Directory(folderPath);
    try {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final probe = File(
        '${directory.path}${Platform.pathSeparator}.write_probe',
      );
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<StartupReport> runStartupChecks({
    required bool cameraConnected,
    required String storageFolder,
    required bool sdkLoaded,
    required bool dllLoaded,
  }) async {
    final checks = <DiagnosticCheck>[
      DiagnosticCheck(
        code: ErrorCodes.cam010,
        title: 'Windows',
        level: Platform.isWindows ? HealthLevel.green : HealthLevel.red,
        detail: Platform.isWindows
            ? 'Windows detected.'
            : 'Application ini hanya berjalan di Windows.',
        solution: Platform.isWindows
            ? 'Tidak ada tindakan yang diperlukan.'
            : 'Jalankan aplikasi di Windows 10/11.',
      ),
      DiagnosticCheck(
        code: ErrorCodes.cam005,
        title: 'Webcam Backend',
        level: sdkLoaded ? HealthLevel.green : HealthLevel.red,
        detail: sdkLoaded
            ? 'Webcam backend siap digunakan.'
            : 'Webcam backend belum tersedia.',
        solution: sdkLoaded
            ? 'Tidak ada tindakan yang diperlukan.'
            : 'Pastikan backend capture tersedia dan kamera Windows terdeteksi.',
        steps: const [
          DiagnosticStep(
            title: 'Langkah 1',
            detail: 'Tutup aplikasi lalu jalankan ulang.',
          ),
          DiagnosticStep(
            title: 'Langkah 2',
            detail: 'Pastikan webcam driver Windows dan backend capture sudah tersedia.',
          ),
        ],
      ),
      DiagnosticCheck(
        code: ErrorCodes.cam005,
        title: 'DLL',
        level: dllLoaded ? HealthLevel.green : HealthLevel.red,
        detail: dllLoaded
            ? 'Backend kamera sudah termuat.'
            : 'Backend kamera belum ditemukan.',
        solution: dllLoaded
            ? 'Tidak ada tindakan yang diperlukan.'
            : 'Pastikan backend capture Windows dapat dijalankan.',
      ),
      DiagnosticCheck(
        code: ErrorCodes.cam001,
        title: 'Camera',
        level: cameraConnected ? HealthLevel.green : HealthLevel.yellow,
        detail: cameraConnected
            ? 'Kamera terhubung.'
            : 'Kamera belum terhubung.',
        solution: cameraConnected
            ? 'Tidak ada tindakan yang diperlukan.'
            : 'Hubungkan kamera lalu tekan Hubungkan Kamera.',
      ),
      DiagnosticCheck(
        code: ErrorCodes.cam006,
        title: 'Folder Penyimpanan',
        level: await Directory(storageFolder).exists()
            ? HealthLevel.green
            : HealthLevel.yellow,
        detail: await Directory(storageFolder).exists()
            ? 'Folder siap digunakan.'
            : 'Folder belum ada dan akan dibuat otomatis.',
        solution: 'Gunakan lokasi penyimpanan yang valid.',
      ),
      DiagnosticCheck(
        code: ErrorCodes.cam007,
        title: 'Write Permission',
        level: await canWriteToFolder(storageFolder)
            ? HealthLevel.green
            : HealthLevel.red,
        detail: await canWriteToFolder(storageFolder)
            ? 'Aplikasi dapat menulis file.'
            : 'Aplikasi tidak dapat menulis ke folder tersebut.',
        solution: await canWriteToFolder(storageFolder)
            ? 'Tidak ada tindakan yang diperlukan.'
            : 'Pilih folder lain atau jalankan aplikasi sebagai administrator.',
      ),
      DiagnosticCheck(
        code: ErrorCodes.cam010,
        title: 'Internet',
        level: HealthLevel.yellow,
        detail: 'Pengecekan internet dapat ditambahkan saat integrasi update.',
        solution: 'Hubungkan jaringan bila fitur update diaktifkan.',
      ),
      DiagnosticCheck(
        code: ErrorCodes.cam010,
        title: 'Update',
        level: HealthLevel.yellow,
        detail: 'Fitur update belum dihubungkan ke server distribusi.',
        solution: 'Tambahkan endpoint update sebelum produksi.',
      ),
    ];

    final ready = checks.every((check) {
      return check.level != HealthLevel.red;
    });

    return StartupReport(ready: ready, checks: checks);
  }

  Future<String> getSystemInventory() async {
    return [
      'app_name=${AppConstants.appName}',
      'platform=${Platform.operatingSystem}',
      'version=${Platform.operatingSystemVersion}',
      'processors=${Platform.numberOfProcessors}',
    ].join('\n');
  }
}
