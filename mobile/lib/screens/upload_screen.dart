import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../services/backup.dart';
import '../services/uploads.dart';
import '../theme.dart';
import 'backup_card.dart';

/// Picks directly from the photo library, which gives the untouched originals.
class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  static const _pageSize = 120;

  PermissionState? _permission;
  AssetPathEntity? _album;
  final _assets = <AssetEntity>[];
  final _selected = <String, AssetEntity>{};
  bool _loading = false;
  bool _reachedEnd = false;
  int _page = 0;
  Map<String, String> _backup = const {};
  bool _backupOn = false;

  Future<void> _open() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!mounted) return;
    setState(() => _permission = permission);
    if (!permission.hasAccess) return;
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
    );
    if (!mounted) return;
    setState(() {
      _album = albums.isEmpty ? null : albums.first;
      _assets.clear();
      _page = 0;
      _reachedEnd = albums.isEmpty;
    });
    await _more();
  }

  Future<void> _more() async {
    final album = _album;
    if (album == null || _loading || _reachedEnd) return;
    _loading = true;
    final page = await album.getAssetListPaged(page: _page, size: _pageSize);
    if (!mounted) return;
    setState(() {
      _assets.addAll(page);
      _page += 1;
      _reachedEnd = page.length < _pageSize;
      _loading = false;
    });
  }

  /// Shows each photo's backup state in the gallery.
  Future<void> _refreshBadges(BackupStatus status) async {
    _backupOn = status.enabled;
    if (!status.enabled || _assets.isEmpty) {
      if (_backup.isNotEmpty && mounted) setState(() => _backup = const {});
      return;
    }
    final map = await ref
        .read(backupProvider)
        .statuses(_assets.map((asset) => asset.id).toList());
    if (mounted) setState(() => _backup = map);
  }

  void _send() {
    ref.read(uploadsProvider.notifier).add(_selected.values.toList());
    setState(_selected.clear);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tasks = ref.watch(uploadsProvider);
    final permission = _permission;

    Widget gallery;
    if (permission == null) {
      gallery = EmptyMessage(
        icon: Icons.photo_library_outlined,
        text: 'Choose photos and videos from this device to upload them.',
        action: GoldButton(
          label: 'Open photo library',
          icon: Icons.photo_library_outlined,
          onPressed: _open,
        ),
      );
    } else if (!permission.hasAccess) {
      gallery = EmptyMessage(
        icon: Icons.lock_outline,
        text: 'Mediarr needs access to your photos. Allow it in Settings.',
        action: GoldButton(
          label: 'Open Settings',
          onPressed: PhotoManager.openSetting,
        ),
      );
    } else if (_assets.isEmpty) {
      gallery = _reachedEnd
          ? const EmptyMessage(
              icon: Icons.photo_outlined,
              text: 'There are no photos on this device.',
            )
          : const Center(child: CircularProgressIndicator(color: Palette.gold));
    } else {
      gallery = NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 800) _more();
          return false;
        },
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 90),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 120,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: _assets.length,
          itemBuilder: (context, index) {
            final asset = _assets[index];
            final isSelected = _selected.containsKey(asset.id);
            return GestureDetector(
              onTap: () => setState(() {
                if (_selected.remove(asset.id) == null) {
                  _selected[asset.id] = asset;
                }
              }),
              child: _AssetThumb(
                asset: asset,
                selected: isSelected,
                backup: _backupOn ? _backup[asset.id] : null,
              ),
            );
          },
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Text('Upload', style: text.headlineMedium),
              ),
              BackupCard(onStatus: _refreshBadges),
              if (tasks.isNotEmpty) _TaskList(tasks: tasks),
              Expanded(child: gallery),
            ],
          ),
          if (_selected.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Center(
                child: GoldButton(
                  label: 'Upload ${_selected.length}',
                  icon: Icons.upload,
                  onPressed: _send,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AssetThumb extends StatefulWidget {
  const _AssetThumb({required this.asset, required this.selected, this.backup});

  final AssetEntity asset;
  final bool selected;
  final String? backup;

  @override
  State<_AssetThumb> createState() => _AssetThumbState();
}

class _AssetThumbState extends State<_AssetThumb> {
  late final Future<Uint8List?> _thumb = widget.asset.thumbnailDataWithSize(
    const ThumbnailSize.square(240),
  );

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      FutureBuilder<Uint8List?>(
        future: _thumb,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          return bytes == null
              ? const ColoredBox(color: Palette.bg3)
              : Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
        },
      ),
      if (widget.asset.type == AssetType.video)
        const Positioned(
          right: 4,
          bottom: 4,
          child: Icon(Icons.play_circle_fill, size: 18, color: Colors.white),
        ),
      if (widget.backup != null)
        Positioned(
          right: 4,
          top: 4,
          child: _BackupBadge(status: widget.backup!),
        ),
      if (widget.selected) ...[
        const ColoredBox(color: Color(0x66000000)),
        const Positioned(
          left: 4,
          top: 4,
          child: Icon(Icons.check_circle, size: 22, color: Palette.gold),
        ),
      ],
    ],
  );
}

/// On the device only, on its way, on the server and verified, or failed.
class _BackupBadge extends StatelessWidget {
  const _BackupBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      'verified' => (Icons.cloud_done, Palette.ok),
      'failed' => (Icons.error, Palette.err),
      'pending' => (Icons.cloud_queue, Colors.white),
      _ => (Icons.cloud_upload, Palette.gold),
    };
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0x8C000000),
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.tasks});

  final List<UploadTask> tasks;

  static String _label(UploadTask task) => switch (task.state) {
    UploadState.queued => 'Queued',
    UploadState.preparing => 'Preparing',
    UploadState.uploading => '${(task.progress * 100).round()} %',
    UploadState.done => 'Uploaded',
    UploadState.duplicate => 'Already on server',
    UploadState.failed => 'Failed',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final done = tasks.where((task) => task.finished).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$done of ${tasks.length} finished',
                  style: text.titleMedium,
                ),
              ),
              if (done > 0)
                TextButton(
                  onPressed: ref.read(uploadsProvider.notifier).clearFinished,
                  child: const Text('Clear'),
                ),
            ],
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final task in tasks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.name.isEmpty ? 'Photo' : task.name,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _label(task),
                              style: text.bodySmall?.copyWith(
                                color: task.state == UploadState.failed
                                    ? Palette.err
                                    : Palette.haze,
                              ),
                            ),
                          ],
                        ),
                        if (task.state == UploadState.uploading)
                          LinearProgressIndicator(
                            value: task.progress,
                            minHeight: 3,
                            color: Palette.gold,
                            backgroundColor: Palette.bg3,
                          ),
                        if (task.error != null)
                          Text(
                            task.error!,
                            style: text.bodySmall?.copyWith(color: Palette.err),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
