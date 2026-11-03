import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../services/backup.dart';
import '../theme.dart';

IconData waitingIcon(String status) => switch (status) {
  'failed' => Icons.error_outline,
  'uploading' || 'exporting' => Icons.cloud_upload_outlined,
  _ => Icons.schedule,
};

/// Photos from the chosen album that have not reached the server yet. They are read live from the
/// phone's library and kept nowhere, and leave this row once they are on the server.
class WaitingStrip extends ConsumerStatefulWidget {
  const WaitingStrip({super.key});

  @override
  ConsumerState<WaitingStrip> createState() => _WaitingStripState();
}

class _WaitingStripState extends ConsumerState<WaitingStrip> {
  static const _pollEvery = Duration(seconds: 5);

  List<WaitingAsset> _waiting = const [];
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(_pollEvery, (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final waiting = await ref.read(backupProvider).waiting();
      if (mounted) setState(() => _waiting = waiting);
    } on PlatformException {
      // The row simply stays as it was.
    } on MissingPluginException {
      // No native backup on this platform.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_waiting.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'On this phone, waiting to back up',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final asset in _waiting)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _WaitingTile(key: ValueKey(asset.id), asset: asset),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingTile extends StatefulWidget {
  const _WaitingTile({super.key, required this.asset});

  final WaitingAsset asset;

  @override
  State<_WaitingTile> createState() => _WaitingTileState();
}

class _WaitingTileState extends State<_WaitingTile> {
  Uint8List? _picture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entity = await AssetEntity.fromId(widget.asset.id);
    final picture = await entity?.thumbnailDataWithSize(
      const ThumbnailSize.square(128),
    );
    if (mounted) setState(() => _picture = picture);
  }

  @override
  Widget build(BuildContext context) {
    final picture = _picture;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: 64,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (picture == null)
              const ColoredBox(color: Palette.bg3)
            else
              Image.memory(picture, fit: BoxFit.cover),
            Positioned(
              right: 3,
              bottom: 3,
              child: Icon(
                waitingIcon(widget.asset.status),
                size: 16,
                color: widget.asset.status == 'failed'
                    ? Palette.err
                    : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
