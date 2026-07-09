import 'dart:convert';
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

class AppController extends ChangeNotifier {
  AppController({
    required this._logger,
    required this._settingsRepository,
    required this._cameraRepository,
    required this._diagnosticRepository,
  });

  final AppLoggerService _logger;
  final SettingsRepository _settingsRepository;
  final CameraRepository _cameraRepository;
  final DiagnosticRepository _diagnosticRepository;

  bool _bootstrapped = false;
  bool _bootstrapping = false;
  bool _busy = false;
  AppSettings _settings = AppSettings.defaults();
  CameraSnapshot _cameraSnapshot = CameraSnapshot.initial();
  StartupReport? _startupReport;
  List<DiagnosticCheck> _smartDiagnostic = const [];
  List<GalleryItem> _gallery = const [];
  SupportInformation? _supportInformation;

  bool get bootstrapped => _bootstrapped;
  bool get bootstrapping => _bootstrapping;
  bool get busy => _busy;
  AppSettings get settings => _settings;
  CameraSnapshot get cameraSnapshot => _cameraSnapshot;
  StartupReport? get startupReport => _startupReport;
  List<DiagnosticCheck> get smartDiagnostic => _smartDiagnostic;
  List<GalleryItem> get gallery => _gallery;
  SupportInformation? get supportInformation => _supportInformation;

  String get cameraStatusLabel {
    switch (_cameraSnapshot.connectionState) {
      case CameraConnectionState.connected:
        return 'Kamera Terhubung';
      case CameraConnectionState.connecting:
        return 'Sedang menghubungkan';
      case CameraConnectionState.error:
        return 'Kamera Bermasalah';
      case CameraConnectionState.disconnected:
        return 'Kamera Tidak Terhubung';
    }
  }

  Future<String> bootstrap() async {
    if (_bootstrapped || _bootstrapping) {
      return 'Aplikasi sudah siap.';
    }

    _bootstrapping = true;
    notifyListeners();
    await _logger.info('App Start');

    _settings = await _settingsRepository.load();
    await _ensureStorageFolderExists();
    _cameraSnapshot = _cameraRepository.snapshot;
    _startupReport = await _diagnosticRepository.runStartupChecks();
    _smartDiagnostic = await _diagnosticRepository.runSmartDiagnostic();
    _supportInformation = await _diagnosticRepository.buildSupportInformation();
    await _refreshGallery();

    _bootstrapping = false;
    _bootstrapped = true;
    notifyListeners();
    return _startupReport?.ready == true
        ? 'Aplikasi siap digunakan.'
        : 'Beberapa pemeriksaan belum lolos, tetapi aplikasi tetap dapat dibuka.';
  }

  Future<String> connectCamera() async {
    await _setBusy(true);
    try {
      _cameraSnapshot = await _cameraRepository.connect();
      await _logger.info('Camera Connected');
      await _refreshDiagnostics();
      return 'Kamera berhasil terhubung.';
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
      await _logger.info('Camera Disconnected');
      await _refreshDiagnostics();
      return 'Kamera berhasil diputuskan.';
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
        return 'Kamera belum terhubung.';
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

  Future<String> reloadSdk() async {
    await _setBusy(true);
    try {
      _cameraSnapshot = await _cameraRepository.refreshSdk();
      _smartDiagnostic = await _diagnosticRepository.runSmartDiagnostic();
      return 'SDK berhasil dimuat ulang.';
    } finally {
      await _setBusy(false);
    }
  }

  Future<String> scanUsb() async {
    await _setBusy(true);
    try {
      _cameraSnapshot = await _cameraRepository.rescanUsb();
      _smartDiagnostic = await _diagnosticRepository.runSmartDiagnostic();
      return _cameraSnapshot.connectionState == CameraConnectionState.connected
          ? 'Kamera berhasil ditemukan.'
          : 'Pemindaian USB selesai.';
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

  Future<String> saveSettings(AppSettings settings) async {
    await _setBusy(true);
    try {
      _settings = settings;
      await _settingsRepository.save(settings);
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
                'title': check.title,
                'level': check.level.name,
                'detail': check.detail,
                'solution': check.solution,
              },
            )
            .toList(),
        'smart_diagnostic': _smartDiagnostic
            .map(
              (check) => {
                'title': check.title,
                'level': check.level.name,
                'detail': check.detail,
                'solution': check.solution,
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
      'SDK Version: ${info.sdkVersion}',
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

  Future<void> _refreshDiagnostics() async {
    _smartDiagnostic = await _diagnosticRepository.runSmartDiagnostic();
    _startupReport = await _diagnosticRepository.runStartupChecks();
    _supportInformation = await _diagnosticRepository.buildSupportInformation();
    notifyListeners();
  }

  Future<void> _refreshGallery() async {
    final folder = Directory(_settings.storageFolder);
    if (!await folder.exists()) {
      _gallery = const [];
      return;
    }

    final photos = <GalleryItem>[];
    await for (final entity in folder.list()) {
      if (entity is File &&
          entity.path.toLowerCase().endsWith('.jpg')) {
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
