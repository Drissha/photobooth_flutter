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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();

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
