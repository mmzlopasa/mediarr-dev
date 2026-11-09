import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../theme.dart';
import '../timeline/layout.dart';
import 'asset_picture.dart';
import '../l10n/l10n.dart';

/// What goes to the trash: whatever is not kept. Keeping none is not offered, so a group can never
/// disappear as a whole by accident.
List<String> shotsToTrash(DuplicateGroup group, Map<String, bool> choices) {
  final out = [
    for (final item in group.items)
      if (!(choices[item.id] ?? item.id == group.keepId)) item.id,
  ];
  return out.length == group.items.length ? const [] : out;
}

/// One photo stays and takes over what the others had; the unticked go to the trash. A second
/// ticked photo is left as it is.
DuplicateChoice? duplicateChoice(
  DuplicateGroup group,
  Map<String, bool> choices,
) {
  bool keeps(DuplicateItem item) => choices[item.id] ?? item.id == group.keepId;
  final kept = group.items.where(keeps).toList();
  final trash = [
    for (final item in group.items)
      if (!keeps(item)) item.id,
  ];
  if (kept.isEmpty || trash.isEmpty) return null;
  final keepId = kept.any((item) => item.id == group.keepId)
      ? group.keepId
      : kept.first.id;
  return DuplicateChoice(keepId: keepId, trashIds: trash);
}

/// Short facts about one copy, for telling the copies apart.
List<String> duplicateNotes(DuplicateItem item) => [
  if (item.favorite) l.duplicatesScreenFavorite,
  if (item.original) l.duplicatesScreenOriginal,
  if (item.resaved) l.duplicatesScreenSavedAgain,
  if (item.hasLocation) l.duplicatesScreenHasLocation,
  if (item.hasCaption) l.duplicatesScreenHasDescription,
  if (!item.hasDate) l.duplicatesScreenNoDate,
];

/// Why the proposed one is kept: the first way it is better than the others.
String duplicateReason(DuplicateGroup group) {
  final keep = group.items.where((item) => item.id == group.keepId).firstOrNull;
  if (keep == null) return '';
  final others = group.items.where((item) => item != keep);
  int pixels(DuplicateItem item) => (item.width ?? 0) * (item.height ?? 0);
  if (keep.favorite && others.any((item) => !item.favorite)) {
    return l.duplicatesScreenReasonFavorite;
  }
  if (keep.original && others.any((item) => !item.original)) {
    return l.duplicatesScreenReasonCameraOriginal;
  }
  if (!keep.resaved && others.any((item) => item.resaved)) {
    return l.duplicatesScreenReasonOthersSaved;
  }
  if (others.every((item) => pixels(item) < pixels(keep))) {
    return l.duplicatesScreenReasonHighestResolution;
  }
  if (others.every((item) => item.sizeBytes < keep.sizeBytes)) {
    return l.duplicatesScreenReasonLargestFile;
  }
  if (others.every(
    (item) => item.sizeBytes == keep.sizeBytes && pixels(item) == pixels(keep),
  )) {
    return l.duplicatesScreenReasonEqual;
  }
  return l.duplicatesScreenReasonSharpest;
}

class DuplicatesScreen extends ConsumerStatefulWidget {
  const DuplicatesScreen({super.key});

  @override
  ConsumerState<DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends ConsumerState<DuplicatesScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  Duplicates? _data;
  bool _failed = false;
  final Map<String, bool> _choices = {};
  Timer? _poll;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await _session.api.listDuplicates();
      if (mounted) {
        setState(() {
          _data = data;
          _failed = false;
        });
        // While all are being resolved, the progress is asked for often.
        _poll?.cancel();
        if (data?.resolving != null) {
          _poll = Timer(const Duration(milliseconds: 1500), _load);
        }
      }
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _tell(String message) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm(String title, String sentence, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(sentence),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.duplicatesScreenCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action, style: TextStyle(color: Palette.err)),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _resolve(DuplicateChoice choice) async {
    final confirmed = await _confirm(
      l.duplicatesScreenResolveThisGroup,
      l.duplicatesScreenKeptTakesOver,
      l.duplicatesScreenResolve,
    );
    if (!confirmed) return;
    setState(() => _working = true);
    try {
      await _session.api.resolveDuplicates(DuplicateResolve(groups: [choice]));
      _tell(l.duplicatesScreenResolved);
      await _load();
    } on ApiException {
      _tell(l.duplicatesScreenActionFailed);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _resolveAll({required bool exactOnly}) async {
    try {
      final preview = await _session.api.resolveDuplicates(
        DuplicateResolve(all: true, exactOnly: exactOnly, dryRun: true),
      );
      if (preview == null || !mounted) return;
      final confirmed = await _confirm(
        exactOnly
            ? l.duplicatesScreenResolveEveryIdentical
            : l.duplicatesScreenResolveAllDuplicates,
        l.duplicatesScreenResolveAllBody(
          '${preview.groups}',
          '${preview.trashed}',
          formatBytes(preview.freedBytes),
        ),
        l.duplicatesScreenResolveAll,
      );
      if (!confirmed) return;
      await _session.api.resolveDuplicates(
        DuplicateResolve(all: true, exactOnly: exactOnly),
      );
      await _load();
    } on ApiException {
      _tell(l.duplicatesScreenActionFailed);
    }
  }

  Future<void> _dismiss(DuplicateGroup group) async {
    try {
      await _session.api.dismissDuplicates(
        AssetIds(ids: [for (final item in group.items) item.id]),
      );
      await _load();
    } on ApiException {
      _tell(l.duplicatesScreenActionFailed);
    }
  }

  Widget _group(DuplicateGroup group) {
    final trash = shotsToTrash(group, _choices);
    final choice = duplicateChoice(group, _choices);
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(
                    group.exact
                        ? l.duplicatesScreenSamePicture
                        : l.duplicatesScreenAlike,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  l.duplicatesScreenProposedToKeep(
                    duplicateReason(group),
                    formatBytes(group.freedBytes),
                  ),
                  style: text.bodySmall,
                ),
              ],
            ),
            for (final item in group.items)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _choices[item.id] ?? item.id == group.keepId,
                onChanged: (keep) =>
                    setState(() => _choices[item.id] = keep ?? false),
                secondary: SizedBox.square(
                  dimension: 56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AssetPicture(
                      session: _session,
                      id: item.id,
                      fit: BoxFit.cover,
                      memCacheWidth: 168,
                      error: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
                title: Text(
                  item.originalName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    if (item.width != null && item.height != null)
                      '${item.width} × ${item.height}',
                    formatBytes(item.sizeBytes),
                    ...duplicateNotes(item),
                  ].join(' · '),
                ),
              ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _dismiss(group),
                  child: Text(l.duplicatesScreenNotDuplicates),
                ),
                TextButton(
                  onPressed: choice == null || _working
                      ? null
                      : () => _resolve(choice),
                  child: Text(
                    l.duplicatesScreenResolveToTrash('${trash.length}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(title: Text(l.duplicatesScreenTitle)),
      body: data == null
          ? _failed
                ? EmptyMessage(
                    icon: Icons.cloud_off,
                    text: l.duplicatesScreenLoadFailed,
                  )
                : Center(child: CircularProgressIndicator(color: Palette.gold))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      [
                        if (data.pending > 0)
                          l.duplicatesScreenPending('${data.pending}'),
                        if (data.groups.isEmpty)
                          l.duplicatesScreenNoneFound
                        else
                          l.duplicatesScreenTickWhatToKeep,
                        if (data.total > data.groups.length)
                          l.duplicatesScreenShowing(
                            '${data.groups.length}',
                            '${data.total}',
                          ),
                      ].join(' '),
                    ),
                  ),
                  if (data.resolving case final progress?)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l.duplicatesScreenResolving(
                              '${progress.done}',
                              '${progress.total}',
                            ),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: progress.total == 0
                                ? null
                                : progress.done / progress.total,
                          ),
                        ],
                      ),
                    )
                  else if (data.groups.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        children: [
                          if ((data.exactTotal ?? 0) > 0)
                            OutlinedButton(
                              onPressed: () => _resolveAll(exactOnly: true),
                              child: Text(
                                l.duplicatesScreenResolveIdentical(
                                  '${data.exactTotal}',
                                ),
                              ),
                            ),
                          FilledButton(
                            onPressed: () => _resolveAll(exactOnly: false),
                            style: FilledButton.styleFrom(
                              backgroundColor: Palette.buttonGold,
                              foregroundColor: Palette.onGold,
                            ),
                            child: Text(
                              l.duplicatesScreenResolveAllAsProposed(
                                '${data.total}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  for (final group in data.groups) _group(group),
                ],
              ),
            ),
    );
  }
}

/// Opens the shots of a stack, to look through them, choose the main one or split the stack.
Future<void> showStackSheet(
  BuildContext context,
  Session session,
  String id,
  Future<void> Function() onChanged,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _StackSheet(session: session, id: id, onChanged: onChanged),
);

class _StackSheet extends StatefulWidget {
  const _StackSheet({
    required this.session,
    required this.id,
    required this.onChanged,
  });

  final Session session;
  final String id;
  final Future<void> Function() onChanged;

  @override
  State<_StackSheet> createState() => _StackSheetState();
}

class _StackSheetState extends State<_StackSheet> {
  List<String>? _shots;
  late String _shown = widget.id;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    widget.session
        .detail(widget.id)
        .then((detail) {
          if (mounted) setState(() => _shots = detail?.stack ?? const []);
        })
        .catchError((Object _) {
          if (mounted) setState(() => _failed = true);
        }, test: (error) => error is ApiException);
  }

  Future<void> _change(Future<void> Function() action) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      await widget.onChanged();
      navigator.pop();
    } on ApiException {
      messenger.showSnackBar(
        SnackBar(content: Text(l.duplicatesScreenActionFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shots = _shots;
    if (shots == null) {
      return SizedBox(
        height: 200,
        child: _failed
            ? EmptyMessage(
                icon: Icons.cloud_off,
                text: l.duplicatesScreenStackLoadFailed,
              )
            : Center(child: CircularProgressIndicator(color: Palette.gold)),
      );
    }
    final api = widget.session.api;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: AssetPicture(
              key: ValueKey(_shown),
              session: widget.session,
              id: _shown,
              large: true,
              fit: BoxFit.contain,
              error: const Icon(Icons.broken_image_outlined),
            ),
          ),
          SizedBox(
            height: 76,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              children: [
                for (final shot in shots)
                  GestureDetector(
                    onTap: () => setState(() => _shown = shot),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2,
                          color: shot == _shown
                              ? Palette.gold
                              : Colors.transparent,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AssetPicture(
                        session: widget.session,
                        id: shot,
                        fit: BoxFit.cover,
                        memCacheWidth: 180,
                        error: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => _change(() => api.dissolveStack(_shown)),
                child: Text(l.duplicatesScreenSplitStack),
              ),
              if (shots.isNotEmpty && shots.first != _shown)
                TextButton(
                  onPressed: () => _change(() => api.setStackMain(_shown)),
                  child: Text(l.duplicatesScreenMakeMain),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
