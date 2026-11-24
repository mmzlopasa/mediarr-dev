import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import 'session.dart';
import 'shared_files.dart';
import 'tus.dart';
import '../l10n/l10n.dart';

enum UploadState { queued, preparing, uploading, done, duplicate, failed }

/// The video of an iOS Live Photo, or null for any other asset.
Future<File?> livePhotoVideo(AssetEntity asset, File still) async {
  if (!Platform.isIOS || !asset.isLivePhoto) return null;
  final video = await asset.originFileWithSubtype;
  if (video == null || video.path == still.path) return null;
  return isVideoPath(video.path) ? video : null;
}

bool isVideoPath(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.mov') || lower.endsWith('.mp4');
}

/// The video's name has the still's name before the dot, as on the phone: IMG_0001.HEIC goes with
/// IMG_0001.MOV.
String livePhotoVideoName(String stillName, String videoPath) {
  final dot = stillName.lastIndexOf('.');
  final base = dot > 0 ? stillName.substring(0, dot) : stillName;
  final file = videoPath.substring(videoPath.lastIndexOf('/') + 1);
  final at = file.lastIndexOf('.');
  final extension = at > 0 ? file.substring(at + 1).toUpperCase() : 'MOV';
  return '$base.$extension';
}

class UploadTask {
  UploadTask({this.asset, this.sharedFile, this.name = '', this.albumId});

  /// From the phone's library.
  final AssetEntity? asset;

  /// Sent from another app. This copy is removed once it has been handled.
  final File? sharedFile;
  final String? albumId;
  String name;
  UploadState state = UploadState.queued;
  int sent = 0;
  int total = 0;
  String? error;

  double get progress => total == 0 ? 0 : sent / total;
  bool get active =>
      state == UploadState.preparing || state == UploadState.uploading;
  bool get finished =>
      state == UploadState.done ||
      state == UploadState.duplicate ||
      state == UploadState.failed;
}

final uploadsProvider = NotifierProvider<UploadsNotifier, List<UploadTask>>(
  UploadsNotifier.new,
);

/// Sends the chosen photos, a few at a time, while the app is open.
class UploadsNotifier extends Notifier<List<UploadTask>> {
  static const _maxParallel = 2;

  /// A sent file stays a moment with its tick, then goes; one that failed stays, with its error.
  static const doneLinger = Duration(milliseconds: 1500);

  @override
  List<UploadTask> build() => [];

  void _changed() {
    if (ref.mounted) state = [...state];
  }

  void add(Iterable<AssetEntity> assets, {String? albumId}) {
    // One chosen twice while it is still on its way is sent once.
    final waiting = {
      for (final task in state)
        if (!task.finished && task.asset != null) task.asset!.id,
    };
    state = [
      ...state,
      for (final asset in assets)
        if (waiting.add(asset.id)) UploadTask(asset: asset, albumId: albumId),
    ];
    _pump();
  }

  void addShared(Iterable<File> files) {
    state = [
      ...state,
      ...files.map(
        (file) => UploadTask(sharedFile: file, name: sharedFileName(file.path)),
      ),
    ];
    _pump();
  }

  /// Takes away the ones that failed; the sent ones go by themselves.
  void clearFinished() {
    state = state.where((task) => !task.finished).toList();
  }

  void _pump() {
    final session = ref.read(sessionProvider).value;
    if (session == null) return;
    final running = state.where((task) => task.active).length;
    final queued = state.where((task) => task.state == UploadState.queued);
    for (final task in queued.take(_maxParallel - running).toList()) {
      _run(task, session);
    }
  }

  Future<void> _run(UploadTask task, Session session) async {
    task.state = UploadState.preparing;
    _changed();
    final client = TusClient(
      baseUrl: session.serverUrl,
      headers: session.headers,
    );
    try {
      final asset = task.asset;
      if (asset != null) task.name = await asset.titleAsync;
      _changed();
      // The untouched original. iOS may first download it from iCloud.
      final file = task.sharedFile ?? await asset?.originFile;
      if (file == null) {
        throw UploadRejected(l.uploadsCouldNotRead);
      }
      task.state = UploadState.uploading;
      task.total = await file.length();
      _changed();
      final result = await client.upload(
        file,
        name: task.name,
        lastModifiedMs: (asset?.createDateTime ?? await file.lastModified())
            .millisecondsSinceEpoch,
        albumId: task.albumId,
        onProgress: (sent, total) {
          task.sent = sent;
          task.total = total;
          _changed();
        },
      );
      // A Live Photo's moving part goes as its own file, the way the backup sends it; the server
      // pairs the two by the identifier both carry.
      final motion = asset == null ? null : await livePhotoVideo(asset, file);
      var duplicate = result.duplicate;
      if (motion != null) {
        final video = await client.upload(
          motion,
          name: livePhotoVideoName(task.name, motion.path),
          lastModifiedMs: asset!.createDateTime.millisecondsSinceEpoch,
          albumId: task.albumId,
        );
        duplicate = duplicate && video.duplicate;
      }
      task.state = duplicate ? UploadState.duplicate : UploadState.done;
      await _removeShared(task);
      Future<void>.delayed(doneLinger, () {
        if (ref.mounted && state.contains(task)) {
          state = state.where((other) => other != task).toList();
        }
      });
    } catch (cause) {
      task.state = UploadState.failed;
      task.error = cause.toString();
    } finally {
      client.close();
      _changed();
      if (ref.mounted) _pump();
    }
  }

  Future<void> _removeShared(UploadTask task) async {
    try {
      await task.sharedFile?.delete();
    } on FileSystemException {
      // iOS cleans its inbox up by itself.
    }
  }
}
