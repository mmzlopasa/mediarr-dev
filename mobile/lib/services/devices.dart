import 'dart:io';

import 'package:mediarr_api/api.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:photo_manager/photo_manager.dart';

import 'backup.dart';

/// How many checksums go in one report: the server takes at most 5000.
const reportChunk = 5000;

/// The checksums of every file the phone has seen confirmed, each once.
List<String> uniqueChecksums(Map<String, List<String>> verified) {
  final seen = <String>{};
  return [
    for (final sums in verified.values)
      for (final sum in sums)
        if (seen.add(sum.toLowerCase())) sum.toLowerCase(),
  ];
}

/// The checksums in reports of at most [size], so a large library is sent in parts.
List<List<String>> chunked(List<String> all, {int size = reportChunk}) => [
  for (var i = 0; i < all.length; i += size)
    all.sublist(i, i + size > all.length ? all.length : i + size),
];

/// What a failed file is called on the phone, for the list of what is missing.
Future<String> _nameOf(String assetId) async {
  try {
    final asset = await AssetEntity.fromId(assetId);
    final title = asset == null ? null : await asset.titleAsync;
    if (title != null && title.isNotEmpty) return title;
  } on Exception {
    // The name is only for people to recognise it.
  }
  return assetId;
}

/// Tells the server how backup on this phone is doing, and gives it the checksums of what is
/// confirmed so the server can count for itself. The full list goes only when the server's count of
/// them differs from the phone's, so most reports are a few hundred bytes.
Future<BackupDevice?> reportThisDevice(
  DefaultApi api,
  BackupService backup, {
  BackupStatus? status,
}) async {
  final now = status ?? await backup.status();
  final id = now.deviceId;
  if (!now.enabled || id == null || id.isEmpty) return null;
  final version = (await PackageInfo.fromPlatform()).version;
  final failures = [
    for (final failure in now.failures.take(100))
      BackupDeviceFailure(
        name: await _nameOf(failure.assetId),
        reason: failure.error,
      ),
  ];
  BackupDeviceReport report({List<String>? checksums, bool? replace}) =>
      BackupDeviceReport(
        name: now.deviceName.isEmpty
            ? (Platform.isIOS ? 'iPhone' : 'Android')
            : now.deviceName,
        platform: Platform.isIOS ? 'ios' : 'android',
        appVersion: version,
        pending: now.pending,
        working: now.working,
        verified: now.verified,
        failed: now.failed,
        failures: failures,
        checksums: checksums ?? const [],
        replace: replace,
      );

  var device = await api.reportBackupDevice(id, report());
  final sums = uniqueChecksums(await backup.verifiedChecksums());
  if (device == null || device.files == sums.length) return device;
  final parts = chunked(sums);
  if (parts.isEmpty) parts.add(const []);
  for (var i = 0; i < parts.length; i++) {
    device = await api.reportBackupDevice(
      id,
      report(checksums: parts[i], replace: i == 0),
    );
  }
  return device;
}
