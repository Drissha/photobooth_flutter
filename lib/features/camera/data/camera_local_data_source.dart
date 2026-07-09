import '../../../core/models/camera_models.dart';
import '../../../core/services/camera_service.dart';

class CameraLocalDataSource {
  CameraLocalDataSource(this._service);

  final CameraService _service;

  CameraSnapshot get snapshot => _service.snapshot;
  Future<CameraSnapshot> connect() => _service.connect();
  Future<CameraSnapshot> disconnect() => _service.disconnect();
  Future<GalleryItem> capture({
    required String storageFolder,
    required String fileNamePrefix,
  }) {
    return _service.capture(
      storageFolder: storageFolder,
      fileNamePrefix: fileNamePrefix,
    );
  }
}
