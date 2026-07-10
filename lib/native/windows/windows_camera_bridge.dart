import 'dart:io';

class WindowsCameraBridge {
  WindowsCameraBridge();

  List<String> listAvailableCameras() {
    if (!Platform.isWindows) {
      return const [];
    }

    final result = Process.runSync(
      'powershell.exe',
      [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        r"Get-PnpDevice -Class Camera,Image -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName } | Select-Object -ExpandProperty FriendlyName",
      ],
    );

    if (result.exitCode != 0) {
      return const [];
    }

    final devices = <String>[];
    for (final rawLine in result.stdout.toString().split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty || devices.contains(line)) {
        continue;
      }
      devices.add(line);
    }
    return devices;
  }

  bool get isAvailable => Platform.isWindows;

  String get statusMessage {
    if (!Platform.isWindows) {
      return 'Windows camera bridge hanya tersedia di Windows.';
    }

    final cameras = listAvailableCameras();
    if (cameras.isEmpty) {
      return 'Tidak ada webcam Windows terdeteksi.';
    }

    return 'Webcam Windows terdeteksi: ${cameras.first}.';
  }
}
