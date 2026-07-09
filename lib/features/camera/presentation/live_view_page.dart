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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF1F2937)],
                ),
                border: Border.all(color: const Color(0x1FFFFFFF)),
              ),
              child: Center(
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
                          ? 'Preview kamera akan tampil di sini'
                          : 'Hubungkan kamera untuk melihat preview',
                      style: const TextStyle(color: Colors.white70),
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
              label: 'Autofocus',
              icon: Icons.center_focus_strong,
              onPressed: () async {
                final message = await controller.autofocus();
                if (context.mounted) {
                  _snack(context, message);
                }
              },
            ),
            ActionButton(
              label: 'Capture',
              icon: Icons.camera_alt,
              onPressed: () async {
                final message = await controller.takePhoto();
                if (context.mounted) {
                  _snack(context, message);
                }
              },
            ),
            ActionButton(
              label: 'Zoom',
              icon: Icons.zoom_in,
              isPrimary: false,
              onPressed: () async {
                final message = await controller.toggleLiveView();
                if (context.mounted) {
                  _snack(context, message);
                }
              },
            ),
            ActionButton(
              label: 'Rotate',
              icon: Icons.rotate_right,
              isPrimary: false,
              onPressed: () async {
                final message = await controller.reloadSdk();
                if (context.mounted) {
                  _snack(context, message);
                }
              },
            ),
            ActionButton(
              label: 'Fullscreen',
              icon: Icons.fullscreen,
              isPrimary: false,
              onPressed: () {},
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
