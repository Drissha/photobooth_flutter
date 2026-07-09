import 'dart:async';
import 'dart:io';

import '../logger/app_logger_service.dart';
import '../models/camera_models.dart';

abstract class CameraService {
  CameraSnapshot get snapshot;

  Future<CameraSnapshot> connect();
  Future<CameraSnapshot> disconnect();
  Future<CameraSnapshot> refreshSdk();
  Future<CameraSnapshot> rescanUsb();
  Future<CameraSnapshot> autofocus();
  Future<CameraSnapshot> zoom(double value);
  Future<CameraSnapshot> rotate();
  Future<CameraSnapshot> toggleLiveView();
  Future<GalleryItem> capture({
    required String storageFolder,
    required String fileNamePrefix,
  });
}

class MockCameraService implements CameraService {
  MockCameraService({required this._logger});

  final AppLoggerService _logger;
  CameraSnapshot _snapshot = CameraSnapshot.initial();

  @override
  CameraSnapshot get snapshot => _snapshot;

  @override
  Future<CameraSnapshot> connect() async {
    await _logger.info('Camera connect requested');
    _snapshot = _snapshot.copyWith(
      connectionState: CameraConnectionState.connecting,
      cameraName: 'Canon / Nikon / Sony',
      serialNumber: 'SN-0001',
      sdkVersion: '1.0.0',
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _snapshot = _snapshot.copyWith(
      connectionState: CameraConnectionState.connected,
      isLiveViewActive: true,
    );
    await _logger.info('Camera connected');
    return _snapshot;
  }

  @override
  Future<CameraSnapshot> disconnect() async {
    await _logger.info('Camera disconnect requested');
    _snapshot = CameraSnapshot.initial();
    await _logger.info('Camera disconnected');
    return _snapshot;
  }

  @override
  Future<CameraSnapshot> refreshSdk() async {
    await _logger.info('SDK refresh requested');
    _snapshot = _snapshot.copyWith(sdkVersion: '1.0.0');
    return _snapshot;
  }

  @override
  Future<CameraSnapshot> rescanUsb() async {
    await _logger.info('USB rescan requested');
    return _snapshot;
  }

  @override
  Future<CameraSnapshot> autofocus() async {
    await _logger.info('Autofocus requested');
    return _snapshot;
  }

  @override
  Future<CameraSnapshot> zoom(double value) async {
    await _logger.info('Zoom requested', data: {'value': value});
    return _snapshot;
  }

  @override
  Future<CameraSnapshot> rotate() async {
    await _logger.info('Rotate requested');
    return _snapshot;
  }

  @override
  Future<CameraSnapshot> toggleLiveView() async {
    await _logger.info('Live view toggled');
    _snapshot = _snapshot.copyWith(
      isLiveViewActive: !_snapshot.isLiveViewActive,
      connectionState: _snapshot.connectionState == CameraConnectionState.connected
          ? CameraConnectionState.connected
          : _snapshot.connectionState,
    );
    return _snapshot;
  }

  @override
  Future<GalleryItem> capture({
    required String storageFolder,
    required String fileNamePrefix,
  }) async {
    await _logger.info('Capture requested');
    final directory = Directory(storageFolder);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final timestamp = DateTime.now();
    final fileName = [
      fileNamePrefix,
      timestamp.year.toString().padLeft(4, '0'),
      timestamp.month.toString().padLeft(2, '0'),
      timestamp.day.toString().padLeft(2, '0'),
      timestamp.hour.toString().padLeft(2, '0'),
      timestamp.minute.toString().padLeft(2, '0'),
      timestamp.second.toString().padLeft(2, '0'),
    ].join('_');
    final filePath =
        '${directory.path}${Platform.pathSeparator}$fileName.jpg';
    await File(filePath).writeAsString(
      'Photobooth placeholder capture generated at ${timestamp.toIso8601String()}',
      flush: true,
    );
    return GalleryItem(
      fileName: '$fileName.jpg',
      filePath: filePath,
      createdAt: timestamp,
    );
  }
}
