import 'dart:convert';
import 'dart:io';

import '../constants/app_constants.dart';

class AppLoggerService {
  AppLoggerService({this._rootDirectory});

  final Directory? _rootDirectory;

  Future<void> info(String message, {Map<String, Object?> data = const {}}) {
    return _write('INFO', message, data: data);
  }

  Future<void> warn(String message, {Map<String, Object?> data = const {}}) {
    return _write('WARN', message, data: data);
  }

  Future<void> error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> data = const {},
  }) {
    return _write(
      'ERROR',
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  Future<List<Map<String, Object?>>> readErrorHistory() async {
    final entries = <Map<String, Object?>>[];
    final directory = _logDirectory();
    if (!await directory.exists()) {
      return entries;
    }

    await for (final entity in directory.list(recursive: false)) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.log')) {
        continue;
      }

      final lines = await entity.readAsLines();
      for (final line in lines) {
        if (line.trim().isEmpty) {
          continue;
        }
        try {
          final decoded = jsonDecode(line);
          if (decoded is Map<String, dynamic> &&
              decoded['level']?.toString() == 'ERROR') {
            entries.add(decoded.cast<String, Object?>());
          }
        } catch (_) {
          continue;
        }
      }
    }

    return entries;
  }

  Future<File?> latestLogFile() async {
    final directory = _logDirectory();
    if (!await directory.exists()) {
      return null;
    }

    final files = <File>[];
    await for (final entity in directory.list(recursive: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.log')) {
        files.add(entity);
      }
    }
    if (files.isEmpty) {
      return null;
    }

    files.sort((a, b) => b.path.compareTo(a.path));
    return files.first;
  }

  Future<void> _write(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> data = const {},
  }) async {
    final directory = _logDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final file = File(
      '${directory.path}${Platform.pathSeparator}${_logFileName(DateTime.now())}',
    );
    final payload = <String, Object?>{
      'ts': DateTime.now().toIso8601String(),
      'level': level,
      'message': message,
      if (data.isNotEmpty) 'data': data,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
    await file.writeAsString(
      '${jsonEncode(payload)}${Platform.lineTerminator}',
      mode: FileMode.append,
      flush: true,
    );
  }

  Directory _logDirectory() {
    final root = _rootDirectory ?? Directory.current;
    return Directory(
      '${root.path}${Platform.pathSeparator}${AppConstants.logFolderName}',
    );
  }

  String _logFileName(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d.log';
  }
}
