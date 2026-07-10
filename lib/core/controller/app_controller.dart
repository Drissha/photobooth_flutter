import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../logger/app_logger_service.dart';
import '../models/app_settings.dart';
import '../models/camera_models.dart';
import '../models/diagnostic_models.dart';
import '../repositories/camera_repository.dart';
import '../repositories/diagnostic_repository.dart';
import '../repositories/settings_repository.dart';
import '../../native/windows/camera_ffi.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this._logger,
    required this._settingsRepository,
    required this._cameraRepository,
    required this._diagnosticRepository,
    required this._cameraNativeBridge,
  });

  final AppLoggerService _logger;
  final SettingsRepository _settingsRepository;
  final CameraRepository _cameraRepository;
  final DiagnosticRepository _diagnosticRepository;
  final CameraNativeBridge _cameraNativeBridge;

  bool _bootstrapped = false;
  bool _bootstrapping = false;
  bool _busy = false;
  AppSettings _settings = AppSettings.defaults();
  CameraSnapshot _cameraSnapshot = CameraSnapshot.initial();
  List<String> _availableCameras = const [];
  Timer? _liveViewTimer;
  String? _liveViewFramePath;
  bool _refreshingLiveView = false;
  StartupReport? _startupReport;
  List<DiagnosticCheck> _smartDiagnostic = const [];
  List<GalleryItem> _gallery = const [];
  SupportInformation? _supportInformation;

  bool get bootstrapped => _bootstrapped;
  bool get bootstrapping => _bootstrapping;
  bool get busy => _busy;
  AppSettings get settings => _settings;
  CameraSnapshot get cameraSnapshot => _cameraSnapshot;
  List<String> get availableCameras => _availableCameras;
  String? get liveViewFramePath => _liveViewFramePath;
  bool get isLiveViewRunning => _liveViewTimer?.isActive == true;
  StartupReport? get startupReport => _startupReport;
  List<DiagnosticCheck> get smartDiagnostic => _smartDiagnostic;
  List<GalleryItem> get gallery => _gallery;
  SupportInformation? get supportInformation => _supportInformation;

  String get cameraStatusLabel {
    switch (_cameraSnapshot.connectionState) {
      case CameraConnectionState.connected:
        return 'Webcam Terhubung';
      case CameraConnectionState.connecting:
        return 'Sedang menghubungkan';
      case CameraConnectionState.error:
        return 'Webcam Bermasalah';
      case CameraConnectionState.disconnected:
        return 'Webcam Tidak Terhubung';
    }
  }

  Future<String> bootstrap() async {
    if (_bootstrapped || _bootstrapping) {
      return 'Aplikasi sudah siap.';
    }

    _bootstrapping = true;
    notifyListeners();
    try {
      await _logger.info('App Start');

      _settings = await _settingsRepository.load();
      _cameraNativeBridge.configureBinaryPath(_settings.ffmpegBinaryPath);
      _cameraNativeBridge.configurePreferredCamera(_settings.preferredCameraName);

      try {
        _availableCameras = _cameraNativeBridge.listAvailableCameras();
      } catch (error, stackTrace) {
        _availableCameras = const [];
        await _logger.error(
          'Camera enumeration failed during bootstrap',
          error: error,
          stackTrace: stackTrace,
        );
      }

      await _ensureStorageFolderExists();
      _cameraSnapshot = _cameraRepository.snapshot;

      if (_cameraSnapshot.connectionState == CameraConnectionState.disconnected &&
          _cameraNativeBridge.isAvailable &&
          _availableCameras.isNotEmpty) {
        await _logger.info('Auto connect camera requested');
        try {
          _cameraSnapshot = await _cameraRepository.connect();
        } catch (error, stackTrace) {
          await _logger.error(
            'Auto connect failed during bootstrap',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }

      try {
        _startupReport = await _diagnosticRepository.runStartupChecks();
      } catch (error, stackTrace) {
        _startupReport = const StartupReport(ready: false, checks: []);
        await _logger.error(
          'Startup checks failed',
          error: error,
          stackTrace: stackTrace,
        );
      }

      try {
        _smartDiagnostic = await _diagnosticRepository.runSmartDiagnostic();
      } catch (error, stackTrace) {
        _smartDiagnostic = const [];
        await _logger.error(
          'Smart diagnostic failed',
          error: error,
          stackTrace: stackTrace,
        );
      }

      try {
        _supportInformation = await _diagnosticRepository.buildSupportInformation();
      } catch (error, stackTrace) {
        _supportInformation = null;
        await _logger.error(
          'Support information build failed',
          error: error,
          stackTrace: stackTrace,
        );
      }

      try {
        await _refreshGallery();
      } catch (error, stackTrace) {
        await _logger.error(
          'Gallery refresh failed during bootstrap',
          error: error,
          stackTrace: stackTrace,
        );
      }

      return _startupReport?.ready == true
          ? 'Aplikasi siap digunakan.'
          : 'Beberapa pemeriksaan belum lolos, tetapi aplikasi tetap dapat dibuka.';
    } catch (error, stackTrace) {
      await _logger.error(
        'App bootstrap failed',
        error: error,
        stackTrace: stackTrace,
      );
      _startupReport = const StartupReport(ready: false, checks: []);
      return 'Aplikasi dibuka dengan mode terbatas.';
    } finally {
      _bootstrapping = false;
      _bootstrapped = true;
      notifyListeners();
    }
  }

  Future<String> connectCamera() async {
    await _setBusy(true);
    try {
      if (_cameraSnapshot.connectionState == CameraConnectionState.connected) {
        return 'Webcam sudah terhubung.';
      }
      _cameraSnapshot = await _cameraRepository.connect();
      if (_cameraSnapshot.connectionState != CameraConnectionState.connected) {
        await _logger.warn('Camera connect did not reach connected state', data: {
          'cameraName': _cameraSnapshot.cameraName,
          'state': _cameraSnapshot.connectionState.name,
        });
        return _cameraSnapshot.cameraName == 'Webcam belum terdeteksi'
            ? 'Webcam terdeteksi, tetapi backend kamera belum bisa terhubung.'
            : 'Webcam belum bisa terhubung. Periksa backend kamera dan driver Windows.';
      }
      await _logger.info('Camera Connected');
      await _refreshDiagnostics();
      return 'Webcam berhasil terhubung.';
    } catch (error, stackTrace) {
      await _logger.error('Camera connection failed', error: error, stackTrace: stackTrace);
      _cameraSnapshot = _cameraSnapshot.copyWith(
        connectionState: CameraConnectionState.error,
      );
      return 'Kamera tidak ditemukan. Coba sambungkan ulang.';
    } finally {
      await _setBusy(false);
    }
  }

  Future<String> disconnectCamera() async {
    await _setBusy(true);
    try {
      _cameraSnapshot = await _cameraRepository.disconnect();
      _stopLiveViewRefreshLoop();
      _liveViewFramePath = null;
      await _logger.info('Camera Disconnected');
      await _refreshDiagnostics();
      return 'Webcam berhasil diputuskan.';
    } finally {
      await _setBusy(false);
    }
  }

  Future<String> autofocus() async {
    await _setBusy(true);
    try {
      await _cameraRepository.autofocus();
      await _logger.info('Autofocus');
      return 'Autofocus dijalankan.';
    } finally {
      await _setBusy(false);
    }
  }

  Future<String> toggleLiveView() async {
    await _setBusy(true);
    try {
      _cameraSnapshot = await _cameraRepository.toggleLiveView();
      if (_cameraSnapshot.isLiveViewActive) {
        _startLiveViewRefreshLoop();
        await _refreshLiveViewFrame();
      } else {
        _stopLiveViewRefreshLoop();
        _liveViewFramePath = null;
      }
      return _cameraSnapshot.isLiveViewActive
          ? 'Live view diaktifkan.'
          : 'Live view dimatikan.';
    } finally {
      await _setBusy(false);
    }
  }

  Future<String> takePhoto() async {
    await _setBusy(true);
    try {
      if (_cameraSnapshot.connectionState != CameraConnectionState.connected) {
        return 'Webcam belum terhubung.';
      }

      final photo = await _cameraRepository.capture(
        storageFolder: _settings.storageFolder,
        fileNamePrefix: _settings.fileNamePrefix,
      );
      _gallery = [photo, ..._gallery];
      await _logger.info('Download');
      if (_settings.autoDelete) {
        await _logger.info('Auto delete requested after capture');
      }
      notifyListeners();
      return 'Foto berhasil diambil.';
    } catch (error, stackTrace) {
      await _logger.error('Capture failed', error: error, stackTrace: stackTrace);
      return 'Foto gagal diambil.';
    } finally {
      await _setBusy(false);
    }
  }

  Future<String> refreshLiveView() async {
    await _setBusy(true);
    try {
      if (_cameraSnapshot.connectionState != CameraConnectionState.connected) {
        return 'Webcam belum terhubung.';
      }
      await _refreshLiveViewFrame();
      return _liveViewFramePath == null
          ? 'Preview live view belum bisa diperbarui.'
          : 'Preview live view diperbarui.';
    } finally {
      await _setBusy(false);
    }
  }

  Future<String> reloadSdk() async {
    await _setBusy(true);
    try {
      _cameraSnapshot = await _cameraRepository.refreshSdk();
      _smartDiagnostic = await _diagnosticRepository.runSmartDiagnostic();
      return 'Webcam backend berhasil dimuat ulang.';
    } finally {
      await _setBusy(false);
    }
  }

  Future<String> scanUsb() async {
    await _setBusy(true);
    try {
      _cameraSnapshot = await _cameraRepository.rescanUsb();
      _availableCameras = _cameraNativeBridge.listAvailableCameras();
      _smartDiagnostic = await _diagnosticRepository.runSmartDiagnostic();
      return _cameraSnapshot.connectionState == CameraConnectionState.connected
          ? 'Kamera berhasil ditemukan.'
          : 'Pemindaian USB selesai.';
    } finally {
      await _setBusy(false);
    }
  }

  Future<String> refreshAvailableCameras() async {
    await _setBusy(true);
    try {
      _availableCameras = _cameraNativeBridge.listAvailableCameras();
      notifyListeners();
      return _availableCameras.isEmpty
          ? 'Tidak ada webcam terdeteksi.'
          : 'Daftar webcam berhasil diperbarui.';
    } finally {
      await _setBusy(false);
    }
  }

  Future<String> runSmartDiagnostic() async {
    await _setBusy(true);
    try {
      _smartDiagnostic = await _diagnosticRepository.runSmartDiagnostic();
      _startupReport = await _diagnosticRepository.runStartupChecks();
      _supportInformation = await _diagnosticRepository.buildSupportInformation();
      await _logger.info('Diagnostic');
      return 'Diagnostik selesai.';
    } finally {
      await _setBusy(false);
    }
  }

  Future<String> repairAutomatically() async {
    await _setBusy(true);
    try {
      final message = await _diagnosticRepository.repairAutomatically();
      _cameraSnapshot = _cameraRepository.snapshot;
      _smartDiagnostic = await _diagnosticRepository.runSmartDiagnostic();
      _supportInformation = await _diagnosticRepository.buildSupportInformation();
      await _ensureStorageFolderExists();
      return message;
    } finally {
      await _setBusy(false);
    }
  }

  Future<String> repairDiagnosticIssue(DiagnosticCheck check) async {
    switch (check.code) {
      case 'CAM001':
      case 'CAM003':
        final scanMessage = await scanUsb();
        if (_cameraSnapshot.connectionState != CameraConnectionState.connected) {
          final connectMessage = await connectCamera();
          return '$scanMessage $connectMessage';
        }
        return scanMessage;
      case 'CAM005':
        return await repairAutomatically();
      case 'CAM006':
        await _ensureStorageFolderExists();
        await _refreshDiagnostics();
        return 'Folder penyimpanan sudah diperbaiki.';
      case 'CAM007':
        return 'Pilih folder lain atau jalankan aplikasi sebagai administrator.';
      case 'CAM008':
        return 'Pastikan driver kamera sudah terpasang di Windows.';
      case 'CAM009':
        final liveViewMessage = await toggleLiveView();
        return liveViewMessage;
      case 'CAM010':
      default:
        await runSmartDiagnostic();
        return 'Diagnostik dijalankan ulang.';
    }
  }

  Future<String> saveSettings(AppSettings settings) async {
    await _setBusy(true);
    try {
      _settings = settings;
      await _settingsRepository.save(settings);
      _cameraNativeBridge.configureBinaryPath(settings.ffmpegBinaryPath);
      _cameraNativeBridge.configurePreferredCamera(settings.preferredCameraName);
      _availableCameras = _cameraNativeBridge.listAvailableCameras();
      await _ensureStorageFolderExists();
      _supportInformation = await _diagnosticRepository.buildSupportInformation();
      notifyListeners();
      return 'Pengaturan tersimpan.';
    } finally {
      await _setBusy(false);
    }
  }

  Future<String> exportDiagnosticBundle() async {
    await _setBusy(true);
    try {
      final exportRoot = Directory(
        '${Directory.current.path}${Platform.pathSeparator}diagnostic_exports',
      );
      if (!await exportRoot.exists()) {
        await exportRoot.create(recursive: true);
      }

      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final bundleName = 'diagnostic-$stamp';
      final bundleDir = Directory(
        '${exportRoot.path}${Platform.pathSeparator}diagnostic-$stamp',
      );
      final zipFile = File(
        '${exportRoot.path}${Platform.pathSeparator}$bundleName.zip',
      );
      if (await bundleDir.exists()) {
        await bundleDir.delete(recursive: true);
      }
      await bundleDir.create(recursive: true);

      final systemInfo = await _diagnosticRepository.buildSupportInformation();
      final diagnosticPayload = <String, Object?>{
        'app_version': systemInfo.appVersion,
        'sdk_version': systemInfo.sdkVersion,
        'windows_version': systemInfo.windowsVersion,
        'camera_name': systemInfo.cameraName,
        'camera_serial_number': systemInfo.cameraSerialNumber,
        'storage_folder': systemInfo.storageFolder,
        'camera_state': systemInfo.connectionState.name,
        'startup_checks': _startupReport?.checks
            .map(
              (check) => {
                'code': check.code,
                'title': check.title,
                'level': check.level.name,
                'detail': check.detail,
                'solution': check.solution,
                'steps': check.steps
                    .map(
                      (step) => {
                        'title': step.title,
                        'detail': step.detail,
                      },
                    )
                    .toList(),
              },
            )
            .toList(),
        'smart_diagnostic': _smartDiagnostic
            .map(
              (check) => {
                'code': check.code,
                'title': check.title,
                'level': check.level.name,
                'detail': check.detail,
                'solution': check.solution,
                'steps': check.steps
                    .map(
                      (step) => {
                        'title': step.title,
                        'detail': step.detail,
                      },
                    )
                    .toList(),
              },
            )
            .toList(),
      };

      final systemInfoPayload = <String, Object?>{
        'app_version': systemInfo.appVersion,
        'sdk_version': systemInfo.sdkVersion,
        'windows_version': systemInfo.windowsVersion,
        'camera_name': systemInfo.cameraName,
        'camera_serial_number': systemInfo.cameraSerialNumber,
        'storage_folder': systemInfo.storageFolder,
        'camera_state': systemInfo.connectionState.name,
      };
      final cameraInfoPayload = <String, Object?>{
        'camera_name': systemInfo.cameraName,
        'camera_serial_number': systemInfo.cameraSerialNumber,
        'camera_state': systemInfo.connectionState.name,
        'sdk_version': systemInfo.sdkVersion,
      };
      final errorHistory = await _logger.readErrorHistory();

      await _writeJsonDocument(
        bundleDir,
        'diagnostic.json',
        diagnosticPayload,
      );
      await _writeJsonDocument(
        bundleDir,
        'system_info.json',
        systemInfoPayload,
      );
      await _writeJsonDocument(
        bundleDir,
        'camera_info.json',
        cameraInfoPayload,
      );
      await _writeJsonDocument(
        bundleDir,
        'error_history.json',
        {'errors': errorHistory},
      );
      await _copyIfExists(
        File(
          '${Directory.current.path}${Platform.pathSeparator}${AppConstants.settingsFolderName}${Platform.pathSeparator}app_settings.json',
        ),
        Directory('${bundleDir.path}${Platform.pathSeparator}${AppConstants.settingsFolderName}'),
      );
      await _copyDirectoryIfExists(
        Directory(
          '${Directory.current.path}${Platform.pathSeparator}${AppConstants.logFolderName}',
        ),
        Directory('${bundleDir.path}${Platform.pathSeparator}${AppConstants.logFolderName}'),
      );

      await _createZipFromDirectory(bundleDir, zipFile);
      await bundleDir.delete(recursive: true);
      return 'Diagnostic berhasil diekspor: ${zipFile.path}';
    } finally {
      await _setBusy(false);
    }
  }

  Future<String> copyAllInformation() async {
    final info = await _diagnosticRepository.buildSupportInformation();
    final text = [
      'App Version: ${info.appVersion}',
      'Webcam Backend Version: ${info.sdkVersion}',
      'Windows Version: ${info.windowsVersion}',
      'Camera Name: ${info.cameraName}',
      'Camera Serial Number: ${info.cameraSerialNumber}',
      'Storage Folder: ${info.storageFolder}',
      'Camera Status: ${info.connectionState.name}',
    ].join(Platform.lineTerminator);
    return text;
  }

  Future<String> openStorageFolder() async {
    final folder = Directory(_settings.storageFolder);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    if (Platform.isWindows) {
      await Process.run('explorer.exe', [folder.absolute.path]);
      return 'Folder penyimpanan dibuka.';
    }

    return 'Folder penyimpanan sudah disiapkan.';
  }

  Future<void> refreshGallery() async {
    await _refreshGallery();
  }

  @override
  void dispose() {
    _stopLiveViewRefreshLoop();
    super.dispose();
  }

  Future<void> _refreshDiagnostics() async {
    _smartDiagnostic = await _diagnosticRepository.runSmartDiagnostic();
    _startupReport = await _diagnosticRepository.runStartupChecks();
    _supportInformation = await _diagnosticRepository.buildSupportInformation();
    notifyListeners();
  }

  void _startLiveViewRefreshLoop() {
    _liveViewTimer?.cancel();
    _liveViewTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        unawaited(_refreshLiveViewFrame());
      },
    );
  }

  void _stopLiveViewRefreshLoop() {
    _liveViewTimer?.cancel();
    _liveViewTimer = null;
  }

  Future<void> _refreshLiveViewFrame() async {
    if (_refreshingLiveView) {
      return;
    }
    if (_cameraSnapshot.connectionState != CameraConnectionState.connected) {
      return;
    }

    try {
      _refreshingLiveView = true;
      final framePath = await _cameraRepository.capturePreviewFrame(
        storageFolder:
            '${Directory.systemTemp.path}${Platform.pathSeparator}photobooth_liveview',
        fileNamePrefix: 'liveview',
      );
      _liveViewFramePath = framePath;
      notifyListeners();
    } catch (error, stackTrace) {
      await _logger.error(
        'Live view refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _refreshingLiveView = false;
    }
  }

  Future<void> _refreshGallery() async {
    final folder = Directory(_settings.storageFolder);
    if (!await folder.exists()) {
      _gallery = const [];
      notifyListeners();
      return;
    }

    final photos = <GalleryItem>[];
    await for (final entity in folder.list()) {
      if (entity is File && _isGalleryImage(entity.path)) {
        photos.add(
          GalleryItem(
            fileName: entity.uri.pathSegments.last,
            filePath: entity.path,
            createdAt: await entity.lastModified(),
          ),
        );
      }
    }

    _gallery = photos.reversed.toList(growable: false);
    notifyListeners();
  }

  bool _isGalleryImage(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.png') ||
        lowerPath.endsWith('.bmp');
  }

  Future<void> _ensureStorageFolderExists() async {
    final directory = Directory(_settings.storageFolder);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  Future<void> _copyIfExists(File source, Directory destination) async {
    if (!await source.exists()) {
      return;
    }

    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }
    await source.copy(
      '${destination.path}${Platform.pathSeparator}${source.uri.pathSegments.last}',
    );
  }

  Future<void> _copyDirectoryIfExists(
    Directory source,
    Directory destination,
  ) async {
    if (!await source.exists()) {
      return;
    }

    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      if (entity is File) {
        await entity.copy(
          '${destination.path}${Platform.pathSeparator}${entity.uri.pathSegments.last}',
        );
      }
    }
  }

  Future<void> _writeJsonDocument(
    Directory directory,
    String fileName,
    Map<String, Object?> payload,
  ) async {
    await File(
      '${directory.path}${Platform.pathSeparator}$fileName',
    ).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
  }

  Future<void> _createZipFromDirectory(
    Directory sourceDirectory,
    File destinationFile,
  ) async {
    final archive = Archive();
    await for (final entity in sourceDirectory.list(recursive: true)) {
      if (entity is! File) {
        continue;
      }

      final relativePath = entity.path.substring(
        sourceDirectory.path.length + 1,
      ).replaceAll('\\', '/');
      final bytes = await entity.readAsBytes();
      archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
    }

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw StateError('Failed to encode diagnostic zip.');
    }

    await destinationFile.writeAsBytes(encoded, flush: true);
  }

  Future<void> _setBusy(bool value) async {
    _busy = value;
    notifyListeners();
  }
}
