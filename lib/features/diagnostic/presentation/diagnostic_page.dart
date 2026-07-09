import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/controller/app_controller.dart';
import '../../../widgets/app_widgets.dart';

class DiagnosticPage extends StatelessWidget {
  const DiagnosticPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final checks = controller.smartDiagnostic.isEmpty
        ? controller.startupReport?.checks ?? const []
        : controller.smartDiagnostic;

    return ListView(
      children: [
        SectionHeader(
          title: 'Diagnostic',
          subtitle: 'Checklist otomatis dan langkah perbaikan cepat',
          trailing: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ActionButton(
                label: 'Scan Ulang',
                icon: Icons.refresh,
                isPrimary: false,
                onPressed: () async {
                  final message = await controller.runSmartDiagnostic();
                  if (context.mounted) {
                    _showSnack(context, message);
                  }
                },
              ),
              ActionButton(
                label: 'Perbaiki Otomatis',
                icon: Icons.build,
                onPressed: () async {
                  final message = await controller.repairAutomatically();
                  if (context.mounted) {
                    _showSnack(context, message);
                  }
                },
              ),
              ActionButton(
                label: 'Export Log',
                icon: Icons.archive,
                isPrimary: false,
                onPressed: () async {
                  final message = await controller.exportDiagnosticBundle();
                  if (context.mounted) {
                    _showSnack(context, message);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...checks.map(
          (check) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: DiagnosticStateChip(level: check.level),
                title: Text(check.title),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${check.detail}\n${check.solution}'),
                ),
                isThreeLine: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
