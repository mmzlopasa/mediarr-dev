import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediarr_api/api.dart';

import '../l10n/l10n.dart';
import '../services/cull.dart';
import '../services/session.dart';
import '../theme.dart';
import 'asset_facts.dart';
import 'asset_picture.dart';

/// Opens the photos among [items], one at a time, to be picked or rejected.
Future<void> openCull(
  BuildContext context,
  Session session,
  List<TimelineItem> items,
) async {
  final photos = [
    for (final item in items)
      if (item.kind == TimelineItemKindEnum.photo && item.isShared != true)
        item,
  ];
  if (photos.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.cullNothing)));
    return;
  }
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CullScreen(session: session, items: photos),
    ),
  );
}

/// One photo over the whole screen and a strip of the others. A drag up picks, a drag down rejects.
class CullScreen extends StatefulWidget {
  const CullScreen({super.key, required this.session, required this.items});

  final Session session;
  final List<TimelineItem> items;

  @override
  State<CullScreen> createState() => _CullScreenState();
}

class _CullScreenState extends State<CullScreen> {
  // One for all the photos on screen: zooming one zooms those beside it.
  final _transform = TransformationController();
  final _strip = ScrollController();
  late List<TimelineItem> _photos = widget.items;
  Map<String, CullMark>? _marks;
  List<String> _compared = const [];
  int _index = 0;
  bool _zoomed = false;
  bool _busy = false;
  bool _failed = false;

  // A finger on the photo, followed without taking part in the zoom's gestures.
  int _fingers = 0;
  Offset? _start;
  bool _pinched = false;

  Session get _session => widget.session;
  TimelineItem get _current => _photos[_index.clamp(0, _photos.length - 1)];
  bool get _comparing => _compared.length >= 2;
  CullMark? get _mark => _marks?[_current.id];

  List<String> _withPick(int pick) => [
    for (final photo in _photos)
      if (_marks?[photo.id]?.pick == pick) photo.id,
  ];

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _preload());
  }

  @override
  void dispose() {
    _transform.dispose();
    _strip.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final found = <String, CullMark>{};
    try {
      for (final part in chunksOf([for (final p in widget.items) p.id])) {
        final answer = await _session.api.readAssetPicks(AssetIds(ids: part));
        for (final state in answer?.items ?? const <PickState>[]) {
          found[state.id] = CullMark(pick: state.pick, rating: state.rating);
        }
      }
    } on ApiException {
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) return;
    final own = [
      for (final item in widget.items)
        if (found.containsKey(item.id)) item,
    ];
    if (own.isEmpty) {
      _say(l.cullNothing);
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _photos = own;
      _marks = found;
      _index = 0;
    });
    _preload();
  }

  void _preload() {
    if (!mounted) return;
    for (final at in preloadIndexes(_index, _photos.length)) {
      final item = _photos[at];
      final version = previewVersion(item.blurhash);
      final url = _session.thumbnailUrl(item.id, large: true, version: version);
      final key = version == null ? '' : '/$version';
      final ImageProvider provider = _session.keepOnDisk
          ? CachedNetworkImageProvider(
              url,
              headers: _session.headers,
              cacheKey: '${_session.serverUrl}/${item.id}/l$key',
            )
          : NetworkImage(url, headers: _session.headers);
      precacheImage(provider, context, onError: (_, _) {});
    }
  }

  void _say(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _resetZoom() {
    _transform.value = Matrix4.identity();
    _zoomed = false;
  }

  void _goTo(int index) {
    if (index < 0 || index >= _photos.length) return;
    setState(() {
      _index = index;
      if (!_comparing) _resetZoom();
    });
    _preload();
  }

  void _move(int by) {
    if (_comparing) {
      final at = _compared.indexOf(_current.id) + by;
      if (at < 0 || at >= _compared.length) return;
      _goTo(_photos.indexWhere((photo) => photo.id == _compared[at]));
      return;
    }
    _goTo(_index + by);
  }

  Future<void> _setPick(int value) async {
    final mark = _mark;
    if (mark == null) return;
    final id = _current.id;
    final before = mark.pick;
    final next = value != 0 && before == value ? 0 : value;
    setState(() => mark.pick = next);
    // A verdict is the end of this photo; undoing one stays on it.
    if (next != 0 && !_comparing) _move(1);
    try {
      final answer = await _session.api.setAssetPick(
        PickRequest(ids: [id], pick: next),
      );
      if ((answer?.changed ?? 0) == 0) throw ApiException(404, '');
    } on ApiException {
      if (mounted) setState(() => mark.pick = before);
      _say(l.cullNotSaved);
    }
  }

  Future<void> _rate(int stars) async {
    final mark = _mark;
    if (mark == null) return;
    final id = _current.id;
    final before = mark.rating;
    setState(() => mark.rating = stars);
    try {
      await _session.api.setAssetFacts(id, AssetFacts(rating: stars));
    } on ApiException {
      if (mounted) setState(() => mark.rating = before);
      _say(l.cullNotSaved);
    }
  }

  void _toggleCompare() => setState(() {
    _compared = toggleCompared(_compared, _current.id);
    _resetZoom();
  });

  Future<void> _trashRejected() async {
    final gone = _withPick(-1);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.cullRejectsToTrash),
        content: Text(l.cullConfirmTrash(gone.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.viewerScreenCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l.viewerScreenDelete,
              style: TextStyle(color: Palette.err),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      for (final part in chunksOf(gone)) {
        await _session.api.bulkAssets(
          BulkRequest(ids: part, action: BulkRequestActionEnum.delete),
        );
      }
    } on ApiException {
      if (mounted) setState(() => _busy = false);
      _say(l.cullActionFailed);
      return;
    }
    if (!mounted) return;
    final left = [
      for (final photo in _photos)
        if (!gone.contains(photo.id)) photo,
    ];
    _say(l.cullMovedToTrash(gone.length));
    if (left.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _photos = left;
      _compared = [
        for (final id in _compared)
          if (!gone.contains(id)) id,
      ];
      _index = _index.clamp(0, left.length - 1);
      _resetZoom();
    });
  }

  Future<void> _picksToAlbum() async {
    final chosen = _withPick(1);
    final title = await showDialog<String>(
      context: context,
      builder: (_) => _AlbumNameDialog(count: chosen.length),
    );
    if (title == null || title.trim().isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      final album = await _session.api.createAlbum(
        AlbumCreate(title: title.trim()),
      );
      for (final part in chunksOf(chosen)) {
        await _session.api.addAlbumAssets(album!.id, AssetIds(ids: part));
      }
      _say(l.cullAlbumMade(chosen.length, title.trim()));
    } on ApiException {
      _say(l.cullActionFailed);
    }
    if (mounted) setState(() => _busy = false);
  }

  void _pointerDown(PointerDownEvent event) {
    _fingers++;
    if (_fingers == 1) {
      _start = event.position;
      _pinched = false;
    } else {
      _pinched = true;
    }
  }

  void _pointerUp(PointerUpEvent event) {
    _fingers = (_fingers - 1).clamp(0, 10);
    final start = _start;
    if (_fingers > 0 || start == null) return;
    _start = null;
    if (_pinched || _zoomed) return;
    final delta = event.position - start;
    final verdict = swipeVerdict(delta.dx, delta.dy);
    if (verdict != null) {
      _setPick(verdict);
      return;
    }
    final by = swipeMove(delta.dx, delta.dy);
    if (by != null) _move(by);
  }

  Widget _pane(TimelineItem item) => GestureDetector(
    onTap: () => _goTo(_photos.indexOf(item)),
    onDoubleTap: () => setState(() {
      if (_zoomed) {
        _resetZoom();
      } else {
        _transform.value = Matrix4.identity()..scaleByDouble(2.5, 2.5, 1, 1);
        _zoomed = true;
      }
    }),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _comparing && item.id == _current.id
              ? Palette.gold
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: ClipRect(
        child: InteractiveViewer(
          transformationController: _transform,
          minScale: 1,
          maxScale: 6,
          panEnabled: _zoomed,
          onInteractionEnd: (_) {
            final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
            if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
          },
          child: SizedBox.expand(
            child: AssetPicture(
              session: _session,
              id: item.id,
              version: previewVersion(item.blurhash),
              large: true,
              full: _zoomed,
              fit: BoxFit.contain,
              error: EmptyMessage(
                icon: Icons.broken_image_outlined,
                text: l.viewerScreenPhotoFailed,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _stage() {
    final shown = _comparing
        ? [
            for (final photo in _photos)
              if (_compared.contains(photo.id)) photo,
          ]
        : [_current];
    final rows = <List<TimelineItem>>[
      for (var at = 0; at < shown.length; at += 2)
        shown.sublist(at, at + 2 < shown.length ? at + 2 : shown.length),
    ];
    return Listener(
      key: const Key('cull-stage'),
      onPointerDown: _pointerDown,
      onPointerUp: _pointerUp,
      onPointerCancel: (_) {
        _fingers = 0;
        _start = null;
      },
      child: Column(
        children: [
          for (final row in rows)
            Expanded(
              child: Row(
                children: [
                  for (final item in row) Expanded(child: _pane(item)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _thumb(int at) {
    final item = _photos[at];
    final pick = _marks?[item.id]?.pick ?? 0;
    return GestureDetector(
      onTap: () => _goTo(at),
      child: Container(
        key: ValueKey('cull-thumb-$at'),
        width: 56,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: at == _index ? Palette.gold : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: pick < 0 ? 0.35 : 1,
              child: AssetPicture(
                session: _session,
                id: item.id,
                version: previewVersion(item.blurhash),
                memCacheWidth: 160,
                fit: BoxFit.cover,
                error: const SizedBox.shrink(),
              ),
            ),
            if (pick != 0)
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  pick > 0 ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: pick > 0 ? Palette.gold : Palette.err,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mark = _mark;
    final marks = _marks;
    final picks = marks == null ? 0 : _withPick(1).length;
    final rejects = marks == null ? 0 : _withPick(-1).length;
    final inCompare = _compared.contains(_current.id);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${_photos.length}'),
        actions: [
          IconButton(
            tooltip: inCompare ? l.cullRemoveFromCompare : l.cullAddToCompare,
            isSelected: inCompare,
            icon: Icon(
              Icons.compare_outlined,
              color: inCompare ? Palette.gold : Colors.white,
            ),
            onPressed: _toggleCompare,
          ),
          if (_compared.isNotEmpty)
            IconButton(
              tooltip: l.cullStopComparing,
              icon: const Icon(Icons.close_fullscreen),
              onPressed: () => setState(() {
                _compared = const [];
                _resetZoom();
              }),
            ),
          IconButton(
            tooltip: l.cullPicksToAlbum,
            icon: const Icon(Icons.photo_album_outlined),
            onPressed: picks == 0 || _busy ? null : _picksToAlbum,
          ),
          IconButton(
            tooltip: l.cullRejectsToTrash,
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: rejects == 0 || _busy ? null : _trashRejected,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_failed)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  l.cullLoadFailed,
                  style: TextStyle(color: Palette.err),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: marks == null
                    ? const SizedBox(height: 18)
                    : Text(
                        l.cullTally(picks, rejects),
                        key: const Key('cull-tally'),
                        style: const TextStyle(color: Colors.white70),
                      ),
              ),
            Expanded(child: _stage()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  ChoiceChip(
                    label: Text(l.cullPick),
                    selected: mark?.pick == 1,
                    onSelected: mark == null ? null : (_) => _setPick(1),
                  ),
                  ChoiceChip(
                    label: Text(l.cullReject),
                    selected: mark?.pick == -1,
                    onSelected: mark == null ? null : (_) => _setPick(-1),
                  ),
                  ChoiceChip(
                    label: Text(l.cullNoMark),
                    selected: mark?.pick == 0,
                    onSelected: mark == null ? null : (_) => _setPick(0),
                  ),
                  RatingRow(rating: mark?.rating ?? 0, onRate: _rate),
                ],
              ),
            ),
            SizedBox(
              height: 60,
              child: ListView.builder(
                controller: _strip,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _photos.length,
                itemBuilder: (_, at) => _thumb(at),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumNameDialog extends StatefulWidget {
  const _AlbumNameDialog({required this.count});

  final int count;

  @override
  State<_AlbumNameDialog> createState() => _AlbumNameDialogState();
}

class _AlbumNameDialogState extends State<_AlbumNameDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(l.cullPicksToAlbum),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('cull-album-name'),
          controller: _name,
          autofocus: true,
          maxLength: 200,
          decoration: InputDecoration(labelText: l.cullAlbumName),
        ),
        Text(l.cullAlbumWillHold(widget.count)),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(l.viewerScreenCancel),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, _name.text),
        child: Text(l.cullCreateAlbum),
      ),
    ],
  );
}
