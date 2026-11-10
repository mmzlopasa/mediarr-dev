import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';
import 'package:video_player/video_player.dart';

import '../cast/tv_controller.dart';
import '../cast/tv_sheet.dart';
import '../services/session.dart';
import '../services/slideshow.dart';
import '../l10n/l10n.dart';

String transitionName(SlideChange transition) => switch (transition) {
  SlideChange.fade => l.slideshowScreenCrossfade,
  SlideChange.slide => l.slideshowScreenSlide,
  SlideChange.zoom => l.slideshowScreenSlowZoom,
  SlideChange.none => l.slideshowScreenNone,
};

/// The photos of a list one after another, full screen, from the one that was open.
class SlideshowScreen extends ConsumerStatefulWidget {
  const SlideshowScreen({
    super.key,
    required this.session,
    required this.items,
    required this.startId,
  });

  final Session session;
  final List<TimelineItem> items;
  final String startId;

  @override
  ConsumerState<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends ConsumerState<SlideshowScreen> {
  SlideshowSettings _settings = const SlideshowSettings();
  late List<TimelineItem> _order = playOrder(
    widget.items,
    (item) => item.id == widget.startId,
    false,
  );
  int _index = 0;
  bool _paused = false;
  bool _controls = true;
  bool _ended = false;
  String _caption = '';
  Timer? _timer;
  Timer? _hide;

  TimelineItem? get _slide => _order.isEmpty ? null : _order[_index];

  @override
  void initState() {
    super.initState();
    KeepAwake.set(true);
    SlideshowSettings.load().then((settings) {
      if (!mounted) return;
      setState(() {
        _settings = settings;
        if (settings.shuffle) {
          _order = playOrder(
            widget.items,
            (item) => item.id == widget.startId,
            true,
          );
        }
      });
      _play();
    });
    _wake();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hide?.cancel();
    KeepAwake.set(false);
    super.dispose();
  }

  String _url(String id) => widget.session.thumbnailUrl(id, large: true);

  /// Each photo stays for the chosen time; a video plays to its end instead.
  void _play() {
    _timer?.cancel();
    final slide = _slide;
    if (slide == null || _paused) return;
    _loadCaption(slide);
    _precacheNext();
    if (slide.kind == TimelineItemKindEnum.video) return;
    _timer = Timer(Duration(seconds: _settings.seconds), () => _go(1));
  }

  void _go(int step) {
    final next = nextSlide(_index, _order.length, _settings.loop, step);
    if (next == null) {
      setState(() {
        _ended = true;
        _paused = true;
      });
      _timer?.cancel();
      return;
    }
    setState(() {
      _ended = false;
      _index = next;
    });
    _play();
    _followOnTv();
  }

  /// The TV shows the same slide as the phone.
  void _followOnTv() {
    final slide = _slide;
    if (slide == null) return;
    ref
        .read(tvProvider.notifier)
        .follow(
          TvAsset(slide.id, video: slide.kind == TimelineItemKindEnum.video),
        );
  }

  void _precacheNext() {
    final next = nextSlide(_index, _order.length, _settings.loop);
    if (next == null || !mounted) return;
    final upcoming = _order[next];
    if (upcoming.kind == TimelineItemKindEnum.video) return;
    precacheImage(
      CachedNetworkImageProvider(
        _url(upcoming.id),
        headers: widget.session.headers,
      ),
      context,
    ).ignore();
  }

  Future<void> _loadCaption(TimelineItem slide) async {
    if (!_settings.caption) {
      if (_caption.isNotEmpty) setState(() => _caption = '');
      return;
    }
    try {
      final detail = await widget.session.detail(slide.id);
      if (!mounted || _slide?.id != slide.id || detail == null) return;
      final local = DateTime.tryParse(detail.localAt);
      final day = local == null
          ? ''
          : MaterialLocalizations.of(context).formatMediumDate(local);
      final place = [
        detail.city,
        detail.country,
      ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
      setState(
        () => _caption = [day, place].where((p) => p.isNotEmpty).join(' · '),
      );
    } on ApiException {
      // Without the caption, the photo still shows.
    }
  }

  void _wake() {
    setState(() => _controls = true);
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controls = false);
    });
  }

  void _togglePause() {
    setState(() {
      if (_ended) {
        _index = 0;
        _ended = false;
      }
      _paused = !_paused;
    });
    if (_paused) {
      _timer?.cancel();
    } else {
      _play();
    }
  }

  void _change(SlideshowSettings next) {
    final reshuffle = next.shuffle != _settings.shuffle;
    final current = _slide?.id ?? widget.startId;
    setState(() {
      _settings = next;
      if (reshuffle) {
        _order = playOrder(
          widget.items,
          (item) => item.id == current,
          next.shuffle,
        );
        _index = 0;
      }
    });
    next.save();
    _play();
  }

  Future<void> _openSettings() async {
    _hide?.cancel();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          void update(SlideshowSettings next) {
            _change(next);
            setSheet(() {});
          }

          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  l.slideshowScreenSettings,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(l.slideshowScreenPace),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final seconds in slidePaces)
                      ChoiceChip(
                        label: Text('$seconds s'),
                        selected: _settings.seconds == seconds,
                        onSelected: (_) =>
                            update(_settings.copyWith(seconds: seconds)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(l.slideshowScreenTransition),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final transition in SlideChange.values)
                      ChoiceChip(
                        label: Text(transitionName(transition)),
                        selected: _settings.transition == transition,
                        onSelected: (_) =>
                            update(_settings.copyWith(transition: transition)),
                      ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.slideshowScreenShuffle),
                  value: _settings.shuffle,
                  onChanged: (on) => update(_settings.copyWith(shuffle: on)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.slideshowScreenLoop),
                  value: _settings.loop,
                  onChanged: (on) => update(_settings.copyWith(loop: on)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.slideshowScreenDateAndPlace),
                  value: _settings.caption,
                  onChanged: (on) => update(_settings.copyWith(caption: on)),
                ),
              ],
            ),
          );
        },
      ),
    );
    _wake();
  }

  Widget _media(TimelineItem slide, SlideChange transition) {
    if (slide.kind == TimelineItemKindEnum.video) {
      return _SlideVideo(
        key: ValueKey('video-${slide.id}'),
        session: widget.session,
        id: slide.id,
        onEnded: () {
          if (!_paused) _go(1);
        },
      );
    }
    Widget image = CachedNetworkImage(
      key: ValueKey(slide.id),
      imageUrl: _url(slide.id),
      httpHeaders: widget.session.headers,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: Duration.zero,
    );
    if (transition == SlideChange.zoom) {
      // The slow zoom lasts as long as the photo stays.
      image = TweenAnimationBuilder<double>(
        key: ValueKey('zoom-${slide.id}'),
        tween: Tween(begin: 1, end: 1.08),
        duration: Duration(seconds: _settings.seconds + 1),
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: image,
      );
    }
    return image;
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slide;
    final transition = shownTransition(
      _settings.transition,
      MediaQuery.of(context).disableAnimations,
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _wake,
        onHorizontalDragEnd: (details) {
          final speed = details.primaryVelocity ?? 0;
          if (speed.abs() > 200) _go(speed < 0 ? 1 : -1);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (slide != null)
              AnimatedSwitcher(
                duration: transition == SlideChange.none
                    ? Duration.zero
                    : const Duration(milliseconds: 650),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) =>
                    transition == SlideChange.slide
                    ? SlideTransition(
                        position: Tween(
                          begin: const Offset(0.06, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      )
                    : FadeTransition(opacity: animation, child: child),
                child: KeyedSubtree(
                  key: ValueKey('slide-${slide.id}'),
                  child: _media(slide, transition),
                ),
              ),
            if (_settings.caption && _caption.isNotEmpty)
              Positioned(left: 16, bottom: 96, child: _Pill(text: _caption)),
            if (_ended)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(child: _Pill(text: l.slideshowScreenTheEnd)),
              ),
            AnimatedOpacity(
              opacity: _controls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_controls,
                child: _Controls(
                  count: '${_index + 1} / ${_order.length}',
                  paused: _paused,
                  onPrevious: () {
                    _go(-1);
                    _wake();
                  },
                  onPause: () {
                    _togglePause();
                    _wake();
                  },
                  onNext: () {
                    _go(1);
                    _wake();
                  },
                  onSettings: _openSettings,
                  onTv: castable(widget.session) && slide != null
                      ? () => showTvSheet(
                          context,
                          widget.session,
                          TvAsset(
                            slide.id,
                            video: slide.kind == TimelineItemKindEnum.video,
                          ),
                        )
                      : null,
                  casting: ref.watch(tvProvider).device != null,
                  onClose: () => Navigator.of(context).pop(_slide?.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(text, style: const TextStyle(color: Colors.white)),
  );
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.count,
    required this.paused,
    required this.onPrevious,
    required this.onPause,
    required this.onNext,
    required this.onSettings,
    required this.onClose,
    this.onTv,
    this.casting = false,
  });

  final VoidCallback? onTv;
  final bool casting;

  final String count;
  final bool paused;
  final VoidCallback onPrevious;
  final VoidCallback onPause;
  final VoidCallback onNext;
  final VoidCallback onSettings;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black54],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TvBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      count,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: l.slideshowScreenPrevious,
                    color: Colors.white,
                    icon: const Icon(Icons.skip_previous),
                    onPressed: onPrevious,
                  ),
                  IconButton(
                    tooltip: paused
                        ? l.slideshowScreenPlay
                        : l.slideshowScreenPause,
                    color: Colors.white,
                    iconSize: 34,
                    icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                    onPressed: onPause,
                  ),
                  IconButton(
                    tooltip: l.slideshowScreenNext,
                    color: Colors.white,
                    icon: const Icon(Icons.skip_next),
                    onPressed: onNext,
                  ),
                  const Spacer(),
                  if (onTv != null)
                    IconButton(
                      tooltip: l.slideshowScreenPlayOnTv,
                      color: Colors.white,
                      isSelected: casting,
                      icon: Icon(casting ? Icons.cast_connected : Icons.cast),
                      onPressed: onTv,
                    ),
                  IconButton(
                    tooltip: l.slideshowScreenSettings,
                    color: Colors.white,
                    icon: const Icon(Icons.tune),
                    onPressed: onSettings,
                  ),
                  IconButton(
                    tooltip: l.slideshowScreenClose,
                    color: Colors.white,
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A video in the slideshow: silent, to its end.
class _SlideVideo extends StatefulWidget {
  const _SlideVideo({
    super.key,
    required this.session,
    required this.id,
    required this.onEnded,
  });

  final Session session;
  final String id;
  final VoidCallback onEnded;

  @override
  State<_SlideVideo> createState() => _SlideVideoState();
}

class _SlideVideoState extends State<_SlideVideo> {
  late final VideoPlayerController _video = VideoPlayerController.networkUrl(
    Uri.parse(widget.session.originalUrl(widget.id)),
    httpHeaders: widget.session.headers,
  );
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _video.setVolume(0);
    _video.addListener(_watch);
    _video.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _video.play();
      }
    }, onError: (Object _) => _finish());
  }

  void _watch() {
    final value = _video.value;
    if (value.hasError ||
        (value.isInitialized &&
            value.duration > Duration.zero &&
            value.position >= value.duration)) {
      _finish();
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onEnded();
  }

  @override
  void dispose() {
    _video
      ..removeListener(_watch)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: _video.value.isInitialized
        ? AspectRatio(
            aspectRatio: _video.value.aspectRatio,
            child: VideoPlayer(_video),
          )
        : CachedNetworkImage(
            imageUrl: widget.session.thumbnailUrl(widget.id, large: true),
            httpHeaders: widget.session.headers,
            fit: BoxFit.contain,
          ),
  );
}
