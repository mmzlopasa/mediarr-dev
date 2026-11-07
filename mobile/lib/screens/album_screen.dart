import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../services/settings.dart';
import '../services/timeline.dart';
import '../theme.dart';
import 'people_screens.dart';
import 'share_sheet.dart';
import 'album_sheets.dart';
import 'timeline_screen.dart';
import 'upload_screen.dart';
import 'viewer_screen.dart';

class AlbumScreen extends ConsumerStatefulWidget {
  const AlbumScreen({super.key, required this.albumId, required this.title});

  final String albumId;
  final String title;

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  static const _pollEvery = Duration(seconds: 10);

  late final Session _session = ref.read(sessionProvider).value!;
  late final TimelineStore _store = TimelineStore.album(
    _session,
    widget.albumId,
  );
  final _selected = <String>{};
  Album? _album;
  bool _gone = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    // What other people add, remove or say appears without reloading.
    _poll = Timer.periodic(_pollEvery, (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _store.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final next = await _session.api.getAlbum(widget.albumId);
      if (!mounted) return;
      final changed = _album != null && next?.updatedAt != _album?.updatedAt;
      setState(() {
        _album = next;
        _gone = false;
      });
      await _store.refresh(reloadLoaded: changed);
    } on ApiException {
      // Access ended, or the album was deleted. Nothing more is shown.
      if (mounted) setState(() => _gone = true);
    }
  }

  void _toggle(String id) {
    if (ref.read(settingsProvider).readOnly) return;
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (cause) {
      if (mounted) _message('The action failed. ${cause.message ?? ''}');
    }
  }

  Future<void> _removeSelected() => _guard(() async {
    final ids = _selected.toList();
    final result = await _session.api.removeAlbumAssets(
      widget.albumId,
      AssetIds(ids: ids),
    );
    final changed = result?.changed ?? 0;
    if (mounted) {
      _message(
        changed == ids.length
            ? 'Removed from the album: $changed'
            : 'Removed: $changed of ${ids.length}. You can remove only photos you added yourself.',
      );
      setState(_selected.clear);
    }
    await _load();
    await _store.refresh(reloadLoaded: true);
  });

  Future<void> _setCover() => _guard(() async {
    await _session.api.updateAlbum(
      widget.albumId,
      AlbumUpdate(coverAssetId: _selected.first),
    );
    if (mounted) {
      _message('The cover is set.');
      setState(_selected.clear);
    }
  });

  void _sheet(Widget sheet) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => sheet,
  );

  Future<void> _confirm({
    required String title,
    required String body,
    required String action,
    required Future<void> Function() run,
  }) async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action, style: TextStyle(color: Palette.err)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _guard(() async {
      await run();
      navigator.pop();
    });
  }

  void _menu(String choice, Album album) {
    switch (choice) {
      case 'library':
        Navigator.of(context)
            .push(
              MaterialPageRoute<void>(
                builder: (_) => _LibraryPicker(albumId: widget.albumId),
              ),
            )
            .then((_) => _load());
      case 'upload':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Upload to album')),
              body: UploadScreen(albumId: widget.albumId),
            ),
          ),
        );
      case 'share':
        _sheet(
          ShareSheet(
            session: _session,
            albumId: widget.albumId,
            onChanged: _load,
          ),
        );
      case 'links':
        _sheet(
          LinksSheet(
            session: _session,
            albumId: widget.albumId,
            isSmart: album.isSmart,
          ),
        );
      case 'edit':
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _EditSheet(session: _session, album: album),
        ).then((_) => _store.refresh(reloadLoaded: true)).then((_) => _load());
      case 'delete':
        _confirm(
          title: 'Delete this album?',
          body: 'The photos stay in the library. Public links stop working.',
          action: 'Delete',
          run: () => _session.api.deleteAlbum(widget.albumId),
        );
      case 'leave':
        _confirm(
          title: 'Leave this album?',
          body: 'You will no longer see it, unless the owner shares it again.',
          action: 'Leave',
          run: () =>
              _session.api.removeAlbumMember(widget.albumId, _session.user.id),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final album = _album;
    final rights = album == null
        ? null
        : AlbumRights(album.role, isSmart: album.isSmart);
    final selecting = _selected.isNotEmpty;
    final readOnly = ref.watch(settingsProvider).readOnly;

    return Scaffold(
      appBar: AppBar(
        leading: selecting
            ? IconButton(
                tooltip: 'Clear selection',
                icon: const Icon(Icons.close),
                onPressed: () => setState(_selected.clear),
              )
            : null,
        title: Text(
          selecting ? '${_selected.length}' : album?.title ?? widget.title,
        ),
        actions: [
          if (selecting) ...[
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.share_outlined),
              onPressed: () =>
                  shareAssets(context, ref, _session, _selected.toList()),
            ),
            if (rights?.canEdit == true && _selected.length == 1)
              IconButton(
                tooltip: 'Set as cover',
                icon: const Icon(Icons.image_outlined),
                onPressed: _setCover,
              ),
            if (rights?.canAdd == true)
              IconButton(
                tooltip: 'Remove from album',
                icon: const Icon(Icons.delete_outline),
                onPressed: _removeSelected,
              ),
          ] else if (album != null && rights != null && !readOnly) ...[
            IconButton(
              tooltip: 'Search in album',
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SearchScreen(
                    albumId: widget.albumId,
                    albumTitle: album.title,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Comments',
              icon: const Icon(Icons.mode_comment_outlined),
              onPressed: () => _sheet(
                ActivitySheet(session: _session, albumId: widget.albumId),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (choice) => _menu(choice, album),
              itemBuilder: (_) => [
                if (rights.canAdd) ...const [
                  PopupMenuItem(
                    value: 'library',
                    child: Text('Add from library'),
                  ),
                  PopupMenuItem(
                    value: 'upload',
                    child: Text('Upload from this phone'),
                  ),
                ],
                if (rights.isOwner) ...const [
                  PopupMenuItem(
                    value: 'share',
                    child: Text('Share with users'),
                  ),
                  PopupMenuItem(value: 'links', child: Text('Public links')),
                ],
                if (rights.canEdit)
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (rights.isOwner)
                  const PopupMenuItem(value: 'delete', child: Text('Delete'))
                else
                  const PopupMenuItem(value: 'leave', child: Text('Leave')),
              ],
            ),
          ],
        ],
      ),
      body: _body(album, rights),
    );
  }

  Widget _body(Album? album, AlbumRights? rights) {
    if (_gone) {
      return const EmptyMessage(
        icon: Icons.lock_outline,
        text: 'This album is not available.',
      );
    }
    if (album == null || rights == null) {
      return Center(child: CircularProgressIndicator(color: Palette.gold));
    }
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final months = _store.months;
        if (months == null) {
          return Center(child: CircularProgressIndicator(color: Palette.gold));
        }
        if (months.isEmpty) {
          return EmptyMessage(
            icon: Icons.photo_album_outlined,
            text: album.isSmart
                ? 'No photos match the rules.'
                : rights.canAdd
                ? 'This album is empty. Add photos from the menu.'
                : 'This album is empty.',
          );
        }
        final canSelect = rights.canAdd || rights.canEdit;
        return TimelineGrid(
          store: _store,
          session: _session,
          selected: _selected,
          onToggle: canSelect ? _toggle : (_) {},
          onOpen: (index) => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ViewerScreen(
                initialIndex: index,
                store: _store,
                albumId: widget.albumId,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Chooses from the user's own library. Only one's own photos can be added to an album.
class _LibraryPicker extends ConsumerStatefulWidget {
  const _LibraryPicker({required this.albumId});

  final String albumId;

  @override
  ConsumerState<_LibraryPicker> createState() => _LibraryPickerState();
}

class _LibraryPickerState extends ConsumerState<_LibraryPicker> {
  final _selected = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(timelineProvider).refresh(),
    );
  }

  void _toggle(String id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  Future<void> _add(Session session) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await session.api.addAlbumAssets(
        widget.albumId,
        AssetIds(ids: _selected.toList()),
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Added: ${result?.changed ?? 0}')),
      );
      navigator.pop();
    } on ApiException catch (cause) {
      messenger.showSnackBar(
        SnackBar(content: Text('The action failed. ${cause.message ?? ''}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(timelineProvider);
    final session = ref.watch(sessionProvider).value;
    if (session == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selected.isEmpty ? 'Choose photos' : '${_selected.length}',
        ),
        actions: [
          TextButton(
            onPressed: _selected.isEmpty ? null : () => _add(session),
            child: const Text('Add'),
          ),
        ],
      ),
      body: store.months == null
          ? Center(child: CircularProgressIndicator(color: Palette.gold))
          : store.months!.isEmpty
          ? const EmptyMessage(
              icon: Icons.photo_outlined,
              text: 'No photos yet.',
            )
          : TimelineGrid(
              store: store,
              session: session,
              selected: _selected,
              onToggle: _toggle,
              onOpen: (index) => _toggle(store.loadedItems[index].id),
            ),
    );
  }
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.session, required this.album});

  final Session session;
  final Album album;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final _title = TextEditingController(text: widget.album.title);
  late final _description = TextEditingController(
    text: widget.album.description,
  );
  late AlbumUpdateOrderEnum _order = widget.album.order == AlbumOrderEnum.oldest
      ? AlbumUpdateOrderEnum.oldest
      : AlbumUpdateOrderEnum.newest;
  late AlbumRules _rules = widget.album.rules ?? AlbumRules();
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    try {
      await widget.session.api.updateAlbum(
        widget.album.id,
        AlbumUpdate(
          title: _title.text.trim(),
          description: _description.text.trim(),
          order: _order,
          rules: widget.album.isSmart ? _rules : null,
        ),
      );
      navigator.pop();
    } on ApiException catch (cause) {
      setState(() => _error = cause.message ?? 'The album was not saved.');
    }
  }

  @override
  Widget build(BuildContext context) => SheetFrame(
    title: 'Edit album',
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
      DropdownButtonFormField<AlbumUpdateOrderEnum>(
        initialValue: _order,
        decoration: const InputDecoration(labelText: 'Order'),
        items: const [
          DropdownMenuItem(
            value: AlbumUpdateOrderEnum.newest,
            child: Text('Newest first'),
          ),
          DropdownMenuItem(
            value: AlbumUpdateOrderEnum.oldest,
            child: Text('Oldest first'),
          ),
        ],
        onChanged: (value) => setState(() => _order = value ?? _order),
      ),
      if (widget.album.isSmart)
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
      GoldButton(label: 'Save', onPressed: _save),
    ],
  );
}
