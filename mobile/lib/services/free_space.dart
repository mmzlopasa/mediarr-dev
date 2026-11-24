import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:mediarr_api/api.dart';

import 'backup.dart';

/// The server takes this many checksums in one question.
const checkBatch = 1000;

/// Which of these checksums the server has right now, not in its trash.
Future<Set<String>> checksumsOnServer(
  DefaultApi api,
  List<String> checksums,
) async {
  final onServer = <String>{};
  for (var start = 0; start < checksums.length; start += checkBatch) {
    final answer = await api.checkAssets(
      ChecksumCheckRequest(
        checksums: checksums.sublist(
          start,
          (start + checkBatch).clamp(0, checksums.length),
        ),
      ),
    );
    onServer.addAll([
      for (final checksum in answer?.existing ?? const <String>[])
        checksum.toLowerCase(),
    ]);
  }
  return onServer;
}

/// The SHA-256 of a file, read away from the screen's thread.
Future<String> fileSha256(String path) => Isolate.run(
  () async => (await sha256.bind(File(path).openRead()).first).toString(),
);

/// Of the chosen assets, those that may still leave the phone at this moment. The backup's record
/// and the server are both asked again, as either may have changed since the list was shown. Where
/// a file on the phone can be changed in place after it was sent (on Android), it is read again and
/// has to have a checksum that was sent; [currentChecksum] does that, and null skips the asset.
Future<List<String>> stillSafeToRemove({
  required List<String> ids,
  required Future<Map<String, List<String>>> Function() verified,
  required Future<Set<String>> Function(List<String> checksums) onServer,
  Future<String?> Function(String id)? currentChecksum,
}) async {
  final record = await verified();
  final chosen = {
    for (final id in ids)
      if (record[id]?.isNotEmpty ?? false)
        id: [for (final sum in record[id]!) sum.toLowerCase()],
  };
  final found = await onServer(
    {for (final sums in chosen.values) ...sums}.toList(),
  );
  final out = <String>[];
  for (final id in safeToRemove(chosen, found)) {
    if (currentChecksum != null) {
      final String? now;
      try {
        now = (await currentChecksum(id))?.toLowerCase();
      } on Object {
        continue;
      }
      if (now == null || !chosen[id]!.contains(now)) continue;
    }
    out.add(id);
  }
  return out;
}
