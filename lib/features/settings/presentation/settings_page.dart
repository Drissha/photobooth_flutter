import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/controller/app_controller.dart';
import '../../../core/models/app_settings.dart';
import '../../../widgets/app_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _storageController;
  late final TextEditingController _prefixController;
  late final TextEditingController _ffmpegController;
  String? _selectedCamera;
  bool _autoDownload = true;
  bool _autoDelete = false;
  bool _darkMode = true;
  bool _autoUpdate = false;
  String _language = 'Indonesia';

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppController>().settings;
    _storageController = TextEditingController(text: settings.storageFolder);
    _prefixController = TextEditingController(text: settings.fileNamePrefix);
    _ffmpegController = TextEditingController(text: settings.ffmpegBinaryPath);
    _selectedCamera =
        settings.preferredCameraName.trim().isEmpty ? null : settings.preferredCameraName;
    _autoDownload = settings.autoDownload;
    _autoDelete = settings.autoDelete;
    _darkMode = settings.darkMode;
    _autoUpdate = settings.autoUpdate;
    _language = settings.language;
  }

  @override
  void dispose() {
    _storageController.dispose();
    _prefixController.dispose();
    _ffmpegController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final cameras = controller.availableCameras;
    final selectedCamera = _selectedCamera != null && cameras.contains(_selectedCamera)
        ? _selectedCamera
        : (cameras.isNotEmpty ? cameras.first : null);

    return ListView(
      children: [
        const SectionHeader(
          title: 'Settings',
          subtitle: 'Pengaturan dasar untuk penyimpanan dan perilaku aplikasi',
        ),
        const SizedBox(height: 20),
        GlassCard(
          child: Column(
            children: [
              TextField(
                controller: _storageController,
                decoration: const InputDecoration(
                  labelText: 'Folder Penyimpanan',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _prefixController,
                decoration: const InputDecoration(labelText: 'Nama File'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ffmpegController,
                decoration: const InputDecoration(
                  labelText: 'Path FFmpeg (opsional)',
                  hintText: 'Contoh: C:\\tools\\ffmpeg.exe',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedCamera,
                      items: cameras
                          .map(
                            (camera) => DropdownMenuItem(
                              value: camera,
                              child: Text(camera),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: cameras.isEmpty
                          ? null
                          : (value) => setState(() => _selectedCamera = value),
                      decoration: const InputDecoration(
                        labelText: 'Kamera Windows',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ActionButton(
                    label: 'Refresh',
                    icon: Icons.refresh,
                    isPrimary: false,
                    onPressed: () async {
                      await controller.refreshAvailableCameras();
                      if (context.mounted) {
                        setState(() {
                          _selectedCamera = controller.availableCameras.contains(_selectedCamera)
                              ? _selectedCamera
                              : (controller.availableCameras.isNotEmpty
                                  ? controller.availableCameras.first
                                  : null);
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (cameras.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Belum ada webcam Windows terdeteksi. Pastikan kamera terpasang dan driver aktif.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _autoDownload,
                onChanged: (value) => setState(() => _autoDownload = value),
                title: const Text('Auto Download'),
              ),
              SwitchListTile(
                value: _autoDelete,
                onChanged: (value) => setState(() => _autoDelete = value),
                title: const Text('Auto Delete'),
              ),
              SwitchListTile(
                value: _darkMode,
                onChanged: (value) => setState(() => _darkMode = value),
                title: const Text('Dark Mode'),
              ),
              SwitchListTile(
                value: _autoUpdate,
                onChanged: (value) => setState(() => _autoUpdate = value),
                title: const Text('Update'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _language,
                items: const [
                  DropdownMenuItem(value: 'Indonesia', child: Text('Indonesia')),
                  DropdownMenuItem(value: 'English', child: Text('English')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _language = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Bahasa'),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ActionButton(
                  label: 'Simpan',
                  icon: Icons.save,
                  onPressed: () async {
                    final message = await controller.saveSettings(
                      AppSettings(
                        storageFolder: _storageController.text.trim(),
                        fileNamePrefix: _prefixController.text.trim().isEmpty
                            ? controller.settings.fileNamePrefix
                            : _prefixController.text.trim(),
                        preferredCameraName: selectedCamera ?? '',
                        ffmpegBinaryPath: _ffmpegController.text.trim(),
                        autoDownload: _autoDownload,
                        autoDelete: _autoDelete,
                        language: _language,
                        darkMode: _darkMode,
                        autoUpdate: _autoUpdate,
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
