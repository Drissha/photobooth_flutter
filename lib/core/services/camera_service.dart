import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../logger/app_logger_service.dart';
import '../models/camera_models.dart';
import '../../native/windows/camera_ffi.dart';

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

  Future<String> capturePreviewFrame({
    required String storageFolder,
    required String fileNamePrefix,
  });
}

class MockCameraService implements CameraService {
  MockCameraService({
    required this._logger,
    required this._cameraNativeBridge,
  });

  final AppLoggerService _logger;
  final CameraNativeBridge _cameraNativeBridge;
  CameraSnapshot _snapshot = CameraSnapshot.initial();

  @override
  CameraSnapshot get snapshot => _snapshot;

  @override
  Future<CameraSnapshot> connect() async {
    await _logger.info('Camera connect requested');
    final nativeResult = _cameraNativeBridge.connect();
    _snapshot = _cameraNativeBridge.snapshot;
    if (nativeResult != 0) {
      await _logger.warn(
        'Webcam backend connect returned non-zero',
        data: {'code': nativeResult},
      );
      return _snapshot;
    }
    await _logger.info(
      'Camera connected',
      data: {'cameraName': _snapshot.cameraName},
    );
    return _snapshot;
  }

  @override
  Future<CameraSnapshot> disconnect() async {
    await _logger.info('Camera disconnect requested');
    final nativeResult = _cameraNativeBridge.disconnect();
    if (nativeResult != 0) {
      await _logger.warn(
        'Webcam backend disconnect returned non-zero',
        data: {'code': nativeResult},
      );
    }
    _snapshot = _cameraNativeBridge.snapshot;
    await _logger.info('Camera disconnected');
    return _snapshot;
  }

  @override
  Future<CameraSnapshot> refreshSdk() async {
    await _logger.info('Webcam backend refresh requested');
    final nativeResult = _cameraNativeBridge.refreshSdk();
    if (nativeResult != 0) {
      await _logger.warn(
        'Webcam backend refresh returned non-zero',
        data: {'code': nativeResult},
      );
    }
    _snapshot = _cameraNativeBridge.snapshot;
    return _snapshot;
  }

  @override
  Future<CameraSnapshot> rescanUsb() async {
    await _logger.info('USB rescan requested');
    final nativeResult = _cameraNativeBridge.rescanUsb();
    if (nativeResult != 0) {
      await _logger.warn(
        'Webcam rescan returned non-zero',
        data: {'code': nativeResult},
      );
    }
    _snapshot = _cameraNativeBridge.snapshot;
    return _snapshot;
  }

  @override
  Future<CameraSnapshot> autofocus() async {
    await _logger.info('Autofocus requested');
    final nativeResult = _cameraNativeBridge.autofocus();
    if (nativeResult != 0) {
      await _logger.warn(
        'Webcam autofocus returned non-zero',
        data: {'code': nativeResult},
      );
    }
    _snapshot = _cameraNativeBridge.snapshot;
    return _snapshot;
  }

  @override
  Future<CameraSnapshot> zoom(double value) async {
    await _logger.info('Zoom requested', data: {'value': value});
    final nativeResult = _cameraNativeBridge.zoom(value.round());
    if (nativeResult != 0) {
      await _logger.warn(
        'Webcam zoom returned non-zero',
        data: {'code': nativeResult, 'value': value},
      );
    }
    _snapshot = _cameraNativeBridge.snapshot;
    return _snapshot;
  }

  @override
  Future<CameraSnapshot> rotate() async {
    await _logger.info('Rotate requested');
    final nativeResult = _cameraNativeBridge.rotate();
    if (nativeResult != 0) {
      await _logger.warn(
        'Webcam rotate returned non-zero',
        data: {'code': nativeResult},
      );
    }
    _snapshot = _cameraNativeBridge.snapshot;
    return _snapshot;
  }

  @override
  Future<CameraSnapshot> toggleLiveView() async {
    await _logger.info('Live view toggled');
    final nextState = !_snapshot.isLiveViewActive;
    final nativeResult =
        nextState ? _cameraNativeBridge.startLiveView() : _cameraNativeBridge.stopLiveView();
    if (nativeResult != 0) {
      await _logger.warn(
        'Webcam live view returned non-zero',
        data: {'code': nativeResult, 'enabled': nextState},
      );
    }
    _snapshot = _cameraNativeBridge.snapshot;
    return _snapshot;
  }

  @override
  Future<GalleryItem> capture({
    required String storageFolder,
    required String fileNamePrefix,
  }) async {
    await _logger.info('Capture requested');
    final filePath = await _buildImagePath(
      storageFolder: storageFolder,
      fileNamePrefix: fileNamePrefix,
    );
    final success = await _captureFrame(filePath);
    if (!success) {
      await _logger.warn(
        'Webcam capture returned non-zero',
        data: {'filePath': filePath},
      );
      throw StateError('Capture failed');
    }
    final timestamp = DateTime.now();
    return GalleryItem(
      fileName: filePath.split(Platform.pathSeparator).last,
      filePath: filePath,
      createdAt: timestamp,
    );
  }

  @override
  Future<String> capturePreviewFrame({
    required String storageFolder,
    required String fileNamePrefix,
  }) async {
    final filePath = await _buildImagePath(
      storageFolder: storageFolder,
      fileNamePrefix: fileNamePrefix,
    );
    final success = await _captureFrame(filePath);
    if (!success) {
      throw StateError('Preview refresh failed');
    }
    return filePath;
  }

  Future<String> _buildImagePath({
    required String storageFolder,
    required String fileNamePrefix,
  }) async {
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
    return '${directory.path}${Platform.pathSeparator}$fileName.jpg';
  }

  Future<bool> _captureFrame(String filePath) async {
    if (_cameraNativeBridge.snapshot.connectionState != CameraConnectionState.connected) {
      return false;
    }

    final cameras = _cameraNativeBridge.listAvailableCameras();
    final selectedCamera = _cameraNativeBridge.snapshot.cameraName.trim().isNotEmpty &&
            _cameraNativeBridge.snapshot.cameraName != 'Belum terhubung'
        ? _cameraNativeBridge.snapshot.cameraName
        : (cameras.isNotEmpty ? cameras.first : null);
    if (selectedCamera == null) {
      return false;
    }

    final directory = File(filePath).parent;
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final command = [
      '-y',
      '-hide_banner',
      '-loglevel error',
      '-f dshow',
      '-i video="${_escapeForFfmpeg(selectedCamera)}"',
      '-frames:v 1',
      '-q:v 2',
      '"${_escapeForFfmpeg(filePath)}"',
    ].join(' ');

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    return ReturnCode.isSuccess(returnCode) == true && File(filePath).existsSync();
  }

  String _escapeForFfmpeg(String value) {
    return value.replaceAll('"', r'\"');
  }
}
