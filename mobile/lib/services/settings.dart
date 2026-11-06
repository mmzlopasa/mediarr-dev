import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const minPerRow = 2;
const maxPerRow = 6;

enum AppAccent {
  // Light blue, the default; buttons stay gold whatever is chosen here.
  blue('Light blue', 0xFFC4BBFF, 0xFF5A49E6),
  gold('Gold', 0xFFFFD76A, 0xFF8A6500),
  violet('Violet', 0xFF8B7CFF, 0xFF5A49E6),
  mint('Mint', 0xFF8EF0C8, 0xFF0B8F69),
  rose('Rose', 0xFFFF9AC8, 0xFFD6489C);

  const AppAccent(this.label, this.onDark, this.onLight);

  final String label;
  final int onDark;
  final int onLight;
}

enum AppTheme {
  system('Auto'),
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
    this.perRow = 4,
    this.groupByDay = true,
    this.loadOriginal = true,
    this.tapToNavigate = false,
    this.autoPlay = true,
    this.loopVideos = false,
    this.forceOriginalVideo = true,
    this.haptics = true,
    this.accent = AppAccent.blue,
    this.theme = AppTheme.system,
    this.readOnly = false,
    this.mirrorAlbums = false,
    this.freeSpace = const FreeSpaceRules(),
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    perRow: ((json['perRow'] as int?) ?? 4).clamp(minPerRow, maxPerRow),
    groupByDay: json['groupByDay'] as bool? ?? true,
    loadOriginal: json['loadOriginal'] as bool? ?? true,
    tapToNavigate: json['tapToNavigate'] as bool? ?? false,
    autoPlay: json['autoPlay'] as bool? ?? true,
    loopVideos: json['loopVideos'] as bool? ?? false,
    forceOriginalVideo: json['forceOriginalVideo'] as bool? ?? true,
    haptics: json['haptics'] as bool? ?? true,
    accent: AppAccent.values.firstWhere(
      (accent) => accent.name == json['accent'],
      orElse: () => AppAccent.blue,
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

  final int perRow;
  final bool groupByDay;
  final bool loadOriginal;
  final bool tapToNavigate;
  final bool autoPlay;
  final bool loopVideos;
  final bool forceOriginalVideo;
  final bool haptics;
  final AppAccent accent;
  final AppTheme theme;
  final bool readOnly;
  final bool mirrorAlbums;
  final FreeSpaceRules freeSpace;

  Map<String, dynamic> toJson() => {
    'perRow': perRow,
    'groupByDay': groupByDay,
    'loadOriginal': loadOriginal,
    'tapToNavigate': tapToNavigate,
    'autoPlay': autoPlay,
    'loopVideos': loopVideos,
    'forceOriginalVideo': forceOriginalVideo,
    'haptics': haptics,
    'accent': accent.name,
    'theme': theme.name,
    'readOnly': readOnly,
    'mirrorAlbums': mirrorAlbums,
    'freeSpace': freeSpace.toJson(),
  };

  AppSettings copyWith({
    int? perRow,
    bool? groupByDay,
    bool? loadOriginal,
    bool? tapToNavigate,
    bool? autoPlay,
    bool? loopVideos,
    bool? forceOriginalVideo,
    bool? haptics,
    AppAccent? accent,
    AppTheme? theme,
    bool? readOnly,
    bool? mirrorAlbums,
    FreeSpaceRules? freeSpace,
  }) => AppSettings(
    perRow: perRow ?? this.perRow,
    groupByDay: groupByDay ?? this.groupByDay,
    loadOriginal: loadOriginal ?? this.loadOriginal,
    tapToNavigate: tapToNavigate ?? this.tapToNavigate,
    autoPlay: autoPlay ?? this.autoPlay,
    loopVideos: loopVideos ?? this.loopVideos,
    forceOriginalVideo: forceOriginalVideo ?? this.forceOriginalVideo,
    haptics: haptics ?? this.haptics,
    accent: accent ?? this.accent,
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
