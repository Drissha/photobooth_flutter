enum CameraConnectionState { disconnected, connecting, connected, error }

enum HealthLevel { green, yellow, red }

class CameraSnapshot {
  const CameraSnapshot({
    required this.connectionState,
    required this.isLiveViewActive,
    required this.cameraName,
    required this.serialNumber,
    required this.sdkVersion,
  });

  final CameraConnectionState connectionState;
  final bool isLiveViewActive;
  final String cameraName;
  final String serialNumber;
  final String sdkVersion;

  CameraSnapshot copyWith({
    CameraConnectionState? connectionState,
    bool? isLiveViewActive,
    String? cameraName,
    String? serialNumber,
    String? sdkVersion,
  }) {
    return CameraSnapshot(
      connectionState: connectionState ?? this.connectionState,
      isLiveViewActive: isLiveViewActive ?? this.isLiveViewActive,
      cameraName: cameraName ?? this.cameraName,
      serialNumber: serialNumber ?? this.serialNumber,
      sdkVersion: sdkVersion ?? this.sdkVersion,
    );
  }

  factory CameraSnapshot.initial() {
    return const CameraSnapshot(
      connectionState: CameraConnectionState.disconnected,
      isLiveViewActive: false,
      cameraName: 'Belum terhubung',
      serialNumber: '-',
      sdkVersion: '-',
    );
  }
}

class GalleryItem {
  const GalleryItem({
    required this.fileName,
    required this.filePath,
    required this.createdAt,
  });

  final String fileName;
  final String filePath;
  final DateTime createdAt;
}
