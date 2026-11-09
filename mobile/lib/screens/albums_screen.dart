import '../motion.dart';

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../l10n/l10n.dart';
import '../services/session.dart';
import '../theme.dart';
import 'album_screen.dart';
import 'app_header.dart';
import 'album_sheets.dart';

enum _Owner { all, shared, mine }

/// Which albums a search and filter leave.
List<Album> visibleAlbums(
  List<Album> albums, {
  required String search,
  required bool? mine,
}) {
  final wanted = search.trim().toLowerCase();
  return [
    for (final album in albums)
      // Albums inside others are on the page of the one they are in; a search finds all.
      if ((wanted.isNotEmpty || album.parentId == null) &&
          album.title.toLowerCase().contains(wanted) &&
          (mine == null || (album.role == AlbumRoleEnum.owner) == mine))
        album,
  ];
}

/// How many albums are inside one, in words.
String albumsInside(int count) => l.albumsScreenInside(count);

class AlbumsScreen extends ConsumerStatefulWidget {
  const AlbumsScreen({super.key});

  @override
  ConsumerState<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends ConsumerState<AlbumsScreen> {
  List<Album>? _albums;
  bool _failed = false;
  String _sort = 'updated';
  String _search = '';
  _Owner _owner = _Owner.all;
  bool _grid = true;
  bool _filtersOpen = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    // What other people share or change appears without reloading.
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final session = ref.read(sessionProvider).value;
    if (session == null) return;
    try {
      final albums = await session.api.listAlbums(sort: _sort);
      if (mounted) {
        setState(() {
          _albums = albums ?? const [];
          _failed = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _create(Session session) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NewAlbumSheet(session: session),
    );
    if (created == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
    if (session == null) return const SizedBox.shrink();
    final all = _albums;
    final albums = all == null
        ? null
        : visibleAlbums(
            all,
            search: _search,
            mine: switch (_owner) {
              _Owner.all => null,
              _Owner.shared => false,
              _Owner.mine => true,
            },
          );

    Widget body;
    if (albums == null) {
      body = _failed
          ? EmptyMessage(
              icon: Icons.cloud_off,
              text: l.albumsScreenLoadFailed,
              action: GoldButton(
                label: l.albumsScreenTryAgain,
                onPressed: _load,
              ),
            )
          : Center(child: CircularProgressIndicator(color: Palette.gold));
    } else if (albums.isEmpty) {
      body = EmptyMessage(
        icon: Icons.photo_album_outlined,
        text: all!.isEmpty ? l.albumsScreenNoAlbums : l.albumsScreenNoMatch,
      );
    } else {
      body = RefreshIndicator(
        color: Palette.gold,
        onRefresh: _load,
        child: _grid
            ? GridView.builder(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: albums.length,
                itemBuilder: (context, index) => Rise(
                  id: 'album ${albums[index].id}',
                  index: index,
                  child: _AlbumTile(
                    album: albums[index],
                    session: session,
                    onReturn: _load,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 110),
                itemCount: albums.length,
                itemBuilder: (context, index) => _AlbumRow(
                  album: albums[index],
                  session: session,
                  onReturn: _load,
                ),
              ),
      );
    }

    final sortNames = {
      'updated': l.albumsScreenSortUpdated,
      'title': l.albumsScreenName,
      'date': l.albumsScreenSortDate,
    };
    Widget chip(String label, _Owner value) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _owner == value,
        showCheckmark: false,
        selectedColor: Palette.gold,
        labelStyle: TextStyle(
          color: _owner == value ? Palette.bg : Palette.ink,
        ),
        onSelected: (_) => setState(() => _owner = value),
      ),
    );
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(
            title: l.albumsScreenTitle,
            actionLabel: l.albumsScreenNew,
            onAction: () => _create(session),
          ),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PopupMenuButton<String>(
                    tooltip: l.albumsScreenSort,
                    onSelected: (value) {
                      setState(() => _sort = value);
                      _load();
                    },
                    itemBuilder: (_) => [
                      for (final entry in sortNames.entries)
                        PopupMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.expand_less, size: 20),
                          const SizedBox(width: 8),
                          Text(sortNames[_sort] ?? ''),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l.albumsScreenSearchFilter,
                icon: Icon(
                  Icons.tune,
                  color: _filtersOpen ? Palette.gold : null,
                ),
                onPressed: () => setState(() {
                  _filtersOpen = !_filtersOpen;
                  if (!_filtersOpen) {
                    _search = '';
                    _owner = _Owner.all;
                  }
                }),
              ),
              IconButton(
                tooltip: _grid
                    ? l.albumsScreenShowList
                    : l.albumsScreenShowGrid,
                icon: Icon(_grid ? Icons.view_list : Icons.grid_view),
                onPressed: () => setState(() => _grid = !_grid),
              ),
            ],
          ),
          if (_filtersOpen) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: TextField(
                onChanged: (value) => setState(() => _search = value),
                decoration: InputDecoration(
                  hintText: l.albumsScreenSearchAlbums,
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  chip(l.albumsScreenAll, _Owner.all),
                  chip(l.albumsScreenSharedWithMe, _Owner.shared),
                  chip(l.albumsScreenMine, _Owner.mine),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _AlbumRow extends StatelessWidget {
  const _AlbumRow({
    required this.album,
    required this.session,
    required this.onReturn,
  });

  final Album album;
  final Session session;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cover = album.coverAssetId;
    final details = [
      l.albumsScreenItems(album.assetCount),
      if ((album.childCount ?? 0) > 0) albumsInside(album.childCount!),
      if (album.isSmart) l.albumsScreenSmart,
      if (album.role == AlbumRoleEnum.owner)
        l.albumsScreenOwned
      else
        album.ownerName,
    ].join(' • ');
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AlbumScreen(albumId: album.id, title: album.title),
          ),
        );
        onReturn();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 84,
                height: 84,
                color: Palette.bg3,
                child: cover == null
                    ? Icon(Icons.photo_album_outlined, color: Palette.dim)
                    : CachedNetworkImage(
                        imageUrl: session.thumbnailUrl(cover),
                        httpHeaders: session.headers,
                        cacheKey: '${session.serverUrl}/$cover/s',
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Icon(
                          Icons.broken_image_outlined,
                          color: Palette.dim,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: Palette.dim),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({
    required this.album,
    required this.session,
    required this.onReturn,
  });

  final Album album;
  final Session session;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cover = album.coverAssetId;
    final details = [
      '${album.assetCount}',
      if ((album.childCount ?? 0) > 0) albumsInside(album.childCount!),
      if (album.isSmart) l.albumsScreenSmart,
      if (album.role != AlbumRoleEnum.owner) album.ownerName,
    ].join(' · ');
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AlbumScreen(albumId: album.id, title: album.title),
          ),
        );
        onReturn();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                color: Palette.bg3,
                width: double.infinity,
                child: cover == null
                    ? Icon(
                        Icons.photo_album_outlined,
                        color: Palette.dim,
                        size: 32,
                      )
                    : CachedNetworkImage(
                        imageUrl: session.thumbnailUrl(cover),
                        httpHeaders: session.headers,
                        cacheKey: '${session.serverUrl}/$cover/s',
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Icon(
                          Icons.broken_image_outlined,
                          color: Palette.dim,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            album.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodyLarge,
          ),
          Text(
            details,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: Palette.dim),
          ),
        ],
      ),
    );
  }
}

class _NewAlbumSheet extends StatefulWidget {
  const _NewAlbumSheet({required this.session});

  final Session session;

  @override
  State<_NewAlbumSheet> createState() => _NewAlbumSheetState();
}

class _NewAlbumSheetState extends State<_NewAlbumSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  bool _smart = false;
  AlbumRules _rules = AlbumRules();
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final navigator = Navigator.of(context);
    try {
      await widget.session.api.createAlbum(
        AlbumCreate(
          title: _title.text.trim(),
          description: _description.text.trim(),
          rules: _smart ? _rules : null,
        ),
      );
      navigator.pop(true);
    } on ApiException catch (cause) {
      setState(() => _error = cause.message ?? l.albumsScreenNotCreated);
    }
  }

  @override
  Widget build(BuildContext context) => SheetFrame(
    title: l.albumsScreenNewAlbum,
    children: [
      TextField(
        controller: _title,
        maxLength: 200,
        decoration: InputDecoration(labelText: l.albumsScreenName),
      ),
      TextField(
        controller: _description,
        decoration: InputDecoration(labelText: l.albumsScreenDescription),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l.albumsScreenSmartAlbum),
        value: _smart,
        onChanged: (value) => setState(() => _smart = value),
      ),
      if (_smart)
        RulesEditor(
          session: widget.session,
          rules: _rules,
          onChanged: (value) => _rules = value,
        ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_error!, style: TextStyle(color: Palette.err)),
        ),
      const SizedBox(height: 12),
      GoldButton(label: l.albumsScreenCreate, onPressed: _create),
    ],
  );
}
