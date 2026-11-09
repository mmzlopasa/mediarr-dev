import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mediarr_api/api.dart';

import 'session.dart';
import '../l10n/l10n.dart';

class BackupAlbum {
  BackupAlbum({required this.id, required this.title, required this.count});

  final String id;
  final String title;
  final int count;
}

class PhoneAlbum {
  const PhoneAlbum(this.title, this.checksums);

  final String title;
  final List<String> checksums;
}

class BackupFailure {
  BackupFailure(this.assetId, this.error);

  final String assetId;
  final String error;
}

List<String> _strings(Object? value) => [
  if (value is List)
    for (final item in value) item.toString(),
];

/// What the native backup engine reports. All of it is counted on the device.
class BackupStatus {
  const BackupStatus({
    this.enabled = false,
    this.wifiOnly = true,
    this.chargingOnly = false,
    this.moreAlbums = const [],
    this.excludedAlbums = const [],
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
    this.deviceId,
    this.deviceName = '',
  });

  factory BackupStatus.fromMap(Map<Object?, Object?> map) => BackupStatus(
    enabled: map['enabled'] == true,
    wifiOnly: map['wifiOnly'] != false,
    chargingOnly: map['chargingOnly'] == true,
    moreAlbums: _strings(map['moreAlbums']),
    excludedAlbums: _strings(map['excludedAlbums']),
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
    deviceId: map['deviceId']?.toString(),
    deviceName: map['deviceName']?.toString() ?? '',
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
  final bool chargingOnly;
  final List<String> moreAlbums;
  final List<String> excludedAlbums;
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

  /// This phone among the devices the server lists; the native engine made it up when backup was
  /// first turned on, and also reports with it on its own.
  final String? deviceId;
  final String deviceName;

  int get total => pending + working + verified + failed;
}

class WaitingAsset {
  const WaitingAsset(this.id, this.status);

  final String id;
  final String status;
}

/// Only what the server confirms having right now may leave the phone: every file of the asset has
/// to be on it. A photo deleted from the server since it was sent is no longer there.
List<String> safeToRemove(
  Map<String, List<String>> verified,
  Set<String> onServer,
) => [
  for (final entry in verified.entries)
    if (entry.value.isNotEmpty && entry.value.every(onServer.contains))
      entry.key,
];

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

  /// Assets whose files are all verified, with the checksum of each file.
  Future<Map<String, List<String>>> verifiedChecksums() async {
    final map = await _channel.invokeMapMethod<String, List<Object?>>(
      'verifiedChecksums',
    );
    return {
      for (final entry in (map ?? const <String, List<Object?>>{}).entries)
        entry.key: entry.value.map((value) => value.toString()).toList(),
    };
  }

  /// Photos in the chosen album that are not on the server yet, newest first.
  Future<List<WaitingAsset>> waiting({int limit = 60}) async {
    final list = await _channel.invokeListMethod<Object?>('waiting', {
      'limit': limit,
    });
    final seen = <String>{};
    return [
      for (final raw in list ?? const <Object?>[])
        if (raw is Map && seen.add(raw['id'].toString()))
          WaitingAsset(raw['id'].toString(), raw['status'].toString()),
    ];
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
      CreateDeviceKeyRequest(name: Platform.isIOS ? 'iPhone' : 'Android'),
    );
    if (key == null) {
      throw ApiException(500, l.backupNoDeviceKey);
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

  Future<void> setChargingOnly(bool value) =>
      _channel.invokeMethod<void>('setChargingOnly', {'value': value});

  Future<void> setAlbumLists({
    required List<String> more,
    required List<String> excluded,
    required bool onlyNew,
  }) => _channel.invokeMethod<void>('setAlbumLists', {
    'more': more,
    'excluded': excluded,
    'onlyNew': onlyNew,
  });

  /// Each chosen album on this phone, with the checksums already safe on the server.
  Future<List<PhoneAlbum>> albumChecksums() async {
    final list = await _channel.invokeListMethod<Object?>('albumChecksums');
    return [
      for (final raw in list ?? const <Object?>[])
        if (raw is Map)
          PhoneAlbum(
            raw['title']?.toString() ?? '',
            _strings(raw['checksums']),
          ),
    ];
  }

  Future<void> setServer(String server) =>
      _channel.invokeMethod<void>('setServer', {'value': server});

  Future<void> retryFailed() => _channel.invokeMethod<void>('retryFailed');
}

const _syncBatch = 1000;

/// Makes the server's albums follow the phone's, one way: photos are added, and nothing is removed.
/// Returns how many albums were looked at.
Future<int> mirrorAlbums(DefaultApi api, List<PhoneAlbum> phone) async {
  final existing = [...?await api.listAlbums()];
  var done = 0;
  for (final album in phone) {
    if (album.title.isEmpty || album.checksums.isEmpty) continue;
    final ids = <String>{};
    for (var start = 0; start < album.checksums.length; start += _syncBatch) {
      final answer = await api.checkAssets(
        ChecksumCheckRequest(
          checksums: album.checksums.sublist(
            start,
            (start + _syncBatch).clamp(0, album.checksums.length),
          ),
        ),
      );
      ids.addAll(answer?.ids.values ?? const <String>[]);
    }
    if (ids.isEmpty) continue;
    var id = _ownAlbum(existing, album.title);
    if (id == null) {
      final created = await api.createAlbum(AlbumCreate(title: album.title));
      if (created == null) continue;
      existing.add(created);
      id = created.id;
    }
    final all = ids.toList();
    for (var start = 0; start < all.length; start += _syncBatch) {
      await api.addAlbumAssets(
        id,
        AssetIds(
          ids: all.sublist(start, (start + _syncBatch).clamp(0, all.length)),
        ),
      );
    }
    done++;
  }
  return done;
}

String? _ownAlbum(List<Album> albums, String title) {
  for (final album in albums) {
    if (album.title == title &&
        !album.isSmart &&
        album.role == AlbumRoleEnum.owner) {
      return album.id;
    }
  }
  return null;
}
