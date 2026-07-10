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
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 16),
                leading: DiagnosticStateChip(level: check.level),
                title: Row(
                  children: [
                    Expanded(child: Text(check.title)),
                    if (check.code != null) ...[
                      const SizedBox(width: 10),
                      _CodeChip(code: check.code!),
                    ],
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    check.detail,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                trailing: ActionButton(
                  label: 'Perbaiki',
                  icon: Icons.auto_fix_high,
                  isPrimary: false,
                  onPressed: () async {
                    final message = await context
                        .read<AppController>()
                        .repairDiagnosticIssue(check);
                    if (context.mounted) {
                      _showSnack(context, message);
                    }
                  },
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          check.solution,
                          style: const TextStyle(color: Colors.white),
                        ),
                        if (check.steps.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ...check.steps.map(
                            (step) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    size: 18,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${step.title}: ${step.detail}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ActionButton(
                              label: 'Perbaiki Otomatis',
                              icon: Icons.build,
                              onPressed: () async {
                                final message = await context
                                    .read<AppController>()
                                    .repairDiagnosticIssue(check);
                                if (context.mounted) {
                                  _showSnack(context, message);
                                }
                              },
                            ),
                            ActionButton(
                              label: 'Scan Ulang',
                              icon: Icons.refresh,
                              isPrimary: false,
                              onPressed: () async {
                                final message = await context
                                    .read<AppController>()
                                    .runSmartDiagnostic();
                                if (context.mounted) {
                                  _showSnack(context, message);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1324),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Text(
        code,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
