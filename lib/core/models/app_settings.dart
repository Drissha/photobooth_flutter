import '../../core/constants/app_constants.dart';

class AppSettings {
  const AppSettings({
    required this.storageFolder,
    required this.fileNamePrefix,
    required this.autoDownload,
    required this.autoDelete,
    required this.language,
    required this.darkMode,
    required this.autoUpdate,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      storageFolder: AppConstants.defaultStorageFolderName,
      fileNamePrefix: AppConstants.defaultFileNamePrefix,
      autoDownload: true,
      autoDelete: false,
      language: 'Indonesia',
      darkMode: true,
      autoUpdate: false,
    );
  }

  final String storageFolder;
  final String fileNamePrefix;
  final bool autoDownload;
  final bool autoDelete;
  final String language;
  final bool darkMode;
  final bool autoUpdate;

  AppSettings copyWith({
    String? storageFolder,
    String? fileNamePrefix,
    bool? autoDownload,
    bool? autoDelete,
    String? language,
    bool? darkMode,
    bool? autoUpdate,
  }) {
    return AppSettings(
      storageFolder: storageFolder ?? this.storageFolder,
      fileNamePrefix: fileNamePrefix ?? this.fileNamePrefix,
      autoDownload: autoDownload ?? this.autoDownload,
      autoDelete: autoDelete ?? this.autoDelete,
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
      autoUpdate: autoUpdate ?? this.autoUpdate,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'storageFolder': storageFolder,
      'fileNamePrefix': fileNamePrefix,
      'autoDownload': autoDownload,
      'autoDelete': autoDelete,
      'language': language,
      'darkMode': darkMode,
      'autoUpdate': autoUpdate,
    };
  }

  factory AppSettings.fromJson(Map<String, Object?> json) {
    return AppSettings(
      storageFolder: (json['storageFolder'] as String?) ??
          AppConstants.defaultStorageFolderName,
      fileNamePrefix: (json['fileNamePrefix'] as String?) ??
          AppConstants.defaultFileNamePrefix,
      autoDownload: json['autoDownload'] as bool? ?? true,
      autoDelete: json['autoDelete'] as bool? ?? false,
      language: (json['language'] as String?) ?? 'Indonesia',
      darkMode: json['darkMode'] as bool? ?? true,
      autoUpdate: json['autoUpdate'] as bool? ?? false,
    );
  }
}
