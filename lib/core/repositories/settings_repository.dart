import '../logger/app_logger_service.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsRepository {
  SettingsRepository({
    required this._service,
    required this._logger,
  });

  final SettingsService _service;
  final AppLoggerService _logger;

  Future<AppSettings> load() async {
    final settings = await _service.loadSettings();
    await _logger.info('Settings loaded');
    return settings;
  }

  Future<void> save(AppSettings settings) async {
    await _service.saveSettings(settings);
    await _logger.info('Settings saved');
  }
}
