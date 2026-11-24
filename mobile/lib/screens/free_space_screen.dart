import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../l10n/l10n.dart';
import '../services/backup.dart';
import '../services/free_space.dart';
import '../services/session.dart';
import '../services/settings.dart';
import '../theme.dart';

/// Removes from the phone only what the server confirms having at this moment.
class FreeSpaceScreen extends ConsumerStatefulWidget {
  const FreeSpaceScreen({super.key});

  @override
  ConsumerState<FreeSpaceScreen> createState() => _FreeSpaceScreenState();
}

class _FreeSpaceScreenState extends ConsumerState<FreeSpaceScreen> {
  List<AssetEntity>? _assets;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Fails closed: if the server cannot be asked, nothing is offered.
  Future<void> _load() async {
    setState(() {
      _assets = null;
      _error = null;
    });
    try {
      final session = ref.read(sessionProvider).value;
      if (session == null) throw const _CannotAsk();
      final verified = _lowercase(
        await ref.read(backupProvider).verifiedChecksums(),
      );
      final checksums = {for (final list in verified.values) ...list}.toList();
      final onServer = await checksumsOnServer(session.api, checksums);
      final rules = ref.read(settingsProvider).freeSpace;
      final kept = await _idsInAlbums(rules.keepAlbums);
      final now = DateTime.now();
      final assets = <AssetEntity>[];
      for (final id in safeToRemove(verified, onServer)) {
        final asset = await AssetEntity.fromId(id);
        if (asset == null) continue;
        final allowed = rules.mayRemove(
          taken: asset.createDateTime,
          now: now,
          isVideo: asset.type == AssetType.video,
          isFavorite: asset.isFavorite,
          inKeptAlbum: kept.contains(id),
        );
        if (allowed) assets.add(asset);
      }
      if (mounted) setState(() => _assets = assets);
    } on PlatformException {
      if (mounted) {
        setState(() => _error = l.freeSpaceScreenBackupUnreadable);
      }
    } on Object {
      // The server did not answer, or answered something else: nothing may go.
      if (mounted) {
        setState(() => _error = l.freeSpaceScreenServerUnreachable);
      }
    }
  }

  static Map<String, List<String>> _lowercase(Map<String, List<String>> map) =>
      {
        for (final entry in map.entries)
          entry.key: [for (final sum in entry.value) sum.toLowerCase()],
      };

  /// On Android another app can change a photo in place after it was sent, so the file is read
  /// again. On iOS the original of a photo never changes: an edit is kept beside it.
  static Future<String?> _checksumNow(String id) async {
    if (!Platform.isAndroid) return null;
    final asset = await AssetEntity.fromId(id);
    final file = await asset?.originFile;
    if (file == null) return null;
    return fileSha256(file.path);
  }

  Future<Set<String>> _idsInAlbums(List<String> albumIds) async {
    if (albumIds.isEmpty) return const {};
    final kept = <String>{};
    final albums = await PhotoManager.getAssetPathList();
    for (final album in albums) {
      if (!albumIds.contains(album.id)) continue;
      final count = await album.assetCountAsync;
      for (final asset in await album.getAssetListRange(start: 0, end: count)) {
        kept.add(asset.id);
      }
    }
    return kept;
  }

  Future<void> _editRules() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RulesSheet(),
    );
    if (mounted) await _load();
  }

  Future<void> _remove(List<AssetEntity> assets) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.freeSpaceScreenRemoveTitle('${assets.length}')),
        content: Text(l.freeSpaceScreenRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.freeSpaceScreenCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l.freeSpaceScreenRemove,
              style: TextStyle(color: Palette.err),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busy) return;
    final session = ref.read(sessionProvider).value;
    if (session == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final chosen = [for (final asset in assets) asset.id];
    try {
      // Asked once more just before, as the server or the phone may have changed since.
      final ids = await stillSafeToRemove(
        ids: chosen,
        verified: ref.read(backupProvider).verifiedChecksums,
        onServer: (checksums) => checksumsOnServer(session.api, checksums),
        currentChecksum: Platform.isAndroid ? _checksumNow : null,
      );
      if (ids.isNotEmpty) await PhotoManager.editor.deleteWithIds(ids);
      final left = chosen.length - ids.length;
      if (left > 0) {
        messenger.showSnackBar(
          SnackBar(content: Text(l.freeSpaceScreenKeptChanged(left))),
        );
      }
    } on Object {
      messenger.showSnackBar(
        SnackBar(content: Text(l.freeSpaceScreenNotRemoved)),
      );
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final assets = _assets;
    final Widget body;
    if (_error != null) {
      body = EmptyMessage(icon: Icons.cloud_off, text: _error!);
    } else if (assets == null) {
      body = Center(child: CircularProgressIndicator(color: Palette.gold));
    } else if (assets.isEmpty) {
      body = EmptyMessage(
        icon: Icons.cleaning_services_outlined,
        text: l.freeSpaceScreenNothingToRemove,
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(l.freeSpaceScreenSafe('${assets.length}')),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
              ),
              itemCount: assets.length,
              itemBuilder: (_, index) => _Thumbnail(
                key: ValueKey(assets[index].id),
                asset: assets[index],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GoldButton(
                label: l.freeSpaceScreenRemoveButton('${assets.length}'),
                busy: _busy,
                onPressed: () => _remove(assets),
              ),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l.freeSpaceScreenTitle),
        actions: [
          IconButton(
            tooltip: l.freeSpaceScreenWhatToKeep,
            icon: const Icon(Icons.tune),
            onPressed: _editRules,
          ),
        ],
      ),
      body: body,
    );
  }
}

class _CannotAsk implements Exception {
  const _CannotAsk();
}

class _RulesSheet extends ConsumerStatefulWidget {
  const _RulesSheet();

  @override
  ConsumerState<_RulesSheet> createState() => _RulesSheetState();
}

class _RulesSheetState extends ConsumerState<_RulesSheet> {
  static Map<int, String> get _ages => {
    0: l.freeSpaceScreenAnyAge,
    30: l.freeSpaceScreenOlderThanMonth,
    90: l.freeSpaceScreenOlderThan3Months,
    365: l.freeSpaceScreenOlderThanYear,
  };

  List<AssetPathEntity> _albums = const [];

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    try {
      final albums = await PhotoManager.getAssetPathList(hasAll: false);
      if (mounted) setState(() => _albums = albums);
    } on PlatformException {
      // Then only the other rules are offered.
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final rules = settings.freeSpace;
    void change(FreeSpaceRules next) => ref
        .read(settingsProvider.notifier)
        .change(settings.copyWith(freeSpace: next));

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text(l.freeSpaceScreenRemoveOnly),
            trailing: DropdownButton<int>(
              value: _ages.containsKey(rules.olderThanDays)
                  ? rules.olderThanDays
                  : 0,
              items: [
                for (final age in _ages.entries)
                  DropdownMenuItem(value: age.key, child: Text(age.value)),
              ],
              onChanged: (days) =>
                  change(rules.copyWith(olderThanDays: days ?? 0)),
            ),
          ),
          SwitchListTile(
            title: Text(l.freeSpaceScreenKeepFavorites),
            value: rules.keepFavorites,
            activeThumbColor: Palette.gold,
            onChanged: (value) => change(rules.copyWith(keepFavorites: value)),
          ),
          SwitchListTile(
            title: Text(l.freeSpaceScreenKeepPhotos),
            value: rules.keepPhotos,
            activeThumbColor: Palette.gold,
            onChanged: (value) => change(rules.copyWith(keepPhotos: value)),
          ),
          SwitchListTile(
            title: Text(l.freeSpaceScreenKeepVideos),
            value: rules.keepVideos,
            activeThumbColor: Palette.gold,
            onChanged: (value) => change(rules.copyWith(keepVideos: value)),
          ),
          if (_albums.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(l.freeSpaceScreenKeepAlbums),
            ),
          for (final album in _albums)
            CheckboxListTile(
              title: Text(album.name),
              value: rules.keepAlbums.contains(album.id),
              activeColor: Palette.gold,
              onChanged: (value) => change(
                rules.copyWith(
                  keepAlbums: value == true
                      ? [...rules.keepAlbums, album.id]
                      : [
                          for (final id in rules.keepAlbums)
                            if (id != album.id) id,
                        ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatefulWidget {
  const _Thumbnail({required this.asset, super.key});

  final AssetEntity asset;

  @override
  State<_Thumbnail> createState() => _ThumbnailState();
}

class _ThumbnailState extends State<_Thumbnail> {
  // Asked once, not again on every rebuild of the grid.
  late final Future<Uint8List?> _data = widget.asset.thumbnailDataWithSize(
    const ThumbnailSize.square(200),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _data,
    builder: (_, snapshot) => snapshot.data == null
        ? ColoredBox(color: Palette.bg3)
        : Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            cacheWidth: 200,
            gaplessPlayback: true,
          ),
  );
}
