import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import 'session.dart';
import 'tus.dart';

enum UploadState { queued, preparing, uploading, done, duplicate, failed }

class UploadTask {
  UploadTask({required this.asset, this.name = ''});

  final AssetEntity asset;
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

  @override
  List<UploadTask> build() => [];

  void _changed() => state = [...state];

  void add(Iterable<AssetEntity> assets) {
    state = [...state, ...assets.map((asset) => UploadTask(asset: asset))];
    _pump();
  }

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
      task.name = await task.asset.titleAsync;
      _changed();
      // The untouched original. iOS may first download it from iCloud.
      final file = await task.asset.originFile;
      if (file == null) {
        throw UploadRejected('This photo could not be read from the device.');
      }
      task.state = UploadState.uploading;
      task.total = await file.length();
      _changed();
      final result = await client.upload(
        file,
        name: task.name,
        lastModifiedMs: task.asset.createDateTime.millisecondsSinceEpoch,
        onProgress: (sent, total) {
          task.sent = sent;
          task.total = total;
          _changed();
        },
      );
      task.state = result.duplicate ? UploadState.duplicate : UploadState.done;
    } catch (cause) {
      task.state = UploadState.failed;
      task.error = cause.toString();
    } finally {
      client.close();
      _changed();
      _pump();
    }
  }
}
