import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mediarr_api/api.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../l10n/l10n.dart';
import '../services/session.dart';
import '../services/sharing.dart';
import '../theme.dart';
import 'admin/admin_common.dart';

/// The state of an export in words.
String exportStatus(LibraryExport entry) => switch (entry.status) {
  LibraryExportStatusEnum.running => l.exportsScreenRunning,
  LibraryExportStatusEnum.done => l.exportsScreenReady,
  LibraryExportStatusEnum.failed => l.exportsScreenFailed,
  LibraryExportStatusEnum.cancelled => l.exportsScreenCancelled,
  _ => l.exportsScreenRemoved,
};

/// How far an export has come, in one line.
String describeExport(LibraryExport entry) => l.exportsScreenProgress(
  entry.doneFiles,
  entry.totalFiles,
  adminBytes(entry.doneBytes),
  adminBytes(entry.totalBytes),
);

/// How far an export has come, from 0 to 1, by the bytes it has packed.
double? exportProgress(LibraryExport entry) {
  if (entry.status == LibraryExportStatusEnum.done) return 1;
  if (entry.totalBytes > 0) {
    return (entry.doneBytes / entry.totalBytes).clamp(0, 1).toDouble();
  }
  if (entry.totalFiles > 0) {
    return (entry.doneFiles / entry.totalFiles).clamp(0, 1).toDouble();
  }
  return null;
}

/// The name a part is saved under, as the server names it.
String exportPartName(LibraryExport entry, int number) {
  final day = entry.createdAt.toUtc().toIso8601String().substring(0, 10);
  return 'mediarr-export-$day-part-${number.toString().padLeft(3, '0')}.zip';
}

/// What to ask for when part of a file is already on the phone, to go on from there.
Map<String, String> resumeHeaders(int have) =>
    have > 0 ? {'Range': 'bytes=$have-'} : const {};

/// Downloads one part into the app's documents, going on from where a broken download stopped.
/// [onProgress] gets the share done, from 0 to 1.
Future<File> downloadExportPart(
  Session session,
  LibraryExport entry,
  LibraryExportPart part, {
  void Function(double done)? onProgress,
}) async {
  final dir = Directory(
    p.join((await getApplicationDocumentsDirectory()).path, 'exports'),
  );
  dir.createSync(recursive: true);
  final file = File(p.join(dir.path, exportPartName(entry, part.number)));
  if (file.existsSync() && file.lengthSync() == part.size) return file;
  final partial = File('${file.path}.partial');
  var have = partial.existsSync() ? partial.lengthSync() : 0;
  final client = http.Client();
  try {
    final request = http.Request(
      'GET',
      Uri.parse(
        '${session.serverUrl}/api/exports/${entry.id}/parts/${part.number}',
      ),
    )..headers.addAll({...session.headers, ...resumeHeaders(have)});
    final response = await client.send(request);
    if (response.statusCode == HttpStatus.ok) {
      have = 0;
    } else if (response.statusCode != HttpStatus.partialContent) {
      await response.stream.drain<void>();
      throw HttpException('The server answered ${response.statusCode}');
    }
    final sink = partial.openWrite(
      mode: have == 0 ? FileMode.write : FileMode.append,
    );
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        have += chunk.length;
        onProgress?.call(part.size > 0 ? have / part.size : 0);
      }
    } finally {
      await sink.close();
    }
  } finally {
    client.close();
  }
  if (partial.lengthSync() != part.size) {
    throw const HttpException('the download was cut off');
  }
  return partial.renameSync(file.path);
}

/// Exports of a whole library: one's own, started and followed here, or, for an administrator,
/// everyone's.
class ExportsScreen extends ConsumerStatefulWidget {
  const ExportsScreen({super.key, this.all = false});

  /// Every library's exports, for an administrator.
  final bool all;

  @override
  ConsumerState<ExportsScreen> createState() => _ExportsScreenState();
}

class _ExportsScreenState extends ConsumerState<ExportsScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  List<LibraryExport>? _exports;
  bool _failed = false;
  bool _starting = false;
  Timer? _timer;
  final Map<String, double> _downloads = {};

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
      final exports =
          await (widget.all
              ? _session.api.listAllExports()
              : _session.api.listMyExports()) ??
          const [];
      if (!mounted) return;
      setState(() {
        _exports = exports;
        _failed = false;
      });
      // Progress is asked for only while something runs.
      _timer?.cancel();
      if (exports.any(
        (entry) => entry.status == LibraryExportStatusEnum.running,
      )) {
        _timer = Timer(const Duration(seconds: 3), _load);
      }
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _tell(String message) =>
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(message)));

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await _session.api.createExport(LibraryExportCreate());
      _tell(l.exportsScreenStarted);
    } on ApiException catch (cause) {
      _tell(exportProblem(cause));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
    await _load();
  }

  Future<void> _act(Future<void> Function() work) async {
    try {
      await work();
    } on ApiException catch (cause) {
      _tell(apiProblem(cause));
    }
    await _load();
  }

  Future<void> _download(LibraryExport entry, LibraryExportPart part) async {
    final key = '${entry.id}/${part.number}';
    if (_downloads.containsKey(key)) return;
    setState(() => _downloads[key] = 0);
    final box = context.findRenderObject() as RenderBox?;
    try {
      final file = await downloadExportPart(
        _session,
        entry,
        part,
        onProgress: (done) {
          if (mounted) setState(() => _downloads[key] = done);
        },
      );
      if (!mounted) return;
      await shareFiles(
        [file],
        origin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } on IOException {
      _tell(l.exportsScreenDownloadFailed);
    } finally {
      if (mounted) setState(() => _downloads.remove(key));
    }
  }

  Widget _entry(LibraryExport entry) {
    final running = entry.status == LibraryExportStatusEnum.running;
    final created = entry.createdAt.toLocal().toString().substring(0, 16);
    final dim = TextStyle(color: Palette.dim);
    return Padding(
      key: ValueKey('export-${entry.id}'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.all ? '${entry.userEmail} · $created' : created,
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text('${exportStatus(entry)} · ${describeExport(entry)}', style: dim),
          if (entry.startedByAdmin)
            Text(l.exportsScreenStartedBy(entry.startedBy), style: dim),
          if (entry.missing > 0)
            Text(l.exportsScreenMissing(entry.missing), style: dim),
          if (entry.status == LibraryExportStatusEnum.failed &&
              entry.lastError.isNotEmpty)
            Text(entry.lastError, style: TextStyle(color: Palette.err)),
          if (running) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: exportProgress(entry),
              color: Palette.gold,
              backgroundColor: Palette.bg3,
            ),
          ],
          if (entry.status == LibraryExportStatusEnum.done) ...[
            if (entry.expiresAt case final until?)
              Text(
                l.exportsScreenKeptUntil(
                  until.toLocal().toString().substring(0, 10),
                ),
                style: dim,
              ),
            if (!entry.canDownload)
              Text(l.exportsScreenOnlyOwner, style: dim)
            else
              for (final part in entry.parts) _part(entry, part),
          ],
          Wrap(
            spacing: 4,
            children: [
              if (running)
                TextButton(
                  onPressed: () =>
                      _act(() => _session.api.cancelExport(entry.id)),
                  child: Text(l.exportsScreenCancel),
                )
              else
                TextButton(
                  onPressed: () =>
                      _act(() => _session.api.deleteExport(entry.id)),
                  child: Text(l.exportsScreenRemove),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _part(LibraryExport entry, LibraryExportPart part) {
    final progress = _downloads['${entry.id}/${part.number}'];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.folder_zip_outlined, color: Palette.dim),
      title: Text(l.exportsScreenPart(part.number)),
      subtitle: progress == null
          ? Text(
              '${adminBytes(part.size)} · ${l.exportsScreenFiles(part.files)}',
            )
          : LinearProgressIndicator(
              value: progress,
              color: Palette.gold,
              backgroundColor: Palette.bg3,
            ),
      trailing: IconButton(
        tooltip: l.exportsScreenDownloadPart(part.number),
        icon: const Icon(Icons.download),
        onPressed: progress == null ? () => _download(entry, part) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exports = _exports;
    final running =
        exports?.any(
          (entry) => entry.status == LibraryExportStatusEnum.running,
        ) ??
        true;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.all ? l.exportsScreenAllTitle : l.exportsScreenTitle,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: exports == null
            ? _failed
                  ? EmptyMessage(
                      icon: Icons.cloud_off,
                      text: l.exportsScreenNotLoaded,
                    )
                  : Center(
                      child: CircularProgressIndicator(color: Palette.gold),
                    )
            : ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(
                      widget.all
                          ? l.exportsScreenAdminHint
                          : l.exportsScreenWhatIsIn,
                      style: TextStyle(color: Palette.dim),
                    ),
                  ),
                  if (!widget.all)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: FilledButton.icon(
                        onPressed: _starting || running ? null : _start,
                        icon: const Icon(Icons.ios_share),
                        label: Text(l.exportsScreenStart),
                      ),
                    ),
                  if (exports.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(l.exportsScreenNothingYet),
                    )
                  else
                    for (final entry in exports) ...[
                      _entry(entry),
                      Divider(height: 1, color: Palette.line),
                    ],
                ],
              ),
      ),
    );
  }
}

/// Why an export could not start, in the person's language when the reason is known.
String exportProblem(ApiException cause) => switch (cause.code) {
  507 => l.exportsScreenNoSpace,
  409 => l.exportsScreenAlreadyRunning,
  _ => apiProblem(cause),
};
