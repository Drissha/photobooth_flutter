#pragma once

#ifdef __cplusplus
extern "C" {
#endif

__declspec(dllexport) const char* CameraEngine_GetVersion();
__declspec(dllexport) int CameraEngine_IsAvailable();
__declspec(dllexport) int CameraEngine_Connect();
__declspec(dllexport) int CameraEngine_Disconnect();
__declspec(dllexport) int CameraEngine_RescanUsb();
__declspec(dllexport) int CameraEngine_RefreshSdk();
__declspec(dllexport) int CameraEngine_StartLiveView();
__declspec(dllexport) int CameraEngine_StopLiveView();
__declspec(dllexport) int CameraEngine_Autofocus();
__declspec(dllexport) int CameraEngine_Zoom(int value);
__declspec(dllexport) int CameraEngine_Rotate();
__declspec(dllexport) int CameraEngine_Capture(const char* file_path);

#ifdef __cplusplus
}
#endif
