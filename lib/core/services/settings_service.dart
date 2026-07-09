import 'dart:convert';
import 'dart:io';

import '../constants/app_constants.dart';
import '../models/app_settings.dart';

class SettingsService {
  SettingsService({this._rootDirectory});

  final Directory? _rootDirectory;

  Future<AppSettings> loadSettings() async {
    final file = _settingsFile();
    if (!await file.exists()) {
      final defaults = AppSettings.defaults();
      await saveSettings(defaults);
      return defaults;
    }

    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is Map<String, dynamic>) {
      return AppSettings.fromJson(decoded.cast<String, Object?>());
    }

    return AppSettings.defaults();
  }

  Future<void> saveSettings(AppSettings settings) async {
    final file = _settingsFile();
    final directory = file.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(settings.toJson()),
      flush: true,
    );
  }

  Directory _root() => _rootDirectory ?? Directory.current;

  File _settingsFile() {
    final root = _root();
    return File(
      '${root.path}${Platform.pathSeparator}${AppConstants.settingsFolderName}${Platform.pathSeparator}app_settings.json',
    );
  }
}
