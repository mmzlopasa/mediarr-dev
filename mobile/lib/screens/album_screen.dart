import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../l10n/l10n.dart';
import '../services/session.dart';
import '../services/settings.dart';
import '../services/timeline.dart';
import '../theme.dart';
import 'people_screens.dart';
import 'share_sheet.dart';
import 'slideshow_screen.dart';
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

  /// Every album this user sees: the ones in this one, the one it is in, and where it can move.
  List<Album> _all = const [];
  List<Album> get _children => [
    for (final other in _all)
      if (other.parentId == widget.albumId) other,
  ];
  Album? get _parent {
    final id = _album?.parentId;
    return id == null
        ? null
        : _all.where((other) => other.id == id).firstOrNull;
  }

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
    _session.api.listAlbums(sort: 'title').then((found) {
      if (mounted && found != null) setState(() => _all = found);
    }, onError: (Object _) {});
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
      if (mounted) _message(l.albumScreenActionFailed(cause.message ?? ''));
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
            ? l.albumScreenRemovedAll('$changed')
            : l.albumScreenRemovedSome('$changed', '${ids.length}'),
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
      _message(l.albumScreenCoverSet);
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
            child: Text(l.albumScreenCancel),
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

  void _open(Album other) => Navigator.of(context)
      .push(
        MaterialPageRoute<void>(
          builder: (_) => AlbumScreen(albumId: other.id, title: other.title),
        ),
      )
      .then((_) => _load());

  Future<void> _slideshow() async {
    final items = await _store.playlist('');
    if (!mounted || items.isEmpty) return;
    await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SlideshowScreen(
          session: _session,
          items: items,
          startId: items.first.id,
        ),
      ),
    );
  }

  Future<void> _makeInside() async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => const _TitleDialog(),
    );
    if (title == null || title.trim().isEmpty) return;
    await _guard(() async {
      await _session.api.createAlbum(
        AlbumCreate(title: title.trim(), parentId: widget.albumId),
      );
      await _load();
    });
  }

  /// Not into itself, nor into an album inside it.
  List<Album> _destinations() {
    final inside = {widget.albumId};
    var grew = true;
    while (grew) {
      grew = false;
      for (final other in _all) {
        final parent = other.parentId;
        if (parent != null && inside.contains(parent) && inside.add(other.id)) {
          grew = true;
        }
      }
    }
    return [
      for (final other in _all)
        if (other.role == AlbumRoleEnum.owner &&
            !other.isSmart &&
            !inside.contains(other.id))
          other,
    ];
  }

  Future<void> _move() async {
    final choices = _destinations();
    // '' is the top; null is nothing chosen.
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(l.albumScreenMoveTitle)),
            ListTile(
              leading: const Icon(Icons.vertical_align_top),
              title: Text(l.albumScreenMoveTop),
              onTap: () => Navigator.pop(context, ''),
            ),
            for (final other in choices)
              ListTile(
                leading: const Icon(Icons.photo_album_outlined),
                title: Text(other.title),
                onTap: () => Navigator.pop(context, other.id),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await _guard(() async {
      await _session.api.moveAlbum(
        widget.albumId,
        AlbumParent(parentId: chosen.isEmpty ? null : chosen),
      );
      if (mounted) _message(l.albumScreenMoved);
      await _load();
    });
  }

  void _menu(String choice, Album album) {
    switch (choice) {
      case 'slideshow':
        _slideshow();
      case 'inside':
        _makeInside();
      case 'move':
        _move();
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
              appBar: AppBar(title: Text(l.albumScreenUploadToAlbum)),
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
          title: l.albumScreenDeleteTitle,
          body: _children.isEmpty
              ? l.albumScreenDeleteBody
              : l.albumScreenDeleteBodyInside,
          action: l.albumScreenDelete,
          run: () => _session.api.deleteAlbum(widget.albumId),
        );
      case 'leave':
        _confirm(
          title: l.albumScreenLeaveTitle,
          body: l.albumScreenLeaveBody,
          action: l.albumScreenLeave,
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
                tooltip: l.albumScreenClearSelection,
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
              tooltip: l.albumScreenShare,
              icon: const Icon(Icons.share_outlined),
              onPressed: () =>
                  shareAssets(context, ref, _session, _selected.toList()),
            ),
            if (rights?.canEdit == true && _selected.length == 1)
              IconButton(
                tooltip: l.albumScreenSetAsCover,
                icon: const Icon(Icons.image_outlined),
                onPressed: _setCover,
              ),
            if (rights?.canAdd == true)
              IconButton(
                tooltip: l.albumScreenRemoveFromAlbum,
                icon: const Icon(Icons.delete_outline),
                onPressed: _removeSelected,
              ),
          ] else if (album != null && rights != null && !readOnly) ...[
            IconButton(
              tooltip: l.albumScreenSearchInAlbum,
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
              tooltip: l.albumScreenComments,
              icon: const Icon(Icons.mode_comment_outlined),
              onPressed: () => _sheet(
                ActivitySheet(session: _session, albumId: widget.albumId),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: l.albumScreenMore,
              onSelected: (choice) => _menu(choice, album),
              itemBuilder: (_) => [
                if (album.assetCount > 0)
                  PopupMenuItem(
                    value: 'slideshow',
                    child: Text(l.albumScreenSlideshow),
                  ),
                if (rights.canAdd) ...[
                  PopupMenuItem(
                    value: 'library',
                    child: Text(l.albumScreenAddFromLibrary),
                  ),
                  PopupMenuItem(
                    value: 'upload',
                    child: Text(l.albumScreenUploadFromPhone),
                  ),
                ],
                if (rights.isOwner) ...[
                  PopupMenuItem(
                    value: 'inside',
                    child: Text(l.albumScreenAlbumInside),
                  ),
                  PopupMenuItem(
                    value: 'move',
                    child: Text(l.albumScreenMoveTo),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Text(l.albumScreenShareWithUsers),
                  ),
                  PopupMenuItem(
                    value: 'links',
                    child: Text(l.albumScreenPublicLinks),
                  ),
                ],
                if (rights.canEdit)
                  PopupMenuItem(value: 'edit', child: Text(l.albumScreenEdit)),
                if (rights.isOwner)
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l.albumScreenDelete),
                  )
                else
                  PopupMenuItem(
                    value: 'leave',
                    child: Text(l.albumScreenLeave),
                  ),
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
      return EmptyMessage(
        icon: Icons.lock_outline,
        text: l.albumScreenNotAvailable,
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
        final header = _nesting();
        if (months.isEmpty) {
          if (header != null) {
            return ListView(children: [header]);
          }
          return EmptyMessage(
            icon: Icons.photo_album_outlined,
            text: album.isSmart
                ? l.albumScreenNoMatch
                : rights.canAdd
                ? l.albumScreenEmptyCanAdd
                : l.albumScreenEmpty,
          );
        }
        final canSelect = rights.canAdd || rights.canEdit;
        return TimelineGrid(
          header: header,
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

  /// The album this one is in, and the ones inside it, above its photos.
  Widget? _nesting() {
    final parent = _parent;
    final children = _children;
    if (parent == null && children.isEmpty) return null;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parent != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: ActionChip(
              avatar: const Icon(Icons.arrow_upward, size: 16),
              label: Text(parent.title),
              onPressed: () => _open(parent),
            ),
          ),
        if (children.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(l.albumScreenAlbumsInside, style: text.titleSmall),
          ),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: children.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _ChildAlbum(
                album: children[index],
                session: _session,
                onTap: _open,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// One album inside another, as a small card.
class _ChildAlbum extends StatelessWidget {
  const _ChildAlbum({
    required this.album,
    required this.session,
    required this.onTap,
  });

  final Album album;
  final Session session;
  final void Function(Album) onTap;

  @override
  Widget build(BuildContext context) {
    final cover = album.coverAssetId;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onTap(album),
      child: SizedBox(
        width: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 100,
                height: 90,
                color: Palette.bg3,
                child: cover == null
                    ? Icon(Icons.photo_album_outlined, color: Palette.dim)
                    : CachedNetworkImage(
                        imageUrl: session.thumbnailUrl(cover),
                        httpHeaders: session.headers,
                        cacheKey: '${session.serverUrl}/$cover/s',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

/// Asks for the name of a new album. It owns its text field, which stays until it has closed.
class _TitleDialog extends StatefulWidget {
  const _TitleDialog();

  @override
  State<_TitleDialog> createState() => _TitleDialogState();
}

class _TitleDialogState extends State<_TitleDialog> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(l.albumScreenNewAlbumInside),
    content: TextField(
      controller: _field,
      autofocus: true,
      maxLength: 200,
      decoration: InputDecoration(labelText: l.albumScreenName),
      onSubmitted: (value) => Navigator.pop(context, value),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(l.albumScreenCancel),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, _field.text),
        child: Text(l.albumScreenCreate),
      ),
    ],
  );
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
        SnackBar(content: Text(l.albumScreenAdded('${result?.changed ?? 0}'))),
      );
      navigator.pop();
    } on ApiException catch (cause) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.albumScreenActionFailed(cause.message ?? ''))),
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
          _selected.isEmpty ? l.albumScreenChoosePhotos : '${_selected.length}',
        ),
        actions: [
          TextButton(
            onPressed: _selected.isEmpty ? null : () => _add(session),
            child: Text(l.albumScreenAdd),
          ),
        ],
      ),
      body: store.months == null
          ? Center(child: CircularProgressIndicator(color: Palette.gold))
          : store.months!.isEmpty
          ? EmptyMessage(
              icon: Icons.photo_outlined,
              text: l.albumScreenNoPhotosYet,
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
      setState(() => _error = cause.message ?? l.albumScreenNotSaved);
    }
  }

  @override
  Widget build(BuildContext context) => SheetFrame(
    title: l.albumScreenEditAlbum,
    children: [
      TextField(
        controller: _title,
        maxLength: 200,
        decoration: InputDecoration(labelText: l.albumScreenName),
      ),
      TextField(
        controller: _description,
        decoration: InputDecoration(labelText: l.albumScreenDescription),
      ),
      DropdownButtonFormField<AlbumUpdateOrderEnum>(
        initialValue: _order,
        decoration: InputDecoration(labelText: l.albumScreenOrder),
        items: [
          DropdownMenuItem(
            value: AlbumUpdateOrderEnum.newest,
            child: Text(l.albumScreenNewestFirst),
          ),
          DropdownMenuItem(
            value: AlbumUpdateOrderEnum.oldest,
            child: Text(l.albumScreenOldestFirst),
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
      GoldButton(label: l.albumScreenSave, onPressed: _save),
    ],
  );
}
