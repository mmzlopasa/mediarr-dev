import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../services/timeline.dart';
import '../theme.dart';
import '../timeline/layout.dart';
import 'asset_picture.dart';
import 'viewer_screen.dart';
import '../l10n/l10n.dart';

const cleanupCategories = [
  CleanupCategoryId.blurry,
  CleanupCategoryId.screenshots,
  CleanupCategoryId.largeVideos,
  CleanupCategoryId.bursts,
];
const cleanupVideoSizes = [250, 500, 1000, 2000];

/// Favorites and photos in albums are shown, but not ticked: someone chose them once.
bool cleanupTicked(CleanupItem item) => !item.favorite && !item.inAlbum;

String cleanupTitle(CleanupCategoryId id) => switch (id) {
  CleanupCategoryId.blurry => l.cleanupScreenBlurry,
  CleanupCategoryId.screenshots => l.cleanupScreenScreenshots,
  CleanupCategoryId.largeVideos => l.cleanupScreenLargeVideos,
  _ => l.cleanupScreenBursts,
};

String cleanupHint(CleanupCategoryId id) => switch (id) {
  CleanupCategoryId.blurry => l.cleanupScreenBlurryHint,
  CleanupCategoryId.screenshots => l.cleanupScreenScreenshotsHint,
  CleanupCategoryId.largeVideos => l.cleanupScreenLargeVideosHint,
  _ => l.cleanupScreenBurstsHint,
};

/// A video's length as m:ss, or h:mm:ss when it is long.
String videoLength(int ms) {
  final total = (ms / 1000).round();
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = (total % 60).toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:${minutes.toString().padLeft(2, '0')}:$seconds'
      : '$minutes:$seconds';
}

/// Blurry photos, screenshots, large videos and the other shots of bursts, to move to the trash.
class CleanupScreen extends ConsumerStatefulWidget {
  const CleanupScreen({super.key});

  @override
  ConsumerState<CleanupScreen> createState() => _CleanupScreenState();
}

class _CleanupScreenState extends ConsumerState<CleanupScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  CleanupSummary? _summary;
  CleanupCategoryId _category = CleanupCategoryId.blurry;
  int _blur = 3;
  int _videoMb = 500;
  List<CleanupItem>? _items;
  int? _next;
  bool _failed = false;
  bool _working = false;
  final Map<String, bool> _choices = {};

  bool _isTicked(CleanupItem item) => _choices[item.id] ?? cleanupTicked(item);

  List<CleanupItem> get _chosen =>
      (_items ?? const []).where(_isTicked).toList();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _items = null;
      _choices.clear();
    });
    _loadSummary();
    _loadItems();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await _session.api.getCleanup(
        blur: _blur,
        videoMb: _videoMb,
      );
      if (mounted) setState(() => _summary = summary);
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _loadItems({bool more = false}) async {
    try {
      final page = await _session.api.listCleanup(
        _category,
        blur: _blur,
        videoMb: _videoMb,
        offset: more ? _next : 0,
      );
      if (!mounted || page == null) return;
      setState(() {
        _items = more ? [...?_items, ...page.items] : page.items;
        _next = page.nextOffset;
        _failed = false;
      });
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _tell(String message) =>
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(message)));

  Future<void> _trash() async {
    final chosen = _chosen;
    final bytes = chosen.fold<int>(0, (sum, item) => sum + item.sizeBytes);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.cleanupScreenMoveToTrashQuestion),
        content: Text(
          l.cleanupScreenTrashBody('${chosen.length}', formatBytes(bytes)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cleanupScreenCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l.cleanupScreenMove,
              style: TextStyle(color: Palette.err),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _working = true);
    try {
      final ids = [for (final item in chosen) item.id];
      for (var at = 0; at < ids.length; at += 1000) {
        await _session.api.bulkAssets(
          BulkRequest(
            ids: ids.sublist(at, (at + 1000).clamp(0, ids.length)),
            action: BulkRequestActionEnum.delete,
          ),
        );
      }
      _tell(l.cleanupScreenMovedToTrash);
      _reload();
    } on ApiException {
      _tell(l.cleanupScreenActionFailed);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _keep() async {
    setState(() => _working = true);
    try {
      await _session.api.keepFromCleanup(
        AssetIds(ids: [for (final item in _chosen) item.id]),
      );
      _tell(l.cleanupScreenKept);
      _reload();
    } on ApiException {
      _tell(l.cleanupScreenActionFailed);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _open(int index) {
    final items = _items;
    if (items == null) return;
    final store = TimelineStore.fixed(_session, [
      for (final item in items)
        TimelineItem(
          id: item.id,
          kind: item.kind == CleanupItemKindEnum.video
              ? TimelineItemKindEnum.video
              : TimelineItemKindEnum.photo,
          ratio: item.ratio,
          isFavorite: item.favorite,
          localAt: item.localAt,
        ),
    ]);
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ViewerScreen(initialIndex: index, store: store, readOnly: true),
          ),
        )
        .then((_) => store.dispose());
  }

  Widget _categoryCard(CleanupCategoryId id) {
    final counted = _summary?.categories
        .where((category) => category.id == id)
        .firstOrNull;
    final on = id == _category;
    return InkWell(
      key: ValueKey('cleanup-${id.value}'),
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        _category = id;
        _reload();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: on ? Palette.gold : Palette.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cleanupTitle(id),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (counted == null)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: LinearProgressIndicator(),
              )
            else ...[
              Text(
                localCount(counted.count),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                formatBytes(counted.bytes),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _controls() => switch (_category) {
    CleanupCategoryId.blurry => Row(
      children: [
        Text(l.cleanupScreenStricter),
        Expanded(
          child: Slider(
            value: _blur.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$_blur',
            onChanged: (value) => setState(() => _blur = value.round()),
            onChangeEnd: (_) => _reload(),
          ),
        ),
        Text(l.cleanupScreenMore),
      ],
    ),
    CleanupCategoryId.largeVideos => Row(
      children: [
        Text(l.cleanupScreenLargerThan),
        DropdownButton<int>(
          value: _videoMb,
          items: [
            for (final size in cleanupVideoSizes)
              DropdownMenuItem(
                value: size,
                child: Text(size >= 1000 ? '${size ~/ 1000} GB' : '$size MB'),
              ),
          ],
          onChanged: (value) {
            _videoMb = value ?? _videoMb;
            _reload();
          },
        ),
      ],
    ),
    _ => const SizedBox.shrink(),
  };

  Widget _tile(CleanupItem item, int index) {
    final ticked = _isTicked(item);
    return GestureDetector(
      key: ValueKey('cleanup-item-${item.originalName}'),
      onTap: () => setState(() => _choices[item.id] = !ticked),
      onLongPress: () => _open(index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AssetPicture(
              session: _session,
              id: item.id,
              fit: BoxFit.cover,
              memCacheWidth: 300,
              error: const Icon(Icons.broken_image_outlined),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                width: 2,
                color: ticked ? Palette.err : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Positioned(
            top: 6,
            left: 6,
            child: Icon(
              ticked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: ticked ? Palette.err : Colors.white,
              semanticLabel: ticked
                  ? l.cleanupScreenToTheTrash
                  : l.cleanupScreenStays,
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: Text(
              [
                formatBytes(item.sizeBytes),
                if (item.durationMs != null) videoLength(item.durationMs!),
                if (item.favorite) l.cleanupScreenFavorite,
                if (item.inAlbum) l.cleanupScreenInAnAlbum,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                shadows: [Shadow(blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final summary = _summary;
    final chosen = _chosen;
    final bytes = chosen.fold<int>(0, (sum, item) => sum + item.sizeBytes);
    return Scaffold(
      appBar: AppBar(title: Text(l.cleanupScreenTitle)),
      bottomNavigationBar: items == null || items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: chosen.isEmpty || _working ? null : _keep,
                      child: Text(l.cleanupScreenKeep),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: chosen.isEmpty || _working ? null : _trash,
                        style: FilledButton.styleFrom(
                          backgroundColor: Palette.err,
                        ),
                        child: Text(
                          l.cleanupScreenToTheTrashButton(
                            '${chosen.length}',
                            formatBytes(bytes),
                          ),
                          // The count and the size are the point: on a long language it takes two lines.
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_failed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l.cleanupScreenNotLoaded),
            ),
          if (summary != null && summary.pending > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l.cleanupScreenStillAnalysed('${summary.pending}')),
            ),
          // A fixed height, not a ratio: on a narrow phone a ratio leaves too little room for the
          // count, and the font can be enlarged.
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent: 92 * MediaQuery.textScalerOf(context).scale(1),
            ),
            children: [for (final id in cleanupCategories) _categoryCard(id)],
          ),
          const SizedBox(height: 12),
          Text(cleanupHint(_category)),
          _controls(),
          const SizedBox(height: 8),
          if (items == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            EmptyMessage(
              icon: Icons.check_circle_outline,
              text: l.cleanupScreenNothing,
            )
          else ...[
            Text(l.cleanupScreenTapToTick),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 140,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: items.length,
              itemBuilder: (_, index) => _tile(items[index], index),
            ),
            if (_next != null)
              Center(
                child: TextButton(
                  onPressed: () => _loadItems(more: true),
                  child: Text(l.cleanupScreenShowMore),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
