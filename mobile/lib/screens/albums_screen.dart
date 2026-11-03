import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../theme.dart';
import 'album_screen.dart';
import 'album_sheets.dart';
import 'shared_screen.dart';

class AlbumsScreen extends ConsumerStatefulWidget {
  const AlbumsScreen({super.key});

  @override
  ConsumerState<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends ConsumerState<AlbumsScreen> {
  List<Album>? _albums;
  bool _failed = false;
  String _sort = 'updated';
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
    final text = Theme.of(context).textTheme;
    if (session == null) return const SizedBox.shrink();
    final albums = _albums;

    Widget body;
    if (albums == null) {
      body = _failed
          ? EmptyMessage(
              icon: Icons.cloud_off,
              text: 'Albums could not be loaded. Check the connection.',
              action: GoldButton(label: 'Try again', onPressed: _load),
            )
          : const Center(child: CircularProgressIndicator(color: Palette.gold));
    } else if (albums.isEmpty) {
      body = const EmptyMessage(
        icon: Icons.photo_album_outlined,
        text: 'No albums yet.',
      );
    } else {
      body = RefreshIndicator(
        color: Palette.gold,
        onRefresh: _load,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisSpacing: 14,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) => _AlbumTile(
            album: albums[index],
            session: session,
            onReturn: _load,
          ),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 4, 2),
            child: Row(
              children: [
                Expanded(child: Text('Albums', style: text.headlineMedium)),
                IconButton(
                  tooltip: 'Shared',
                  icon: const Icon(Icons.people_outline),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SharedScreen(),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Sort',
                  icon: const Icon(Icons.sort),
                  onSelected: (value) {
                    setState(() => _sort = value);
                    _load();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'updated', child: Text('Last change')),
                    PopupMenuItem(value: 'title', child: Text('Name')),
                    PopupMenuItem(value: 'date', child: Text('Photo date')),
                  ],
                ),
                IconButton(
                  tooltip: 'New album',
                  icon: const Icon(Icons.add),
                  onPressed: () => _create(session),
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
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
      if (album.isSmart) 'Smart',
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
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: Palette.bg3,
                width: double.infinity,
                child: cover == null
                    ? const Icon(
                        Icons.photo_album_outlined,
                        color: Palette.dim,
                        size: 32,
                      )
                    : CachedNetworkImage(
                        imageUrl: session.thumbnailUrl(cover),
                        httpHeaders: session.headers,
                        cacheKey: '${session.serverUrl}/$cover/s',
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const Icon(
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
      setState(() => _error = cause.message ?? 'The album was not created.');
    }
  }

  @override
  Widget build(BuildContext context) => SheetFrame(
    title: 'New album',
    children: [
      TextField(
        controller: _title,
        maxLength: 200,
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      TextField(
        controller: _description,
        decoration: const InputDecoration(labelText: 'Description'),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Smart album: fills itself from rules'),
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
          child: Text(_error!, style: const TextStyle(color: Palette.err)),
        ),
      const SizedBox(height: 12),
      GoldButton(label: 'Create', onPressed: _create),
    ],
  );
}
