import '../../../core/models/camera_models.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.cameraState,
    required this.storageFolder,
    required this.galleryCount,
  });

  final CameraConnectionState cameraState;
  final String storageFolder;
  final int galleryCount;
}
