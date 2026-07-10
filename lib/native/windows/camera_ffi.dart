import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../../core/models/camera_models.dart';
import 'windows_camera_bridge.dart';

class CameraNativeBridge {
  CameraNativeBridge({
    List<String>? binaryCandidates,
  }) : _binaryCandidates = binaryCandidates ?? _defaultBinaryCandidates();

  List<String> _binaryCandidates;
  CameraEngineBindings? _bindings;
  final WindowsCameraBridge _windowsCameraBridge = WindowsCameraBridge();
  String? _resolvedBinary;
  String? _cachedVersion;
  String? _preferredCameraName;
  List<String> _cachedDevices = const [];
  CameraSnapshot _snapshot = CameraSnapshot.initial();

  CameraSnapshot get snapshot => _snapshot;

  bool get isAvailable => Platform.isWindows;

  String get loadedLibraryName => 'ffmpeg_kit_flutter_new';

  String get loadedVendorLabel => 'Windows Webcam';

  String get statusMessage {
    final cameras = _cachedDevices.isNotEmpty
        ? _cachedDevices
        : _windowsCameraBridge.listAvailableCameras();
    if (cameras.isNotEmpty && isAvailable) {
      return 'FFmpegKit backend siap digunakan: ${cameras.first}.';
    }

    if (cameras.isNotEmpty) {
      return 'Webcam Windows terdeteksi, tetapi backend belum siap.';
    }

    if (!isAvailable) {
      return 'Backend kamera hanya tersedia di Windows.';
    }

    return 'FFmpegKit backend siap digunakan.';
  }

  void configureBinaryPath(String? binaryPath) {
    final trimmed = binaryPath?.trim() ?? '';
    _resolvedBinary = null;
    _cachedVersion = null;
    _binaryCandidates = trimmed.isEmpty
        ? _defaultBinaryCandidates()
        : <String>[
            trimmed,
            ..._defaultBinaryCandidates(),
          ];
  }

  void configurePreferredCamera(String? cameraName) {
    final trimmed = cameraName?.trim() ?? '';
    _preferredCameraName = trimmed.isEmpty ? null : trimmed;
  }

  List<String> listAvailableCameras() {
    final windowsDevices = _windowsCameraBridge.listAvailableCameras();
    _cachedDevices = _mergeDevices(windowsDevices, const <String>[]);
    return _cachedDevices;
  }

  String get version {
    final cachedVersion = _cachedVersion;
    if (cachedVersion != null) {
      return cachedVersion;
    }

    if (!Platform.isWindows) {
      return '-';
    }

    _cachedVersion = 'ffmpeg_kit_flutter_new';
    return _cachedVersion!;
  }

  int connect() {
    final devices = _ensureDevices();
    if (devices.isEmpty) {
      _snapshot = _snapshot.copyWith(
        connectionState: CameraConnectionState.error,
        cameraName: 'Webcam belum terdeteksi',
        sdkVersion: version,
      );
      return 2;
    }

    final selectedCamera = _selectCamera(devices);
    _snapshot = _snapshot.copyWith(
      connectionState: CameraConnectionState.connected,
      isLiveViewActive: false,
      cameraName: selectedCamera,
      serialNumber: '-',
      sdkVersion: version,
    );
    return 0;
  }

  int disconnect() {
    _snapshot = CameraSnapshot.initial().copyWith(sdkVersion: version);
    return 0;
  }

  int rescanUsb() {
    _cachedDevices = listAvailableCameras();
    return _cachedDevices.isEmpty ? 1 : 0;
  }

  int refreshSdk() {
    _cachedVersion = null;
    _snapshot = _snapshot.copyWith(sdkVersion: version);
    return isAvailable ? 0 : -1;
  }

  int startLiveView() {
    if (!isAvailable) {
      return -1;
    }
    _snapshot = _snapshot.copyWith(isLiveViewActive: true);
    return 0;
  }

  int stopLiveView() {
    if (!isAvailable) {
      return -1;
    }
    _snapshot = _snapshot.copyWith(isLiveViewActive: false);
    return 0;
  }

  int autofocus() {
    return isAvailable ? 0 : -1;
  }

  int zoom(int value) {
    return isAvailable ? 0 : -1;
  }

  int rotate() {
    return isAvailable ? 0 : -1;
  }

  int capture(String filePath) {
    final bindings = _loadBindings();
    final devices = _ensureDevices();
    if (devices.isEmpty) {
      return 2;
    }

    final binary = _resolveBinary();
    if (binary != null) {
      final selectedCamera = _selectCamera(devices);
      final directory = File(filePath).parent;
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final result = _run(
        binary,
        [
          '-y',
          '-hide_banner',
          '-loglevel',
          'error',
          '-f',
          'dshow',
          '-i',
          'video="$selectedCamera"',
          '-frames:v',
          '1',
          filePath,
        ],
      );

      if (result.exitCode == 0 && File(filePath).existsSync()) {
        return 0;
      }
    }

    if (bindings == null || !bindings.isAvailable) {
      return -1;
    }

    final pathPtr = filePath.toNativeUtf8();
    try {
      return bindings.capture(pathPtr);
    } finally {
      malloc.free(pathPtr);
    }
  }

  String? _resolveBinary() {
    final cached = _resolvedBinary;
    if (cached != null) {
      return cached;
    }

    for (final candidate in _binaryCandidates) {
      final resolved = _resolveCandidate(candidate);
      if (resolved != null) {
        _resolvedBinary = resolved;
        return resolved;
      }
    }

    return null;
  }

  String? _resolveCandidate(String candidate) {
    try {
      if (File(candidate).existsSync()) {
        return candidate;
      }

      final probe = Platform.isWindows
          ? Process.runSync('where', [candidate], runInShell: true)
          : Process.runSync('which', [candidate]);
      if (probe.exitCode != 0) {
        return null;
      }

      final output = probe.stdout.toString().trim();
      if (output.isEmpty) {
        return null;
      }

      return output.split(RegExp(r'\r?\n')).first.trim();
    } catch (_) {
      return null;
    }
  }

  List<String> _ensureDevices() {
    if (_cachedDevices.isEmpty) {
      _cachedDevices = listAvailableCameras();
    }
    return _cachedDevices;
  }

  List<String> _mergeDevices(List<String> primary, List<String> secondary) {
    final merged = <String>[];
    for (final device in [...primary, ...secondary]) {
      if (device.trim().isEmpty || merged.contains(device)) {
        continue;
      }
      merged.add(device);
    }
    return merged;
  }

  List<String> _listVideoDevices(String binary) {
    final result = _run(
      binary,
      const [
        '-hide_banner',
        '-list_devices',
        'true',
        '-f',
        'dshow',
        '-i',
        'dummy',
      ],
    );

    final output = [
      result.stdout.toString(),
      result.stderr.toString(),
    ].join('\n');

    final devices = <String>[];
    var inVideoSection = false;
    for (final rawLine in LineSplitter.split(output)) {
      final line = rawLine.trim();
      if (line.contains('DirectShow video devices')) {
        inVideoSection = true;
        continue;
      }
      if (inVideoSection && line.contains('DirectShow audio devices')) {
        break;
      }
      if (!inVideoSection) {
        continue;
      }

      final match = RegExp(r'"([^"]+)"').firstMatch(line);
      if (match != null) {
        devices.add(match.group(1)!.trim());
      }
    }

    final uniqueDevices = <String>[];
    for (final device in devices) {
      if (!uniqueDevices.contains(device)) {
        uniqueDevices.add(device);
      }
    }
    return uniqueDevices;
  }

  String _selectCamera(List<String> devices) {
    final preferredCamera = _preferredCameraName;
    if (preferredCamera != null) {
      for (final device in devices) {
        if (device.toLowerCase() == preferredCamera.toLowerCase()) {
          return device;
        }
      }
    }
    return devices.first;
  }

  ProcessResult _run(String executable, List<String> arguments) {
    try {
      return Process.runSync(
        executable,
        arguments,
        runInShell: Platform.isWindows,
      );
    } catch (error) {
      return ProcessResult(
        0,
        1,
        '',
        error.toString(),
      );
    }
  }

  static List<String> _defaultBinaryCandidates() {
    if (!Platform.isWindows) {
      return const <String>[
        'ffmpeg',
        'ffmpeg.exe',
      ];
    }

    return const <String>[
      'ffmpeg',
      'ffmpeg.exe',
      r'C:\ffmpeg\bin\ffmpeg.exe',
      r'C:\Program Files\ffmpeg\bin\ffmpeg.exe',
      r'C:\Program Files\FFmpeg\bin\ffmpeg.exe',
      r'C:\Program Files (x86)\ffmpeg\bin\ffmpeg.exe',
      r'C:\Program Files (x86)\FFmpeg\bin\ffmpeg.exe',
    ];
  }

  CameraEngineBindings? _loadBindings() {
    final cached = _bindings;
    if (cached != null) {
      return cached;
    }

    if (!Platform.isWindows) {
      return null;
    }

    final candidates = <String>[
      'camera_engine.dll',
      'camera_engine',
    ];

    for (final candidate in candidates) {
      try {
        final library = DynamicLibrary.open(candidate);
        _bindings = CameraEngineBindings(library);
        return _bindings;
      } catch (_) {
        continue;
      }
    }

    return null;
  }

}

extension _FirstOrNullExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

typedef _GetVersionNative = Pointer<Utf8> Function();
typedef _BoolNative = Int32 Function();
typedef _IntNative = Int32 Function();
typedef _CaptureNative = Int32 Function(Pointer<Utf8>);

class CameraEngineBindings {
  CameraEngineBindings(DynamicLibrary library)
      : _getVersion = library.lookupFunction<_GetVersionNative, Pointer<Utf8> Function()>(
          'CameraEngine_GetVersion',
        ),
        _isAvailable = library.lookupFunction<_BoolNative, int Function()>(
          'CameraEngine_IsAvailable',
        ),
        _connect = library.lookupFunction<_IntNative, int Function()>(
          'CameraEngine_Connect',
        ),
        _disconnect = library.lookupFunction<_IntNative, int Function()>(
          'CameraEngine_Disconnect',
        ),
        _rescanUsb = library.lookupFunction<_IntNative, int Function()>(
          'CameraEngine_RescanUsb',
        ),
        _refreshSdk = library.lookupFunction<_IntNative, int Function()>(
          'CameraEngine_RefreshSdk',
        ),
        _startLiveView = library.lookupFunction<_IntNative, int Function()>(
          'CameraEngine_StartLiveView',
        ),
        _stopLiveView = library.lookupFunction<_IntNative, int Function()>(
          'CameraEngine_StopLiveView',
        ),
        _autofocus = library.lookupFunction<_IntNative, int Function()>(
          'CameraEngine_Autofocus',
        ),
        _zoom = library.lookupFunction<Int32 Function(Int32), int Function(int)>(
          'CameraEngine_Zoom',
        ),
        _rotate = library.lookupFunction<_IntNative, int Function()>(
          'CameraEngine_Rotate',
        ),
        _capture = library.lookupFunction<_CaptureNative, int Function(Pointer<Utf8>)>(
          'CameraEngine_Capture',
        );

  final Pointer<Utf8> Function() _getVersion;
  final int Function() _isAvailable;
  final int Function() _connect;
  final int Function() _disconnect;
  final int Function() _rescanUsb;
  final int Function() _refreshSdk;
  final int Function() _startLiveView;
  final int Function() _stopLiveView;
  final int Function() _autofocus;
  final int Function(int) _zoom;
  final int Function() _rotate;
  final int Function(Pointer<Utf8>) _capture;

  bool get isAvailable => _isAvailable() != 0;
  String get loadedLibraryName => 'camera_engine.dll';

  Pointer<Utf8> getVersion() => _getVersion();
  int connect() => _connect();
  int disconnect() => _disconnect();
  int rescanUsb() => _rescanUsb();
  int refreshSdk() => _refreshSdk();
  int startLiveView() => _startLiveView();
  int stopLiveView() => _stopLiveView();
  int autofocus() => _autofocus();
  int zoom(int value) => _zoom(value);
  int rotate() => _rotate();
  int capture(Pointer<Utf8> filePath) => _capture(filePath);
}
