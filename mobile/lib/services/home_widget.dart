import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mediarr_api/api.dart';

import 'session.dart';
import '../l10n/l10n.dart';

/// What the home screen widget shows now.
class WidgetChoice {
  const WidgetChoice({this.albumId, this.albumTitle = '', this.pictures = 0});

  factory WidgetChoice.fromMap(Map<Object?, Object?>? map) => WidgetChoice(
    albumId: map?['albumId']?.toString(),
    albumTitle: map?['albumTitle']?.toString() ?? '',
    pictures: (map?['pictures'] as num?)?.toInt() ?? 0,
  );

  final String? albumId;
  final String albumTitle;

  /// Pictures kept on the phone for it, where the phone says.
  final int pictures;

  bool get chosen => albumId != null && albumId!.isNotEmpty;
}

/// The home screen widget shows an album the user chooses. It reads it with a key of its own that
/// can only read, so a widget never holds more than it needs.
class HomeWidgetService {
  static const _channel = MethodChannel('app.mediarr/widget');
  static const _keyId = 'widget_key_id';
  static const _storage = FlutterSecureStorage();

  Future<WidgetChoice> status() async {
    try {
      return WidgetChoice.fromMap(
        await _channel.invokeMapMethod<Object?, Object?>('status'),
      );
    } on MissingPluginException {
      return const WidgetChoice();
    }
  }

  Future<void> choose(Session session, Album album) async {
    // A new key each time: the old one goes, so only one is ever in use.
    await _revoke(session);
    final key = await session.api.createAPIKey(
      ApiKeyCreate(
        name: 'Home screen widget',
        scopes: [ApiKeyCreateScopesEnum.read],
      ),
    );
    if (key == null) {
      throw ApiException(500, l.homeWidgetNoKey);
    }
    await _storage.write(key: _keyId, value: key.id);
    await _channel.invokeMethod<void>('configure', {
      'server': session.serverUrl,
      'key': key.key,
      'albumId': album.id,
      'albumTitle': album.title,
    });
  }

  Future<void> clear(Session session) async {
    await _channel.invokeMethod<void>('clear');
    await _revoke(session);
  }

  Future<void> _revoke(Session session) async {
    final id = await _storage.read(key: _keyId);
    if (id == null) return;
    try {
      await session.api.revokeDeviceKey(id);
    } on ApiException {
      // Already gone.
    }
    await _storage.delete(key: _keyId);
  }
}
