import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/controller/app_controller.dart';
import '../../../widgets/app_widgets.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final info = controller.supportInformation;

    return ListView(
      children: [
        SectionHeader(
          title: 'Support',
          subtitle: 'Ringkasan informasi yang siap dibagikan ke tim support',
          trailing: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ActionButton(
                label: 'Copy Semua Informasi',
                icon: Icons.copy,
                onPressed: () async {
                  final text = await controller.copyAllInformation();
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Informasi disalin.')),
                    );
                  }
                },
              ),
              ActionButton(
                label: 'Export Diagnostic',
                icon: Icons.archive,
                isPrimary: false,
                onPressed: () async {
                  final message = await controller.exportDiagnosticBundle();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GlassCard(
          child: Column(
            children: [
              InfoTile(label: 'Versi aplikasi', value: info?.appVersion ?? '-'),
              const SizedBox(height: 12),
              InfoTile(label: 'Versi Webcam Backend', value: info?.sdkVersion ?? '-'),
              const SizedBox(height: 12),
              InfoTile(label: 'Versi Windows', value: info?.windowsVersion ?? '-'),
              const SizedBox(height: 12),
              InfoTile(label: 'Nama Kamera', value: info?.cameraName ?? '-'),
              const SizedBox(height: 12),
              InfoTile(
                label: 'Serial Kamera',
                value: info?.cameraSerialNumber ?? '-',
              ),
              const SizedBox(height: 12),
              InfoTile(
                label: 'Folder Penyimpanan',
                value: info?.storageFolder ?? '-',
              ),
              const SizedBox(height: 12),
              InfoTile(
                label: 'Status Kamera',
                value: info?.connectionState.name ?? '-',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
