import 'dart:io';
import 'dart:ui' show Rect;

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import 'session.dart';

/// The address of the file the server gives to send or save an asset: its original, or a smaller
/// JPEG for messages.
String shareUrl(Session session, String id, {bool small = false}) =>
    '${session.serverUrl}/api/assets/$id/share${small ? '?small=true' : ''}';

/// The name a file arrives with, from Content-Disposition, made safe for the disk.
String fileNameFrom(String? disposition, String fallback) {
  final match = RegExp(
    r'''filename\*?=(?:UTF-8'')?"?([^";]+)"?''',
    caseSensitive: false,
  ).firstMatch(disposition ?? '');
  final raw = Uri.decodeComponent(match?.group(1) ?? fallback);
  final safe = p
      .basename(raw)
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_');
  return safe.isEmpty || safe == '.' || safe == '..' ? fallback : safe;
}

/// Downloads assets into a folder of their own under the temporary directory, which is emptied
/// before each use, so nothing sent stays on the phone. [onProgress] gets how many are done.
Future<List<File>> fetchForSharing(
  Session session,
  List<String> ids, {
  bool small = false,
  void Function(int done, int total)? onProgress,
  bool Function()? cancelled,
}) async {
  final dir = Directory(p.join((await getTemporaryDirectory()).path, 'share'));
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);
  final client = http.Client();
  final files = <File>[];
  try {
    for (var i = 0; i < ids.length; i++) {
      if (cancelled?.call() ?? false) break;
      final request = http.Request(
        'GET',
        Uri.parse(shareUrl(session, ids[i], small: small)),
      )..headers.addAll(session.headers);
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw HttpException('The server answered ${response.statusCode}');
      }
      var name = fileNameFrom(response.headers['content-disposition'], ids[i]);
      // Two photos can have the same name; each keeps its own file.
      if (files.any((file) => p.basename(file.path) == name)) {
        name = '${p.basenameWithoutExtension(name)}-$i${p.extension(name)}';
      }
      final file = File(p.join(dir.path, name));
      await response.stream.pipe(file.openWrite());
      files.add(file);
      onProgress?.call(i + 1, ids.length);
    }
  } finally {
    client.close();
  }
  return files;
}

/// Opens the system's sheet to send the files to another app. On an iPad it opens from [origin].
Future<void> shareFiles(List<File> files, {Rect? origin}) =>
    SharePlus.instance.share(
      ShareParams(
        files: [for (final file in files) XFile(file.path)],
        sharePositionOrigin: origin,
      ),
    );

/// Saves the files in the phone's own gallery, as photos or videos by their kind.
Future<void> saveToPhone(List<File> files) async {
  final permission = await PhotoManager.requestPermissionExtend(
    requestOption: const PermissionRequestOption(
      androidPermission: AndroidPermission(
        type: RequestType.common,
        mediaLocation: false,
      ),
    ),
  );
  if (!permission.hasAccess) {
    throw const FileSystemException('Mediarr may not add photos to this phone');
  }
  for (final file in files) {
    final name = p.basename(file.path);
    if (isVideoName(name)) {
      await PhotoManager.editor.saveVideo(file, title: name);
    } else {
      await PhotoManager.editor.saveImageWithPath(file.path, title: name);
    }
  }
}

/// Whether a file is a video by its name.
bool isVideoName(String name) => const {
  '.mp4',
  '.mov',
  '.m4v',
  '.3gp',
  '.mkv',
  '.webm',
  '.avi',
}.contains(p.extension(name).toLowerCase());
