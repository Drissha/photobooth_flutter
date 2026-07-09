import '../../../core/models/diagnostic_models.dart';

abstract class DiagnosticContract {
  Future<StartupReport> runStartupChecks();
  Future<List<DiagnosticCheck>> runSmartDiagnostic();
}
