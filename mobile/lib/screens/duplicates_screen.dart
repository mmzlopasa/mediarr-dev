import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../theme.dart';
import '../timeline/layout.dart';
import 'asset_picture.dart';

/// What goes to the trash: whatever is not kept. Keeping none is not offered, so a group can never
/// disappear as a whole by accident.
List<String> shotsToTrash(DuplicateGroup group, Map<String, bool> choices) {
  final out = [
    for (final item in group.items)
      if (!(choices[item.id] ?? item.id == group.keepId)) item.id,
  ];
  return out.length == group.items.length ? const [] : out;
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _session.api.listDuplicates();
      if (mounted) {
        setState(() {
          _data = data;
          _failed = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _tell(String message) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _trash(List<String> ids) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to the trash?'),
        content: const Text(
          'The selected photos stay in the trash for 30 days and can be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Move', style: TextStyle(color: Palette.err)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _session.api.bulkAssets(
        BulkRequest(ids: ids, action: BulkRequestActionEnum.delete),
      );
      await _load();
    } on ApiException {
      _tell('The action failed.');
    }
  }

  Future<void> _dismiss(DuplicateGroup group) async {
    try {
      await _session.api.dismissDuplicates(
        AssetIds(ids: [for (final item in group.items) item.id]),
      );
      await _load();
    } on ApiException {
      _tell('The action failed.');
    }
  }

  Widget _group(DuplicateGroup group) {
    final trash = shotsToTrash(group, _choices);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  ].join(' · '),
                ),
              ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _dismiss(group),
                  child: const Text('Not duplicates'),
                ),
                TextButton(
                  onPressed: trash.isEmpty ? null : () => _trash(trash),
                  child: Text('Move to the trash (${trash.length})'),
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
      appBar: AppBar(title: const Text('Duplicates')),
      body: data == null
          ? _failed
                ? const EmptyMessage(
                    icon: Icons.cloud_off,
                    text: 'Duplicates could not be loaded.',
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
                          'Photos still being compared: ${data.pending}.',
                        if (data.groups.isEmpty)
                          'No similar photos were found.'
                        else
                          'Tick what to keep. These are only proposals, and nothing is removed without your confirmation.',
                        if (data.total > data.groups.length)
                          'Showing ${data.groups.length} of ${data.total}.',
                      ].join(' '),
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
        const SnackBar(content: Text('The action failed.')),
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
            ? const EmptyMessage(
                icon: Icons.cloud_off,
                text: 'This stack could not be loaded.',
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
                child: const Text('Split the stack'),
              ),
              if (shots.isNotEmpty && shots.first != _shown)
                TextButton(
                  onPressed: () => _change(() => api.setStackMain(_shown)),
                  child: const Text('Make it the main shot'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
