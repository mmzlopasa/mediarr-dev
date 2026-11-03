import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';
import 'package:video_player/video_player.dart';

import '../services/session.dart';
import '../services/timeline.dart';
import '../theme.dart';
import '../timeline/layout.dart';
import 'album_sheets.dart';
import 'asset_picture.dart';
import 'duplicates_screen.dart';

/// A full screen view on a clean black background: colors around a photo must not affect it.
class ViewerScreen extends ConsumerStatefulWidget {
  const ViewerScreen({
    super.key,
    required this.initialIndex,
    this.store,
    this.albumId,
    this.session,
    this.readOnly = false,
  });

  final int initialIndex;

  /// What to move through. Without it, the library.
  final TimelineStore? store;

  /// With an album, the photo also has its comments and hearts.
  final String? albumId;

  /// Where the files come from. Without it, the signed-in library.
  final Session? session;

  /// Only for looking: moving a photo goes through the actions of where it is.
  final bool readOnly;

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  bool _zoomed = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  TimelineStore get _store => widget.store ?? ref.read(timelineProvider);

  Future<void> _favorite(TimelineItem item) async {
    final store = _store;
    await _guard(
      () => store.act(
        [item.id],
        item.isFavorite
            ? BulkRequestActionEnum.unfavorite
            : BulkRequestActionEnum.favorite,
      ),
    );
  }

  Future<void> _delete(TimelineItem item) async {
    final store = _store;
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this photo?'),
        content: const Text(
          'It moves to the trash, where it stays for 30 days and can be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Palette.err)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final done = await _guard(
      () => store.act([item.id], BulkRequestActionEnum.delete),
    );
    if (done && store.loadedItems.isEmpty) navigator.pop();
  }

  Future<bool> _guard(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } on ApiException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('The action failed.')));
      }
      return false;
    }
  }

  /// Plays the moving part of a Live Photo or an Android Motion Photo.
  Future<void> _playLive(Session session, TimelineItem item) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final detail = await session.detail(item.id);
      final liveId = detail?.liveVideoId;
      String? url;
      if (detail?.hasMotion == true) {
        url = session.motionUrl(item.id);
      } else if (liveId != null) {
        final video = await session.detail(liveId);
        url = video?.hlsReady == true
            ? session.hlsUrl(liveId)
            : session.originalUrl(liveId);
      }
      if (url == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('This photo has no video.')),
        );
        return;
      }
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => _LivePlayer(session: session, url: url!),
        ),
      );
    } on ApiException {
      messenger.showSnackBar(
        const SnackBar(content: Text('The video could not be loaded.')),
      );
    }
  }

  void _info(Session session, TimelineItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _InfoSheet(session: session, id: item.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(timelineProvider);
    final store = widget.store ?? library;
    final session = widget.session ?? ref.watch(sessionProvider).value;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _page(store, session),
    );
  }

  Widget _page(TimelineStore store, Session? session) {
    final items = store.loadedItems;
    if (session == null || items.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    final index = _index.clamp(0, items.length - 1);
    final current = items[index];
    // Someone else's photo can be looked at, but only its owner changes it.
    final mine = !widget.readOnly && current.isShared != true;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black38,
        foregroundColor: Colors.white,
        actions: [
          if (mine && current.stackSize != null)
            IconButton(
              tooltip: 'Shots in this stack',
              icon: const Icon(Icons.burst_mode),
              onPressed: () => showStackSheet(
                context,
                session,
                current.id,
                () => store.refresh(reloadLoaded: true),
              ),
            ),
          if (current.isLive == true)
            IconButton(
              tooltip: 'Play Live Photo',
              icon: const Icon(Icons.motion_photos_on_outlined),
              onPressed: () => _playLive(session, current),
            ),
          if (widget.albumId != null)
            IconButton(
              tooltip: 'Comments and hearts',
              icon: const Icon(Icons.favorite_border),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => ActivitySheet(
                  session: session,
                  albumId: widget.albumId!,
                  assetId: current.id,
                ),
              ),
            ),
          if (mine)
            IconButton(
              tooltip: 'Favorite',
              icon: Icon(
                current.isFavorite ? Icons.star : Icons.star_border,
                color: current.isFavorite ? Palette.gold : Colors.white,
              ),
              onPressed: () => _favorite(current),
            ),
          IconButton(
            tooltip: 'Details',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _info(session, current),
          ),
          if (mine)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(current),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pages,
        physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
        itemCount: items.length,
        onPageChanged: (value) {
          setState(() {
            _index = value;
            _zoomed = false;
          });
          // Moving towards the end of what is loaded fetches the next month.
          if (value >= items.length - 3) {
            final months = store.months ?? const <TimelineMonth>[];
            for (final month in months) {
              if (month.items == null) {
                store.load(month);
                break;
              }
            }
          }
        },
        itemBuilder: (context, page) {
          final item = items[page];
          if (item.kind == TimelineItemKindEnum.video) {
            return _VideoPage(
              key: ValueKey(item.id),
              session: session,
              id: item.id,
              active: page == index,
            );
          }
          return _PhotoPage(
            key: ValueKey(item.id),
            session: session,
            id: item.id,
            onZoom: (zoomed) {
              if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
            },
          );
        },
      ),
    );
  }
}

class _PhotoPage extends StatefulWidget {
  const _PhotoPage({
    super.key,
    required this.session,
    required this.id,
    required this.onZoom,
  });

  final Session session;
  final String id;
  final void Function(bool zoomed) onZoom;

  @override
  State<_PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<_PhotoPage> {
  final _transform = TransformationController();
  Offset _tap = Offset.zero;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _doubleTap() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed) {
      _transform.value = Matrix4.identity();
    } else {
      const scale = 2.5;
      _transform.value = Matrix4.identity()
        ..translateByDouble(
          -_tap.dx * (scale - 1),
          -_tap.dy * (scale - 1),
          0,
          1,
        )
        ..scaleByDouble(scale, scale, scale, 1);
    }
    widget.onZoom(!zoomed);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onDoubleTapDown: (details) => _tap = details.localPosition,
    onDoubleTap: _doubleTap,
    child: InteractiveViewer(
      transformationController: _transform,
      minScale: 1,
      maxScale: 6,
      onInteractionEnd: (_) =>
          widget.onZoom(_transform.value.getMaxScaleOnAxis() > 1.01),
      child: SizedBox.expand(
        child: AssetPicture(
          session: widget.session,
          id: widget.id,
          large: true,
          fit: BoxFit.contain,
          error: const EmptyMessage(
            icon: Icons.broken_image_outlined,
            text: 'This photo could not be loaded.',
          ),
        ),
      ),
    ),
  );
}

class _VideoPage extends StatefulWidget {
  const _VideoPage({
    super.key,
    required this.session,
    required this.id,
    required this.active,
  });

  final Session session;
  final String id;
  final bool active;

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void didUpdateWidget(_VideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) _controller?.pause();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final existing = _controller;
    if (existing != null) {
      existing.value.isPlaying ? await existing.pause() : await existing.play();
      if (mounted) setState(() {});
      return;
    }
    AssetDetail? detail;
    try {
      detail = await widget.session.detail(widget.id);
    } on ApiException {
      // The original still plays.
    }
    if (!mounted) {
      return;
    }
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(
        detail?.hlsReady == true
            ? widget.session.hlsUrl(widget.id)
            : widget.session.originalUrl(widget.id),
      ),
      httpHeaders: widget.session.headers,
    );
    setState(() => _controller = controller);
    try {
      await controller.initialize();
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) {
      return const EmptyMessage(
        icon: Icons.videocam_off_outlined,
        text: 'This video cannot be played on this device.',
      );
    }
    if (controller == null || !controller.value.isInitialized) {
      return GestureDetector(
        onTap: controller == null ? _start : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AssetPicture(
              session: widget.session,
              id: widget.id,
              large: true,
              fit: BoxFit.contain,
              error: const SizedBox.shrink(),
            ),
            Center(
              child: controller == null
                  ? const Icon(
                      Icons.play_circle_fill,
                      size: 72,
                      color: Colors.white,
                    )
                  : const CircularProgressIndicator(color: Palette.gold),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: _start,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          SafeArea(
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(playedColor: Palette.gold),
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePlayer extends StatefulWidget {
  const _LivePlayer({required this.session, required this.url});

  final Session session;
  final String url;

  @override
  State<_LivePlayer> createState() => _LivePlayerState();
}

class _LivePlayerState extends State<_LivePlayer> {
  late final VideoPlayerController _controller =
      VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        httpHeaders: widget.session.headers,
      );
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller
        .initialize()
        .then((_) async {
          await _controller.setLooping(true);
          await _controller.play();
          if (mounted) {
            setState(() {});
          }
        })
        .catchError((Object _) {
          if (mounted) {
            setState(() => _failed = true);
          }
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black38,
      foregroundColor: Colors.white,
    ),
    body: Center(
      child: _failed
          ? const EmptyMessage(
              icon: Icons.videocam_off_outlined,
              text: 'This video cannot be played on this device.',
            )
          : _controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          : const CircularProgressIndicator(color: Palette.gold),
    ),
  );
}

class _InfoSheet extends StatelessWidget {
  const _InfoSheet({required this.session, required this.id});

  final Session session;
  final String id;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: FutureBuilder<AssetDetail?>(
        future: session.detail(id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const SizedBox(
              height: 200,
              child: EmptyMessage(
                icon: Icons.cloud_off,
                text: 'The details could not be loaded.',
              ),
            );
          }
          final detail = snapshot.data;
          if (detail == null) {
            return const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: Palette.gold),
              ),
            );
          }
          final settings = [
            if (detail.fNumber != null) 'f/${detail.fNumber}',
            if (detail.exposureTime != null)
              '${_exposure(detail.exposureTime!)} s',
            if (detail.focalLength != null) '${detail.focalLength} mm',
            if (detail.iso != null) 'ISO ${detail.iso}',
          ].join(' · ');
          final rows = <(String, String)>[
            ('Name', detail.originalName),
            (
              detail.hasCaptureTime == true ? 'Taken' : 'Added',
              formatDateTime(detail.localAt),
            ),
            if (detail.width != null && detail.height != null)
              ('Dimensions', '${detail.width} × ${detail.height}'),
            ('Size', formatBytes(detail.sizeBytes)),
            if (detail.durationMs != null)
              ('Duration', formatDuration(detail.durationMs!)),
            if (detail.camera != null) ('Camera', detail.camera!),
            if (detail.lens != null) ('Lens', detail.lens!),
            if (settings.isNotEmpty) ('Settings', settings),
            if (detail.latitude != null && detail.longitude != null)
              (
                'Location',
                '${detail.latitude!.toStringAsFixed(5)}, ${detail.longitude!.toStringAsFixed(5)}',
              ),
          ];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Details', style: text.titleLarge),
                const SizedBox(height: 10),
                for (final (label, value) in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: text.bodyMedium?.copyWith(color: Palette.dim),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            value,
                            textAlign: TextAlign.right,
                            style: text.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _exposure(String value) {
    final seconds = double.tryParse(value);
    return seconds != null && seconds > 0 && seconds < 1
        ? '1/${(1 / seconds).round()}'
        : value;
  }
}
