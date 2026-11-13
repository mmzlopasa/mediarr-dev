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
enum WidgetInstallVerdict { missing, unsigned, fine, unknown }

class WidgetInstall {
  const WidgetInstall(this.facts);

  final Map<Object?, Object?> facts;

  String _text(String key) => facts[key]?.toString() ?? '';

  String get appId => _text('appId');
  String get widgetId => _text('widgetId');

  /// The keychain group the app writes the widget's album to.
  String get group => _text('group');

  WidgetInstallVerdict get verdict {
    if (facts['present'] == false) return WidgetInstallVerdict.missing;
    if (facts['present'] != true) return WidgetInstallVerdict.unknown;
    if (facts['signed'] == false) return WidgetInstallVerdict.unsigned;
    // Which profile signed it says nothing for sure: iOS has offered a widget signed with a
    // profile made for another identifier.
    return WidgetInstallVerdict.fine;
  }
}

/// The name the widget's key has on the server. It stays in English there, and the app shows it
/// in the chosen language with [apiKeyLabel].
const widgetKeyName = 'Home screen widget';

/// A key's name as the API keys list shows it.
String apiKeyLabel(String name) =>
    name == widgetKeyName ? l.homeWidgetKeyName : name;

/// The home screen widget shows an album the user chooses. It reads it with a key of its own that
/// can only read, so a widget never holds more than it needs.
class HomeWidgetService {
  static const _channel = MethodChannel('app.mediarr/widget');
  static const _keyId = 'widget_key_id';
  static const _storage = FlutterSecureStorage();

  /// Nothing chosen when the phone cannot say; the screen still lets the user choose.
  Future<WidgetChoice> status() async {
    try {
      return WidgetChoice.fromMap(
        await _channel.invokeMapMethod<Object?, Object?>('status'),
      );
    } on MissingPluginException {
      return const WidgetChoice();
    } on PlatformException {
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
    // A new key each time, made before the old one goes: if it cannot be made, the widget keeps
    // showing what it showed.
    final key = await session.api.createAPIKey(
      ApiKeyCreate(name: widgetKeyName, scopes: [ApiKeyCreateScopesEnum.read]),
    );
    if (key == null) {
      throw ApiException(500, l.homeWidgetNoKey);
    }
    try {
      await _channel.invokeMethod<void>('configure', {
        'server': session.serverUrl,
        'key': key.key,
        'albumId': album.id,
        'albumTitle': album.title,
      });
    } on PlatformException {
      // The widget cannot read it, so the key is of no use to anyone.
      await _revokeId(session, key.id);
      throw ApiException(500, l.homeWidgetNoShare);
    }
    // The widget holds the new key now, so only one is ever in use.
    final old = await _storage.read(key: _keyId);
    await _storage.write(key: _keyId, value: key.id);
    if (old != null && old != key.id) await _revokeId(session, old);
  }

  Future<void> clear(Session session) async {
    await _channel.invokeMethod<void>('clear');
    await _revoke(session);
  }

  /// On signing out: the phone forgets the server and the key, and the server stops accepting it.
  /// Works without a widget and without a connection.
  Future<void> forget(Session? session) async {
    try {
      await _channel.invokeMethod<void>('clear');
    } on MissingPluginException {
      // No widget on this platform.
    } on PlatformException {
      // Nothing was handed over.
    }
    if (session != null) {
      await _revoke(session);
    } else {
      await _storage.delete(key: _keyId);
    }
  }

  Future<void> _revoke(Session session) async {
    final id = await _storage.read(key: _keyId);
    if (id == null) return;
    await _revokeId(session, id);
    await _storage.delete(key: _keyId);
  }

  Future<void> _revokeId(Session session, String id) async {
    try {
      await session.api.revokeDeviceKey(id);
    } on ApiException {
      // Already gone, or the server cannot be reached.
    }
  }
}
