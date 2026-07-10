#include "camera_engine.h"

#include <fstream>

static const char* kVersion = "camera-engine-scaffold-1.0.0";

const char* CameraEngine_GetVersion() {
  return kVersion;
}

int CameraEngine_IsAvailable() {
  return 1;
}

int CameraEngine_Connect() {
  return 0;
}

int CameraEngine_Disconnect() {
  return 0;
}

int CameraEngine_RescanUsb() {
  return 0;
}

int CameraEngine_RefreshSdk() {
  return 0;
}

int CameraEngine_StartLiveView() {
  return 0;
}

int CameraEngine_StopLiveView() {
  return 0;
}

int CameraEngine_Autofocus() {
  return 0;
}

int CameraEngine_Zoom(int value) {
  (void)value;
  return 0;
}

int CameraEngine_Rotate() {
  return 0;
}

int CameraEngine_Capture(const char* file_path) {
  if (file_path == nullptr) {
    return 1;
  }

  std::ofstream file(file_path, std::ios::binary);
  if (!file.is_open()) {
    return 2;
  }

  file << "Native photobooth capture generated at camera-engine-scaffold-1.0.0";
  file.close();
  return 0;
}
