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

/// What iOS was given of the widget, after the phone signed the app again.
enum WidgetInstallVerdict { missing, unsigned, wrongProfile, fine, unknown }

class WidgetInstall {
  const WidgetInstall(this.facts);

  final Map<Object?, Object?> facts;

  String _text(String key) => facts[key]?.toString() ?? '';

  String get appId => _text('appId');
  String get widgetId => _text('widgetId');

  /// The profile's app identifier without the team in front, such as `*` or `app.mediarr.*`.
  String get profileId {
    final full = _text('widgetProfile').isNotEmpty
        ? _text('widgetProfile')
        : _text('appProfile');
    final dot = full.indexOf('.');
    return dot < 0 ? full : full.substring(dot + 1);
  }

  WidgetInstallVerdict get verdict {
    if (facts['present'] == false) return WidgetInstallVerdict.missing;
    if (facts['present'] != true) return WidgetInstallVerdict.unknown;
    if (facts['signed'] == false) return WidgetInstallVerdict.unsigned;
    final id = profileId;
    if (id.isEmpty) return WidgetInstallVerdict.fine;
    final allowed =
        id == '*' ||
        id == widgetId ||
        (id.endsWith('.*') &&
            widgetId.startsWith(id.substring(0, id.length - 1)));
    return allowed
        ? WidgetInstallVerdict.fine
        : WidgetInstallVerdict.wrongProfile;
  }
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

  /// Only iOS answers; elsewhere there is nothing to check.
  Future<WidgetInstall?> install() async {
    try {
      final facts = await _channel.invokeMapMethod<Object?, Object?>('install');
      return facts == null ? null : WidgetInstall(facts);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
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
