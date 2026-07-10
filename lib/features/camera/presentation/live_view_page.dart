import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/controller/app_controller.dart';
import '../../../core/models/camera_models.dart';
import '../../../widgets/app_widgets.dart';

class LiveViewPage extends StatelessWidget {
  const LiveViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final connected =
        controller.cameraSnapshot.connectionState == CameraConnectionState.connected;
    final framePath = controller.liveViewFramePath;
    final hasFrame = framePath != null && File(framePath).existsSync();

    return ListView(
      children: [
        const SectionHeader(
          title: 'Live View',
          subtitle: 'Kontrol kamera secara langsung dengan tampilan sederhana',
        ),
        const SizedBox(height: 20),
        GlassCard(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF111827), Color(0xFF1F2937)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (connected && hasFrame)
                      Image.file(
                        File(framePath!),
                        fit: BoxFit.cover,
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              connected ? Icons.videocam : Icons.videocam_off,
                              size: 64,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              connected
                                  ? 'Tekan Refresh untuk memuat preview live view'
                                  : 'Hubungkan kamera untuk melihat preview',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xAA0B1324),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: Text(
                          controller.isLiveViewRunning
                              ? 'Live view aktif'
                              : 'Live view tidak aktif',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ActionButton(
              label: controller.isLiveViewRunning ? 'Stop Live View' : 'Start Live View',
              icon: controller.isLiveViewRunning ? Icons.stop_circle : Icons.play_arrow,
              onPressed: () async {
                final message = await controller.toggleLiveView();
                if (context.mounted) {
                  _snack(context, message);
                }
              },
            ),
            ActionButton(
              label: 'Refresh Preview',
              icon: Icons.refresh,
              isPrimary: false,
              onPressed: () async {
                final message = await controller.refreshLiveView();
                if (context.mounted) {
                  _snack(context, message);
                }
              },
            ),
            ActionButton(
              label: 'Capture Photo',
              icon: Icons.camera_alt,
              onPressed: () async {
                final message = await controller.takePhoto();
                if (context.mounted) {
                  _snack(context, message);
                }
              },
            ),
            ActionButton(
              label: 'Autofocus',
              icon: Icons.center_focus_strong,
              isPrimary: false,
              onPressed: () async {
                final message = await controller.autofocus();
                if (context.mounted) {
                  _snack(context, message);
                }
              },
            ),
            ActionButton(
              label: 'Refresh Kamera',
              icon: Icons.refresh,
              isPrimary: false,
              onPressed: () async {
                final message = await controller.refreshAvailableCameras();
                if (context.mounted) {
                  _snack(context, message);
                }
              },
            ),
            ActionButton(
              label: 'Reload SDK',
              icon: Icons.rotate_right,
              isPrimary: false,
              onPressed: () async {
                final message = await controller.reloadSdk();
                if (context.mounted) {
                  _snack(context, message);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
