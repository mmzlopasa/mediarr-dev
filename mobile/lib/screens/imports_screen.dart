import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../theme.dart';

/// Where a Google Takeout or iCloud export came from, by name.
String importSourceName(UserImport entry) => switch (entry.source_.value) {
  'takeout' => 'Google Takeout',
  'icloud' => 'iCloud',
  _ => 'Immich',
};

/// The state of an import in words.
String importStatus(UserImport entry) => switch (entry.status) {
  UserImportStatusEnum.uploading => 'Waiting for files',
  UserImportStatusEnum.running => 'Running',
  UserImportStatusEnum.done => 'Done',
  UserImportStatusEnum.failed => 'Failed',
  _ => 'Stopped',
};

/// What an import has done so far, in one line.
String describeImport(UserImport entry) {
  if (entry.status == UserImportStatusEnum.uploading) {
    final count = entry.parts.length;
    return '$count ZIP ${count == 1 ? 'file' : 'files'} uploaded';
  }
  final line =
      'added ${entry.added} · already here or deleted ${entry.skipped} · failed ${entry.failed}';
  final done = entry.added + entry.skipped + entry.failed;
  return entry.total > 0 ? '$line · $done / ${entry.total}' : line;
}

/// How far an import has come, from 0 to 1, once it knows how many files there are.
double? importProgress(UserImport entry) {
  if (entry.total <= 0) return null;
  final done = entry.added + entry.skipped + entry.failed;
  return (done / entry.total).clamp(0, 1).toDouble();
}

/// The imports of the signed-in person. The ZIP files of an export are large and live on a
/// computer, so they are uploaded on the web; here an import is followed, stopped, continued and
/// its report read.
class ImportsScreen extends ConsumerStatefulWidget {
  const ImportsScreen({super.key});

  @override
  ConsumerState<ImportsScreen> createState() => _ImportsScreenState();
}

class _ImportsScreenState extends ConsumerState<ImportsScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  List<UserImport>? _imports;
  bool _failed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final imports = await _session.api.listMyImports() ?? const [];
      if (!mounted) return;
      setState(() {
        _imports = imports;
        _failed = false;
      });
      // Progress is asked for only while something runs.
      _timer?.cancel();
      if (imports.any(
        (entry) => entry.status == UserImportStatusEnum.running,
      )) {
        _timer = Timer(const Duration(seconds: 3), _load);
      }
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _tell(String message) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _act(Future<void> Function() work, String failed) async {
    try {
      await work();
    } on ApiException catch (cause) {
      _tell('$failed ${cause.message ?? ''}'.trim());
    }
    await _load();
  }

  Future<void> _report(UserImport entry) async {
    ImportDetail? detail;
    try {
      detail = await _session.api.getImport(entry.id);
    } on ApiException {
      _tell('The report could not be loaded.');
      return;
    }
    if (!mounted || detail == null) return;
    final problems = detail.problems;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: problems.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No files failed.'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final problem in problems)
                    ListTile(
                      title: Text(problem.name, style: monoData(13)),
                      subtitle: Text(problem.reason),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _entry(UserImport entry) {
    final progress = importProgress(entry);
    final running = entry.status == UserImportStatusEnum.running;
    final canContinue =
        entry.fromZip &&
        entry.parts.isNotEmpty &&
        (entry.status == UserImportStatusEnum.cancelled ||
            entry.status == UserImportStatusEnum.failed ||
            entry.status == UserImportStatusEnum.uploading);
    final created = entry.createdAt.toLocal().toString().substring(0, 16);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${importSourceName(entry)} · $created',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${importStatus(entry)} · ${describeImport(entry)}',
            style: TextStyle(color: Palette.dim),
          ),
          if (running && progress != null) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              color: Palette.gold,
              backgroundColor: Palette.bg3,
            ),
          ],
          Wrap(
            spacing: 4,
            children: [
              if (running)
                TextButton(
                  onPressed: () => _act(
                    () => _session.api.stopImport(entry.id),
                    'The import could not be stopped.',
                  ),
                  child: const Text('Stop'),
                ),
              if (canContinue)
                TextButton(
                  onPressed: () => _act(
                    () => _session.api.startImport(entry.id),
                    'The import could not go on.',
                  ),
                  child: Text(
                    entry.status == UserImportStatusEnum.uploading
                        ? 'Bring in'
                        : 'Continue',
                  ),
                ),
              if (entry.failed > 0)
                TextButton(
                  onPressed: () => _report(entry),
                  child: const Text('Report'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imports = _imports;
    final web = '${_session.serverUrl}/account/import';
    return Scaffold(
      appBar: AppBar(title: const Text('Import')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: imports == null
            ? _failed
                  ? const EmptyMessage(
                      icon: Icons.cloud_off,
                      text: 'The imports could not be loaded.',
                    )
                  : Center(
                      child: CircularProgressIndicator(color: Palette.gold),
                    )
            : ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(
                      'To bring in photos from Google Photos or iCloud, upload the ZIP files of the export on a computer, at $web.',
                      style: TextStyle(color: Palette.dim),
                    ),
                  ),
                  if (imports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('You have not imported anything yet.'),
                    )
                  else
                    for (final entry in imports) ...[
                      _entry(entry),
                      Divider(height: 1, color: Palette.line),
                    ],
                ],
              ),
      ),
    );
  }
}
