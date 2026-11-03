import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mediarr_api/api.dart';

import 'session.dart';

class BackupAlbum {
  BackupAlbum({required this.id, required this.title, required this.count});

  final String id;
  final String title;
  final int count;
}

class BackupFailure {
  BackupFailure(this.assetId, this.error);

  final String assetId;
  final String error;
}

/// What the native backup engine reports. All of it is counted on the device.
class BackupStatus {
  const BackupStatus({
    this.enabled = false,
    this.wifiOnly = true,
    this.unauthorized = false,
    this.pending = 0,
    this.working = 0,
    this.verified = 0,
    this.failed = 0,
    this.lastFinished,
    this.failures = const [],
    this.albumName = '',
    this.albumFound = false,
    this.limitedAccess = false,
  });

  factory BackupStatus.fromMap(Map<Object?, Object?> map) => BackupStatus(
    enabled: map['enabled'] == true,
    wifiOnly: map['wifiOnly'] != false,
    unauthorized: map['unauthorized'] == true,
    pending: (map['pending'] as num?)?.toInt() ?? 0,
    working: (map['working'] as num?)?.toInt() ?? 0,
    verified: (map['verified'] as num?)?.toInt() ?? 0,
    failed: (map['failed'] as num?)?.toInt() ?? 0,
    lastFinished: switch (map['lastFinished']) {
      final num seconds => DateTime.fromMillisecondsSinceEpoch(
        (seconds * 1000).round(),
      ),
      _ => null,
    },
    albumName: map['albumName']?.toString() ?? '',
    albumFound: map['albumFound'] == true,
    limitedAccess: map['limitedAccess'] == true,
    failures: [
      for (final raw in (map['failures'] as List<Object?>?) ?? const [])
        if (raw is Map)
          BackupFailure(
            raw['id']?.toString() ?? '',
            raw['error']?.toString() ?? '',
          ),
    ],
  );

  final bool enabled;
  final bool wifiOnly;
  final bool unauthorized;
  final int pending;
  final int working;
  final int verified;
  final int failed;
  final DateTime? lastFinished;
  final List<BackupFailure> failures;
  final String albumName;
  final bool albumFound;
  final bool limitedAccess;

  int get total => pending + working + verified + failed;
}

final backupProvider = Provider<BackupService>((ref) => BackupService());

class BackupService {
  static const _channel = MethodChannel('app.mediarr/backup');
  static const _keyIdKey = 'device_key_id';
  static const _storage = FlutterSecureStorage();

  Future<BackupStatus> status() async {
    final map = await _channel.invokeMapMethod<Object?, Object?>('status');
    return map == null ? const BackupStatus() : BackupStatus.fromMap(map);
  }

  /// The backup state of each asset: pending, exporting, uploading, verified or failed.
  Future<Map<String, String>> statuses(List<String> ids) async {
    final map = await _channel.invokeMapMethod<String, String>('statuses', {
      'ids': ids,
    });
    return map ?? const {};
  }

  /// Background work outlives a session, so it gets its own long-lived key for this device.
  Future<void> enable(
    Session session, {
    required bool wifiOnly,
    required bool onlyNew,
    required String? albumId,
    required String albumName,
  }) async {
    final key = await session.api.createDeviceKey(
      CreateDeviceKeyRequest(name: 'iPhone'),
    );
    if (key == null) {
      throw ApiException(500, 'The server did not create a device key.');
    }
    await _storage.write(key: _keyIdKey, value: key.id);
    await _channel.invokeMethod<void>('enable', {
      'server': session.serverUrl,
      'key': key.key,
      'wifiOnly': wifiOnly,
      'onlyNew': onlyNew,
      'albumId': albumId,
      'albumName': albumName,
    });
  }

  Future<List<BackupAlbum>> albums() async {
    final list = await _channel.invokeListMethod<Object?>('albums');
    return [
      for (final raw in list ?? const <Object?>[])
        if (raw is Map)
          BackupAlbum(
            id: raw['id']?.toString() ?? '',
            title: raw['title']?.toString() ?? '',
            count: (raw['count'] as num?)?.toInt() ?? 0,
          ),
    ];
  }

  Future<void> setAlbum({
    required String? albumId,
    required String albumName,
    required bool onlyNew,
  }) => _channel.invokeMethod<void>('setAlbum', {
    'albumId': albumId,
    'albumName': albumName,
    'onlyNew': onlyNew,
  });

  /// Stops the backup and removes the key from the device and the server.
  Future<void> disable(Session? session) async {
    await _channel.invokeMethod<void>('disable');
    final id = await _storage.read(key: _keyIdKey);
    await _storage.delete(key: _keyIdKey);
    if (id != null && session != null) {
      try {
        await session.api.revokeDeviceKey(id);
      } on ApiException {
        // Signing out must work offline. The device has already forgotten the key.
      }
    }
  }

  Future<void> setWifiOnly(bool value) =>
      _channel.invokeMethod<void>('setWifiOnly', {'value': value});

  Future<void> retryFailed() => _channel.invokeMethod<void>('retryFailed');
}
