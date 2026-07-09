import '../logger/app_logger_service.dart';
import '../models/diagnostic_models.dart';
import '../services/diagnostic_service.dart';

class DiagnosticRepository {
  DiagnosticRepository({
    required this._service,
    required this._logger,
  });

  final DiagnosticService _service;
  final AppLoggerService _logger;

  Future<StartupReport> runStartupChecks() async {
    final report = await _service.runStartupChecks();
    await _logger.info('Diagnostic startup checks collected');
    return report;
  }

  Future<List<DiagnosticCheck>> runSmartDiagnostic() {
    return _service.runSmartDiagnostic();
  }

  Future<String> repairAutomatically() => _service.repairAutomatically();

  Future<SupportInformation> buildSupportInformation() {
    return _service.buildSupportInformation();
  }
}
