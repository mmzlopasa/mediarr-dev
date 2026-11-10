import 'dart:io';

import '../motion.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';
import 'package:video_player/video_player.dart';

import '../l10n/l10n.dart';
import '../services/session.dart';
import '../services/trash.dart';
import '../services/settings.dart';
import '../services/timeline.dart';
import '../theme.dart';
import 'share_sheet.dart';
import '../timeline/layout.dart';
import 'album_sheets.dart';
import 'asset_facts.dart';
import 'asset_picture.dart';
import 'duplicates_screen.dart';
import 'faces_section.dart';
import 'panorama_view.dart';
import '../cast/tv_controller.dart';
import '../cast/tv_sheet.dart';
import 'slideshow_screen.dart';
import 'photo_editor_screen.dart';

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
  int _revision = 0;
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  bool _zoomed = false;

  /// A 360° panorama opens as one; the button shows it flat.
  bool _flat = false;

  /// One tap hides the bars and the status bar, so the whole photo shows; the next brings them back.
  bool _chrome = true;

  void _toggleChrome() {
    setState(() => _chrome = !_chrome);
    SystemChrome.setEnabledSystemUIMode(
      _chrome ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
  }

  @override
  void dispose() {
    if (!_chrome) SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
        title: Text(l.viewerScreenDeleteTitle),
        content: TrashSentence(
          (days) => days == null
              ? l.viewerScreenTrashNoDays
              : l.viewerScreenTrashDays(days),
        ),
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
            .showSnackBar(SnackBar(content: Text(l.viewerScreenActionFailed)));
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
        messenger.showSnackBar(SnackBar(content: Text(l.viewerScreenNoVideo)));
        return;
      }
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => _LivePlayer(session: session, url: url!),
        ),
      );
    } on ApiException {
      messenger.showSnackBar(
        SnackBar(content: Text(l.viewerScreenVideoFailed)),
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
    ref.watch(settingsProvider);
    final store = widget.store ?? library;
    final session = widget.session ?? ref.watch(sessionProvider).value;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _page(store, session),
    );
  }

  /// The edges turn the page when the setting asks for it; anywhere else shows or hides the bars.
  void _tap(TapUpDetails details, {required bool navigate}) {
    final width = MediaQuery.sizeOf(context).width;
    final x = details.globalPosition.dx;
    const turn = Duration(milliseconds: 200);
    if (navigate && x < width / 4) {
      _pages.previousPage(duration: turn, curve: Curves.easeOut);
    } else if (navigate && x > width * 3 / 4) {
      _pages.nextPage(duration: turn, curve: Curves.easeOut);
    } else {
      _toggleChrome();
    }
  }

  Widget _page(TimelineStore store, Session? session) {
    final settings = ref.read(settingsProvider);
    final items = store.loadedItems;
    if (session == null || items.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    final index = _index.clamp(0, items.length - 1);
    final current = items[index];
    // Someone else's photo can be looked at, but only its owner changes it.
    final mine =
        !widget.readOnly &&
        !ref.read(settingsProvider).readOnly &&
        current.isShared != true;
    // Turning a panorama uses the same drags as moving to the next photo and closing.
    final turning = current.isPanorama == true && !_flat;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _Hideable(
        shown: _chrome,
        child: AppBar(
          backgroundColor: Colors.black38,
          foregroundColor: Colors.white,
          actions: fitActions(context, [
            if (mine && current.stackSize != null)
              ViewerAction(
                priority: 9,
                tooltip: l.viewerScreenStackShots,
                icon: const Icon(Icons.burst_mode),
                onPressed: () => showStackSheet(
                  context,
                  session,
                  current.id,
                  () => store.refresh(reloadLoaded: true),
                ),
              ),
            ViewerAction(
              priority: 3,
              tooltip: l.viewerScreenSlideshow,
              icon: const Icon(Icons.slideshow_outlined),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final items = await store.playlist(current.id);
                if (!mounted) return;
                final last = await navigator.push<String>(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => SlideshowScreen(
                      session: session,
                      items: items,
                      startId: current.id,
                    ),
                  ),
                );
                // Back where the slideshow stopped.
                final at = store.loadedItems.indexWhere(
                  (item) => item.id == last,
                );
                if (at >= 0 && mounted) _pages.jumpToPage(at);
              },
            ),
            if (current.isPanorama == true)
              ViewerAction(
                priority: 2,
                tooltip: _flat ? l.viewerScreen360View : l.viewerScreenFlatView,
                selected: !_flat,
                icon: const Icon(Icons.threesixty),
                onPressed: () => setState(() => _flat = !_flat),
              ),
            if (current.isLive == true)
              ViewerAction(
                priority: 7,
                tooltip: l.viewerScreenPlayLive,
                icon: const Icon(Icons.motion_photos_on_outlined),
                onPressed: () => _playLive(session, current),
              ),
            if (widget.albumId != null)
              ViewerAction(
                priority: 8,
                tooltip: l.viewerScreenCommentsAndHearts,
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
              ViewerAction(
                priority: 4,
                tooltip: l.viewerScreenFavorite,
                icon: Pulse(
                  on: current.isFavorite,
                  child: Icon(
                    current.isFavorite ? Icons.star : Icons.star_border,
                    color: current.isFavorite ? Palette.gold : Colors.white,
                  ),
                ),
                onPressed: () => _favorite(current),
              ),
            if (mine && current.kind == TimelineItemKindEnum.photo)
              ViewerAction(
                priority: 10,
                tooltip: l.viewerScreenEdit,
                icon: const Icon(Icons.tune),
                onPressed: () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) =>
                          PhotoEditorScreen(session: session, id: current.id),
                    ),
                  );
                  if (changed != true) return;
                  await store.refresh(reloadLoaded: true);
                  if (mounted) setState(() => _revision++);
                },
              ),
            if (castable(session))
              ViewerAction(
                priority: 6,
                tooltip: l.viewerScreenPlayOnTv,
                selected: ref.watch(tvProvider).device != null,
                icon: Icon(
                  ref.watch(tvProvider).device != null
                      ? Icons.cast_connected
                      : Icons.cast,
                ),
                onPressed: () => showTvSheet(
                  context,
                  session,
                  TvAsset(
                    current.id,
                    video: current.kind == TimelineItemKindEnum.video,
                  ),
                ),
              ),
            ViewerAction(
              priority: 0,
              tooltip: l.viewerScreenShare,
              icon: Icon(
                Platform.isIOS ? Icons.ios_share : Icons.share_outlined,
              ),
              onPressed: () => shareAssets(context, ref, session, [current.id]),
            ),
            ViewerAction(
              priority: 1,
              tooltip: l.viewerScreenDetails,
              icon: const Icon(Icons.info_outline),
              onPressed: () => _info(session, current),
            ),
            if (mine)
              ViewerAction(
                priority: 5,
                tooltip: l.viewerScreenDelete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(current),
              ),
          ]),
        ),
      ),
      bottomNavigationBar: const TvBar(),
      body: DragToDismiss(
        enabled: !_zoomed && !turning,
        onDismiss: () => Navigator.of(context).maybePop(),
        child: GestureDetector(
          onTapUp: turning
              ? null
              : (details) =>
                    _tap(details, navigate: settings.tapToNavigate && !_zoomed),
          child: PageView.builder(
            controller: _pages,
            physics: _zoomed || turning
                ? const NeverScrollableScrollPhysics()
                : null,
            itemCount: items.length,
            onPageChanged: (value) {
              setState(() {
                _index = value;
                _zoomed = false;
                _flat = false;
              });
              // The TV follows the photo on the phone.
              final shown = items[value];
              ref
                  .read(tvProvider.notifier)
                  .follow(
                    TvAsset(
                      shown.id,
                      video: shown.kind == TimelineItemKindEnum.video,
                    ),
                  );
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
                  autoPlay: settings.autoPlay,
                  loop: settings.loopVideos,
                  forceOriginal: settings.forceOriginalVideo,
                );
              }
              if (item.isPanorama == true && !_flat && page == index) {
                return PanoramaView(
                  key: ValueKey('pano-${item.id}'),
                  url: session.fullPhotoUrl(item.id),
                  headers: session.headers,
                );
              }
              return _PhotoPage(
                key: ValueKey('${item.id}-$_revision'),
                session: session,
                id: item.id,
                version: previewVersion(item.blurhash),
                full: settings.loadOriginal,
                onZoom: (zoomed) {
                  if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The viewer's top bar, which fades away while the photo is shown alone.
class _Hideable extends StatelessWidget implements PreferredSizeWidget {
  const _Hideable({required this.shown, required this.child});

  final bool shown;
  final PreferredSizeWidget child;

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !shown,
    child: AnimatedOpacity(
      opacity: shown ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: child,
    ),
  );
}

class _PhotoPage extends StatefulWidget {
  const _PhotoPage({
    super.key,
    required this.session,
    required this.id,
    this.version,
    this.full = false,
    required this.onZoom,
  });

  final String? version;
  final Session session;
  final String id;
  final bool full;
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
          version: widget.version,
          large: true,
          full: widget.full,
          fit: BoxFit.contain,
          error: EmptyMessage(
            icon: Icons.broken_image_outlined,
            text: l.viewerScreenPhotoFailed,
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
    this.autoPlay = false,
    this.loop = false,
    this.forceOriginal = false,
  });

  final Session session;
  final String id;
  final bool active;
  final bool autoPlay;
  final bool loop;
  final bool forceOriginal;

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  VideoPlayerController? _controller;
  bool _starting = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.active && widget.autoPlay) _start();
  }

  @override
  void didUpdateWidget(_VideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) _controller?.pause();
    if (widget.active &&
        !oldWidget.active &&
        widget.autoPlay &&
        _controller == null) {
      _start();
    }
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
    // A second tap while the first is still starting would start a second player.
    if (_starting) return;
    _starting = true;
    try {
      await _open();
    } finally {
      _starting = false;
    }
  }

  Future<void> _open() async {
    AssetDetail? detail;
    try {
      detail = await widget.session.detail(widget.id);
    } on ApiException {
      // The original still plays.
    }
    if (!mounted) {
      return;
    }
    // The original first when it is wanted, and the converted version if this phone cannot play it,
    // as some cannot play every original.
    final stream = detail?.hlsReady == true
        ? widget.session.hlsUrl(widget.id)
        : null;
    final original = widget.session.originalUrl(widget.id);
    final tries = [
      if (widget.forceOriginal || stream == null) original,
      ?stream,
      if (!widget.forceOriginal && stream != null) original,
    ];
    for (final url in tries) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: widget.session.headers,
      );
      setState(() => _controller = controller);
      try {
        await controller.initialize();
        if (!mounted) {
          await controller.dispose();
          return;
        }
        await controller.setLooping(widget.loop);
        await controller.play();
        if (mounted) setState(() {});
        return;
      } catch (_) {
        await controller.dispose();
        if (!mounted) return;
        setState(() => _controller = null);
      }
    }
    if (mounted) setState(() => _failed = true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) {
      return EmptyMessage(
        icon: Icons.videocam_off_outlined,
        text: l.viewerScreenCannotPlay,
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
                  : CircularProgressIndicator(color: Palette.gold),
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
              colors: VideoProgressColors(playedColor: Palette.gold),
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
          ? EmptyMessage(
              icon: Icons.videocam_off_outlined,
              text: l.viewerScreenCannotPlay,
            )
          : _controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          : CircularProgressIndicator(color: Palette.gold),
    ),
  );
}

class _InfoSheet extends StatefulWidget {
  const _InfoSheet({required this.session, required this.id});

  final Session session;
  final String id;

  @override
  State<_InfoSheet> createState() => _InfoSheetState();
}

class _InfoSheetState extends State<_InfoSheet> {
  Session get session => widget.session;
  String get id => widget.id;
  late Future<AssetDetail?> _detail = session.detail(id);

  Future<void> _editFacts(AssetDetail detail) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => AssetFactsDialog(session: session, detail: detail),
    );
    if (changed == true && mounted) {
      setState(() => _detail = session.detail(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: FutureBuilder<AssetDetail?>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return SizedBox(
              height: 200,
              child: EmptyMessage(
                icon: Icons.cloud_off,
                text: l.viewerScreenDetailsFailed,
              ),
            );
          }
          final detail = snapshot.data;
          if (detail == null) {
            return SizedBox(
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
            if (detail.isMissing == true)
              (l.viewerScreenUnavailable, l.viewerScreenMissingFile),
            (l.viewerScreenName, detail.originalName),
            if (detail.description != null)
              (l.viewerScreenDescription, detail.description!),
            (
              detail.hasCaptureTime == true
                  ? l.viewerScreenTaken
                  : l.viewerScreenAdded,
              formatDateTime(detail.localAt),
            ),
            if (detail.width != null && detail.height != null)
              (l.viewerScreenDimensions, '${detail.width} × ${detail.height}'),
            (l.viewerScreenSize, formatBytes(detail.sizeBytes)),
            if (detail.durationMs != null)
              (l.viewerScreenDuration, formatDuration(detail.durationMs!)),
            if (detail.camera != null) (l.viewerScreenCamera, detail.camera!),
            if (detail.lens != null) (l.viewerScreenLens, detail.lens!),
            if (settings.isNotEmpty) (l.viewerScreenSettings, settings),
            if (detail.latitude != null && detail.longitude != null)
              (
                l.viewerScreenLocation,
                '${detail.latitude!.toStringAsFixed(5)}, ${detail.longitude!.toStringAsFixed(5)}',
              ),
          ];
          // Data from the camera and the file is set in mono; words are not.
          final data = {
            l.viewerScreenName,
            l.viewerScreenDimensions,
            l.viewerScreenSettings,
            l.viewerScreenLocation,
          };
          Future<void> rate(int stars) async {
            try {
              await session.api.setAssetFacts(id, AssetFacts(rating: stars));
              if (mounted) setState(() => _detail = session.detail(id));
            } on ApiException catch (cause) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.viewerScreenNotSaved(cause.message ?? '')),
                  ),
                );
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Titled as on the web: the caption, or else when it was taken.
                Text(
                  detail.caption?.trim().isNotEmpty == true
                      ? detail.caption!
                      : formatDateTime(detail.localAt),
                  style: displayTitle(26),
                ),
                if (detail.isOwner == true) ...[
                  const SizedBox(height: 8),
                  RatingRow(rating: detail.rating ?? 0, onRate: rate),
                ],
                const SizedBox(height: 8),
                for (final (label, value) in rows)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Palette.line)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        SizedBox(
                          width: 104,
                          child: Text(
                            label,
                            style: text.bodySmall?.copyWith(color: Palette.dim),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            value,
                            style: data.contains(label)
                                ? monoData(13)
                                : text.bodyMedium?.copyWith(color: Palette.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                FacesSection(session: session, assetId: id),
                if (detail.isOwner == true) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _editFacts(detail),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l.viewerScreenEditDetails),
                  ),
                ],
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

/// Pulling a photo down closes it, as in the phone's own gallery. It listens to the raw pointer
/// because the zoom underneath takes every gesture that is offered to it.
class DragToDismiss extends StatefulWidget {
  const DragToDismiss({
    super.key,
    required this.enabled,
    required this.onDismiss,
    required this.child,
  });

  final bool enabled;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  State<DragToDismiss> createState() => _DragToDismissState();
}

class _DragToDismissState extends State<DragToDismiss> {
  static const _startAfter = 18.0;
  static const _closeAfter = 110.0;

  final _pointers = <int>{};
  Offset? _start;
  double _offset = 0;
  bool _dragging = false;

  void _reset() {
    _start = null;
    _dragging = false;
    setState(() => _offset = 0);
  }

  void _move(PointerMoveEvent event) {
    final start = _start;
    if (start == null || !widget.enabled || _pointers.length != 1) return;
    final moved = event.position - start;
    if (!_dragging) {
      if (moved.dy < _startAfter || moved.dy.abs() < moved.dx.abs() * 1.5) {
        return;
      }
      _dragging = true;
    }
    setState(() => _offset = moved.dy.clamp(0, double.infinity).toDouble());
  }

  void _up(PointerUpEvent event) {
    _pointers.remove(event.pointer);
    final close = _dragging && _offset >= _closeAfter;
    _reset();
    if (close) widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final progress = (_offset / height).clamp(0.0, 1.0);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _pointers.add(event.pointer);
        _start = _pointers.length == 1 ? event.position : null;
      },
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: (event) {
        _pointers.remove(event.pointer);
        _reset();
      },
      child: Opacity(
        opacity: 1 - progress * 0.6,
        child: Transform.translate(
          offset: Offset(0, _offset),
          child: Transform.scale(
            scale: 1 - progress * 0.25,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// One button of the viewer's bar. The lower the priority, the longer it stays a button when the
/// screen is narrow; the rest go into a menu.
class ViewerAction {
  const ViewerAction({
    required this.priority,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected,
  });

  final int priority;
  final String tooltip;
  final Widget icon;
  final VoidCallback onPressed;
  final bool? selected;
}

/// As many buttons as fit beside the back button, in their order, and a menu with the rest.
List<Widget> fitActions(BuildContext context, List<ViewerAction> actions) {
  const button = 48.0;
  final width = MediaQuery.sizeOf(context).width;
  final room = ((width - kToolbarHeight - 8) / button).floor();
  var shown = actions;
  var hidden = <ViewerAction>[];
  if (actions.length > room) {
    final keep =
        (actions.toList()..sort((a, b) => a.priority.compareTo(b.priority)))
            .take(room - 1)
            .toSet();
    shown = actions.where(keep.contains).toList();
    hidden = actions.where((action) => !keep.contains(action)).toList();
  }
  return [
    for (final action in shown)
      IconButton(
        tooltip: action.tooltip,
        isSelected: action.selected,
        icon: action.icon,
        onPressed: action.onPressed,
      ),
    if (hidden.isNotEmpty)
      PopupMenuButton<ViewerAction>(
        tooltip: l.viewerScreenMore,
        icon: const Icon(Icons.more_vert),
        onSelected: (action) => action.onPressed(),
        itemBuilder: (_) => [
          for (final action in hidden)
            PopupMenuItem(
              value: action,
              child: Row(
                children: [
                  IconTheme(
                    data: IconThemeData(color: Palette.ink),
                    child: action.icon,
                  ),
                  const SizedBox(width: 12),
                  Flexible(child: Text(action.tooltip)),
                ],
              ),
            ),
        ],
      ),
  ];
}
