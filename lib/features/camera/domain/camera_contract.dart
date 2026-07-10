import '../../../core/models/camera_models.dart';

abstract class CameraContract {
  CameraSnapshot get snapshot;
  Future<CameraSnapshot> connect();
  Future<CameraSnapshot> disconnect();
  Future<GalleryItem> capture({
    required String storageFolder,
    required String fileNamePrefix,
  });
  Future<String> capturePreviewFrame({
    required String storageFolder,
    required String fileNamePrefix,
  });
}
