import 'dart:ffi';

class WindowsCameraBridge {
  WindowsCameraBridge();

  DynamicLibrary? get library => null;

  bool get isAvailable => false;

  String get statusMessage => 'Native camera bridge is not wired yet.';
}
