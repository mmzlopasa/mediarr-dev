import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// How large pictures are in the timeline.
enum GridSize {
  small('Small', 0.72),
  medium('Medium', 1),
  large('Large', 1.45);

  const GridSize(this.label, this.scale);

  final String label;
  final double scale;
}

enum AppTheme {
  system('Automatic'),
  light('Light'),
  dark('Dark');

  const AppTheme(this.label);

  final String label;
}

/// What Free up space must leave on the phone, whatever the server holds.
class FreeSpaceRules {
  const FreeSpaceRules({
    this.olderThanDays = 0,
    this.keepFavorites = true,
    this.keepPhotos = false,
    this.keepVideos = false,
    this.keepAlbums = const [],
  });

  factory FreeSpaceRules.fromJson(Map<String, dynamic> json) => FreeSpaceRules(
    olderThanDays: json['olderThanDays'] as int? ?? 0,
    keepFavorites: json['keepFavorites'] as bool? ?? true,
    keepPhotos: json['keepPhotos'] as bool? ?? false,
    keepVideos: json['keepVideos'] as bool? ?? false,
    keepAlbums: [
      for (final id in json['keepAlbums'] as List? ?? const []) id as String,
    ],
  );

  /// 0 means any age.
  final int olderThanDays;
  final bool keepFavorites;
  final bool keepPhotos;
  final bool keepVideos;
  final List<String> keepAlbums;

  Map<String, dynamic> toJson() => {
    'olderThanDays': olderThanDays,
    'keepFavorites': keepFavorites,
    'keepPhotos': keepPhotos,
    'keepVideos': keepVideos,
    'keepAlbums': keepAlbums,
  };

  FreeSpaceRules copyWith({
    int? olderThanDays,
    bool? keepFavorites,
    bool? keepPhotos,
    bool? keepVideos,
    List<String>? keepAlbums,
  }) => FreeSpaceRules(
    olderThanDays: olderThanDays ?? this.olderThanDays,
    keepFavorites: keepFavorites ?? this.keepFavorites,
    keepPhotos: keepPhotos ?? this.keepPhotos,
    keepVideos: keepVideos ?? this.keepVideos,
    keepAlbums: keepAlbums ?? this.keepAlbums,
  );

  bool mayRemove({
    required DateTime taken,
    required DateTime now,
    required bool isVideo,
    required bool isFavorite,
    required bool inKeptAlbum,
  }) {
    if (inKeptAlbum || (keepFavorites && isFavorite)) return false;
    if (isVideo ? keepVideos : keepPhotos) return false;
    if (olderThanDays == 0) return true;
    return now.difference(taken).inDays >= olderThanDays;
  }
}

/// Settings of this phone. Things that differ per device stay on the device.
class AppSettings {
  const AppSettings({
    this.gridSize = GridSize.medium,
    this.theme = AppTheme.system,
    this.readOnly = false,
    this.mirrorAlbums = false,
    this.freeSpace = const FreeSpaceRules(),
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    gridSize: GridSize.values.firstWhere(
      (size) => size.name == json['gridSize'],
      orElse: () => GridSize.medium,
    ),
    theme: AppTheme.values.firstWhere(
      (theme) => theme.name == json['theme'],
      orElse: () => AppTheme.system,
    ),
    readOnly: json['readOnly'] as bool? ?? false,
    mirrorAlbums: json['mirrorAlbums'] as bool? ?? false,
    freeSpace: FreeSpaceRules.fromJson(
      json['freeSpace'] as Map<String, dynamic>? ?? const {},
    ),
  );

  final GridSize gridSize;
  final AppTheme theme;
  final bool readOnly;
  final bool mirrorAlbums;
  final FreeSpaceRules freeSpace;

  Map<String, dynamic> toJson() => {
    'gridSize': gridSize.name,
    'theme': theme.name,
    'readOnly': readOnly,
    'mirrorAlbums': mirrorAlbums,
    'freeSpace': freeSpace.toJson(),
  };

  AppSettings copyWith({
    GridSize? gridSize,
    AppTheme? theme,
    bool? readOnly,
    bool? mirrorAlbums,
    FreeSpaceRules? freeSpace,
  }) => AppSettings(
    gridSize: gridSize ?? this.gridSize,
    theme: theme ?? this.theme,
    readOnly: readOnly ?? this.readOnly,
    mirrorAlbums: mirrorAlbums ?? this.mirrorAlbums,
    freeSpace: freeSpace ?? this.freeSpace,
  );
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  static const _key = 'app_settings';
  static const _storage = FlutterSecureStorage();

  @override
  AppSettings build() {
    unawaited(_load());
    return const AppSettings();
  }

  Future<void> _load() async {
    final saved = await _storage.read(key: _key);
    if (saved == null) return;
    try {
      state = AppSettings.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    } on FormatException {
      // Unreadable settings are the same as none.
    } on TypeError {
      // The same.
    }
  }

  Future<void> change(AppSettings next) async {
    state = next;
    await _storage.write(key: _key, value: jsonEncode(next.toJson()));
  }
}
