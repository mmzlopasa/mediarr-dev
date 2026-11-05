import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../services/trash.dart';
import '../services/timeline.dart';
import '../services/uploads.dart';
import '../theme.dart';
import '../services/settings.dart';
import '../timeline/layout.dart';
import 'app_header.dart';
import 'stories_strip.dart';
import 'album_sheets.dart';
import 'asset_picture.dart';
import 'organize_screens.dart';
import 'viewer_screen.dart';
import 'waiting_strip.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  static const _pollEvery = Duration(seconds: 5);
  final _selected = <String>{};
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _store.refresh());
    // New photos appear while uploads and server processing are going on.
    _poll = Timer.periodic(_pollEvery, (_) => _store.refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  TimelineStore get _store => ref.read(timelineProvider);

  void _toggle(String id) {
    final settings = ref.read(settingsProvider);
    if (settings.readOnly) return;
    if (settings.haptics) HapticFeedback.selectionClick();
    _toggleNow(id);
  }

  void _toggleNow(String id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  Future<void> _act(BulkRequestActionEnum action) async {
    final ids = _selected.toList();
    try {
      await _store.act(ids, action);
      if (mounted) setState(_selected.clear);
    } on ApiException catch (cause) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The action failed. ${cause.message ?? ''}')),
        );
      }
    }
  }

  Future<void> _more(String choice, Session session) async {
    switch (choice) {
      case 'archive':
        await _act(BulkRequestActionEnum.archive);
      case 'tag':
        final done = await showAddTag(context, session, _selected.toList());
        if (done && mounted) setState(_selected.clear);
      case 'vault':
        final status = await session.api.getVaultStatus();
        if (!mounted) return;
        if (status?.hasPin != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Set a vault PIN first: Account > Vault.'),
            ),
          );
          return;
        }
        await _act(BulkRequestActionEnum.vault);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_selected.length}?'),
        content: TrashSentence(
          (days) => days == null
              ? 'They move to the trash, where they can be restored.'
              : 'They move to the trash, where they stay for $days days and can be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Palette.err)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _act(BulkRequestActionEnum.delete);
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(timelineProvider);
    final session = ref.watch(sessionProvider).value;
    ref.listen(uploadsProvider, (previous, next) {
      final before = previous?.where((task) => task.finished).length ?? 0;
      if (next.where((task) => task.finished).length > before) store.refresh();
    });
    final text = Theme.of(context).textTheme;
    final months = store.months;

    if (session == null) return const SizedBox.shrink();

    Widget body;
    if (months == null) {
      body = store.failed
          ? EmptyMessage(
              icon: Icons.cloud_off,
              text: 'Your photos could not be loaded. Check the connection.',
              action: GoldButton(label: 'Try again', onPressed: store.refresh),
            )
          : Center(child: CircularProgressIndicator(color: Palette.gold));
    } else if (months.isEmpty) {
      body = const EmptyMessage(
        icon: Icons.photo_outlined,
        text: 'No photos yet. Add your first ones in the Upload tab.',
      );
    } else {
      body = TimelineGrid(
        header: StoriesStrip(session: session),
        store: store,
        session: session,
        selected: _selected,
        onToggle: _toggle,
        onOpen: (index) => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ViewerScreen(initialIndex: index),
          ),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                if (_selected.isEmpty) ...[
                  const Expanded(child: AppHeader(title: 'Media')),
                ] else ...[
                  IconButton(
                    tooltip: 'Clear selection',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(_selected.clear),
                  ),
                  Text('${_selected.length}', style: text.titleLarge),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Add to album',
                    icon: const Icon(Icons.photo_album_outlined),
                    onPressed: () async {
                      final added = await showAddToAlbum(
                        context,
                        session,
                        _selected.toList(),
                      );
                      if (added && mounted) setState(_selected.clear);
                    },
                  ),
                  IconButton(
                    tooltip: 'Add to favorites',
                    icon: const Icon(Icons.star_border),
                    onPressed: () => _act(BulkRequestActionEnum.favorite),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _confirmDelete,
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'More',
                    onSelected: (choice) => _more(choice, session),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'archive', child: Text('Archive')),
                      PopupMenuItem(value: 'tag', child: Text('Add a tag')),
                      PopupMenuItem(
                        value: 'vault',
                        child: Text('Move to the vault'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const WaitingStrip(),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// The months and photos of any store: the library, an album or a partner's library.
class TimelineGrid extends StatelessWidget {
  const TimelineGrid({
    super.key,
    required this.store,
    required this.session,
    required this.selected,
    required this.onToggle,
    required this.onOpen,
    this.header,
  });

  final Widget? header;
  final TimelineStore store;
  final Session session;
  final Set<String> selected;
  final void Function(String id) onToggle;
  final void Function(int index) onOpen;

  @override
  Widget build(BuildContext context) {
    final months = store.months ?? const <TimelineMonth>[];
    return LayoutBuilder(
      builder: (context, constraints) {
        const side = 12.0;
        final width = constraints.maxWidth - side * 2;
        return RefreshIndicator(
          color: Palette.gold,
          onRefresh: () => store.refresh(reloadLoaded: true),
          child: CustomScrollView(
            // Keeps nearby months loaded, and the scroll steady when returning.
            key: PageStorageKey(store),
            scrollCacheExtent: const ScrollCacheExtent.pixels(900),
            slivers: [
              if (header != null) SliverToBoxAdapter(child: header),
              for (final month in months)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: side),
                  sliver: _MonthSliver(
                    store: store,
                    month: month,
                    width: width,
                    session: session,
                    selected: selected,
                    onToggle: onToggle,
                    onOpen: onOpen,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          ),
        );
      },
    );
  }
}

class _MonthSliver extends ConsumerWidget {
  const _MonthSliver({
    required this.store,
    required this.month,
    required this.width,
    required this.session,
    required this.selected,
    required this.onToggle,
    required this.onOpen,
  });

  final TimelineStore store;
  final TimelineMonth month;
  final double width;
  final Session session;
  final Set<String> selected;
  final void Function(String id) onToggle;
  final void Function(int index) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final items = month.items;
    if (items == null) {
      // Built only when this month comes near the screen, which is when it loads.
      return SliverList.builder(
        itemCount: 1,
        itemBuilder: (context, _) {
          if (!month.loading && !month.failed) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => store.load(month),
            );
          }
          return SizedBox(
            height: estimateMonthHeight(month.count, width, settings.perRow),
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 22),
                child: month.failed
                    ? TextButton(
                        onPressed: () => store.load(month),
                        child: Text(
                          '${formatMonth(month.month)} could not be loaded. Try again.',
                        ),
                      )
                    : Text(
                        formatMonth(month.month),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
              ),
            ),
          );
        },
      );
    }

    final rows = layoutMonth(
      items,
      start: store.startOf(month),
      width: width,
      monthLabel: formatMonth(month.month),
      dayLabel: formatDay,
      perRow: settings.perRow,
      byDay: settings.groupByDay,
    );
    final text = Theme.of(context).textTheme;
    return SliverList.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return switch (row) {
          HeaderRow(:final label, :final isMonth) => SizedBox(
            height: row.height,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  label,
                  style: isMonth ? text.titleLarge : text.bodyMedium,
                ),
              ),
            ),
          ),
          TilesRow(:final tiles) => Padding(
            padding: const EdgeInsets.only(bottom: gap),
            child: SizedBox(
              height: row.height,
              child: Row(
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    _TileView(
                      tile: tiles[i],
                      height: row.height,
                      session: session,
                      isSelected: selected.contains(tiles[i].item.id),
                      selecting: selected.isNotEmpty,
                      onToggle: onToggle,
                      onOpen: onOpen,
                    ),
                  ],
                ],
              ),
            ),
          ),
        };
      },
    );
  }
}

class _TileView extends StatelessWidget {
  const _TileView({
    required this.tile,
    required this.height,
    required this.session,
    required this.isSelected,
    required this.selecting,
    required this.onToggle,
    required this.onOpen,
  });

  final Tile tile;
  final double height;
  final Session session;
  final bool isSelected;
  final bool selecting;
  final void Function(String id) onToggle;
  final void Function(int index) onOpen;

  @override
  Widget build(BuildContext context) {
    final item = tile.item;
    final pixels = (tile.width * MediaQuery.devicePixelRatioOf(context))
        .round();
    return GestureDetector(
      onTap: () => selecting ? onToggle(item.id) : onOpen(tile.index),
      onLongPress: () {
        HapticFeedback.selectionClick();
        onToggle(item.id);
      },
      child: SizedBox(
        width: tile.width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Palette.bg3),
              AnimatedPadding(
                duration: const Duration(milliseconds: 120),
                padding: EdgeInsets.all(isSelected ? 8 : 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isSelected ? 5 : 0),
                  child: AssetPicture(
                    session: session,
                    id: item.id,
                    memCacheWidth: pixels,
                    fit: BoxFit.cover,
                    error: Icon(
                      Icons.broken_image_outlined,
                      color: Palette.dim,
                    ),
                  ),
                ),
              ),
              if (item.kind == TimelineItemKindEnum.video)
                const Positioned(
                  right: 5,
                  bottom: 5,
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              if (item.stackSize != null)
                Positioned(
                  right: 5,
                  bottom: 5,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.stackSize}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.burst_mode,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              if (item.isLive == true)
                const Positioned(
                  right: 5,
                  top: 5,
                  child: Icon(
                    Icons.motion_photos_on,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              if (item.isFavorite)
                Positioned(
                  left: 5,
                  bottom: 5,
                  child: Icon(Icons.star, size: 18, color: Palette.gold),
                ),
              if (isSelected)
                Positioned(
                  left: 4,
                  top: 4,
                  child: Icon(
                    Icons.check_circle,
                    size: 22,
                    color: Palette.gold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
