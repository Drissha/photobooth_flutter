import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/controller/app_controller.dart';
import '../../../core/models/camera_models.dart';
import '../../../core/models/diagnostic_models.dart';
import '../../../widgets/app_widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final connected =
        controller.cameraSnapshot.connectionState == CameraConnectionState.connected;

    return ListView(
      children: [
        SectionHeader(
          title: 'Dashboard',
          subtitle: 'Ringkasan cepat untuk operator studio',
          trailing: StatusBanner(
            title: controller.cameraStatusLabel,
            subtitle: controller.cameraSnapshot.cameraName,
            isPositive: connected,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 280,
              child: InfoTile(
                label: 'Status Kamera',
                value: controller.cameraStatusLabel,
              ),
            ),
            SizedBox(
              width: 280,
              child: InfoTile(
                label: 'Nama Kamera',
                value: controller.cameraSnapshot.cameraName,
              ),
            ),
            SizedBox(
              width: 280,
              child: InfoTile(
                label: 'Folder Penyimpanan',
                value: controller.settings.storageFolder,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ActionButton(
              label: connected ? 'Webcam Tersambung' : 'Hubungkan Webcam',
              icon: connected ? Icons.link : Icons.link_off,
              onPressed: connected
                  ? null
                  : () async {
                      final message = await controller.connectCamera();
                      if (context.mounted) {
                        _showSnack(context, message);
                      }
                    },
            ),
            ActionButton(
              label: 'Putuskan Webcam',
              icon: Icons.link_off,
              isPrimary: false,
              onPressed: connected
                  ? () async {
                      final message = await controller.disconnectCamera();
                      if (context.mounted) {
                        _showSnack(context, message);
                      }
                    }
                  : null,
            ),
            ActionButton(
              label: 'Refresh Kamera',
              icon: Icons.refresh,
              isPrimary: false,
              onPressed: () async {
                final message = await controller.refreshAvailableCameras();
                if (context.mounted) {
                  _showSnack(context, message);
                }
              },
            ),
            ActionButton(
              label: 'Live View',
              icon: Icons.videocam,
              isPrimary: false,
              onPressed: () => context.go('/live-view'),
            ),
            ActionButton(
              label: 'Ambil Foto',
              icon: Icons.camera_alt,
              onPressed: () async {
                final message = await controller.takePhoto();
                if (context.mounted) {
                  _showSnack(context, message);
                }
              },
            ),
            ActionButton(
              label: 'Pengaturan',
              icon: Icons.settings,
              isPrimary: false,
              onPressed: () => context.go('/settings'),
            ),
            ActionButton(
              label: 'Diagnostik',
              icon: Icons.medical_information,
              isPrimary: false,
              onPressed: () => context.go('/diagnostic'),
            ),
            ActionButton(
              label: 'Support',
              icon: Icons.support_agent,
              isPrimary: false,
              onPressed: () => context.go('/support'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Checklist Cepat',
                subtitle: 'Status inti sistem yang paling sering dicek operator',
              ),
              const SizedBox(height: 16),
              ..._quickChecks(controller).map(
                (check) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(check.title),
                    subtitle: Text(check.detail),
                    trailing: DiagnosticStateChip(level: check.level),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<DiagnosticCheck> _quickChecks(AppController controller) {
    final diagnostics = controller.smartDiagnostic;
    if (diagnostics.isEmpty) {
      return [
        const DiagnosticCheck(
          title: 'Menunggu diagnostik',
          level: HealthLevel.yellow,
          detail: 'Data diagnostik akan tampil setelah pemeriksaan selesai.',
          solution: 'Buka halaman Diagnostik untuk menjalankan scan.',
        ),
      ];
    }

    return diagnostics.take(4).toList(growable: false);
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
