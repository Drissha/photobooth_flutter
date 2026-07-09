import '../logger/app_logger_service.dart';
import '../models/camera_models.dart';
import '../services/camera_service.dart';

class CameraRepository {
  CameraRepository({
    required this._service,
    required this._logger,
  });

  final CameraService _service;
  final AppLoggerService _logger;

  CameraSnapshot get snapshot => _service.snapshot;

  Future<CameraSnapshot> connect() async {
    final snapshot = await _service.connect();
    await _logger.info('Camera repository connect completed');
    return snapshot;
  }

  Future<CameraSnapshot> disconnect() async {
    final snapshot = await _service.disconnect();
    await _logger.info('Camera repository disconnect completed');
    return snapshot;
  }

  Future<CameraSnapshot> refreshSdk() => _service.refreshSdk();

  Future<CameraSnapshot> rescanUsb() => _service.rescanUsb();

  Future<CameraSnapshot> autofocus() => _service.autofocus();

  Future<CameraSnapshot> zoom(double value) => _service.zoom(value);

  Future<CameraSnapshot> rotate() => _service.rotate();

  Future<CameraSnapshot> toggleLiveView() => _service.toggleLiveView();

  Future<GalleryItem> capture({
    required String storageFolder,
    required String fileNamePrefix,
  }) async {
    final item = await _service.capture(
      storageFolder: storageFolder,
      fileNamePrefix: fileNamePrefix,
    );
    await _logger.info('Capture completed', data: {'file': item.fileName});
    return item;
  }
}
