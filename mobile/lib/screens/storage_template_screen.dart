import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../theme.dart';

/// What the last run over the files already here did, or would do, in one line.
String describeStorageReport(StorageReport report) {
  if (report.running) {
    return '${report.dryRun ? 'Dry run' : 'Moving'}… ${report.checked}';
  }
  final line = report.dryRun
      ? 'Dry run: ${report.moved} of ${report.checked} would move.'
      : 'Moved ${report.moved} of ${report.checked}.';
  return report.failed > 0 ? '$line Failed: ${report.failed}.' : line;
}

/// Whether the files already here may move: only after a dry run of the template that is kept.
bool mayMoveFiles(StorageTemplate current) {
  final report = current.report;
  return current.template.isNotEmpty &&
      report != null &&
      report.dryRun &&
      !report.running &&
      report.template == current.template &&
      report.moved > 0;
}

/// How originals are laid out on the disk, inside each user's folder, as on the web.
class StorageTemplateScreen extends ConsumerStatefulWidget {
  const StorageTemplateScreen({super.key});

  @override
  ConsumerState<StorageTemplateScreen> createState() =>
      _StorageTemplateScreenState();
}

class _StorageTemplateScreenState extends ConsumerState<StorageTemplateScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  final _field = TextEditingController();
  StorageTemplate? _current;
  List<StoragePreview> _previews = const [];
  String? _previewError;
  Timer? _typing;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load(fill: true);
  }

  @override
  void dispose() {
    _typing?.cancel();
    _poll?.cancel();
    _field.dispose();
    super.dispose();
  }

  Future<void> _load({bool fill = false}) async {
    try {
      final current = await _session.api.getStorageTemplate();
      if (!mounted || current == null) return;
      setState(() => _current = current);
      if (fill) {
        _field.text = current.template;
        _preview();
      }
      if (current.report?.running == true) {
        _poll ??= Timer.periodic(
          const Duration(milliseconds: 1500),
          (_) => _load(),
        );
      } else {
        _poll?.cancel();
        _poll = null;
      }
    } on ApiException catch (cause) {
      _say(cause.message ?? 'Not loaded.');
    }
  }

  void _preview() {
    _typing?.cancel();
    _typing = Timer(const Duration(milliseconds: 300), () async {
      try {
        final found = await _session.api.previewStorageTemplate(
          StorageTemplateChange(template: _field.text.trim()),
        );
        if (mounted) {
          setState(() {
            _previews = found ?? const [];
            _previewError = null;
          });
        }
      } on ApiException catch (cause) {
        if (mounted) {
          setState(() {
            _previews = const [];
            _previewError = cause.message;
          });
        }
      }
    });
  }

  void _insert(String token) {
    final value = _field.value;
    final at = value.selection.isValid
        ? value.selection.start
        : value.text.length;
    final text = value.text.replaceRange(at, at, token);
    _field.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: at + token.length),
    );
    _preview();
    setState(() {});
  }

  Future<void> _save(String template) async {
    try {
      final current = await _session.api.setStorageTemplate(
        StorageTemplateChange(template: template),
      );
      if (!mounted || current == null) return;
      setState(() => _current = current);
      _field.text = current.template;
      _preview();
      _say('Saved.');
    } on ApiException catch (cause) {
      _say(cause.message ?? 'Not saved.');
    }
  }

  Future<void> _apply(bool dryRun) async {
    if (!dryRun) {
      final moved = _current?.report?.moved ?? 0;
      final sure = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Move $moved files?'),
          content: const Text(
            'The originals do not change, only where they are on the disk.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Move'),
            ),
          ],
        ),
      );
      if (sure != true) return;
    }
    try {
      await _session.api.applyStorageTemplate(StorageApply(dryRun: dryRun));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _load();
      _poll ??= Timer.periodic(
        const Duration(milliseconds: 1500),
        (_) => _load(),
      );
    } on ApiException catch (cause) {
      _say(cause.message ?? 'Not started.');
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final current = _current;
    final saved = current != null && current.template == _field.text.trim();
    final report = current?.report;
    return Scaffold(
      appBar: AppBar(title: const Text('Storage template')),
      body: current == null
          ? Center(child: CircularProgressIndicator(color: Palette.gold))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  'How originals are laid out on the disk, inside each user’s folder. It applies '
                  'to new files; the ones already here move only when you ask, after a dry run. '
                  'An external library never moves.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _field,
                  maxLength: 200,
                  style: const TextStyle(fontFamily: 'JetBrains Mono'),
                  decoration: InputDecoration(
                    labelText: 'Template',
                    hintText: current.defaultLayout,
                    errorText: _previewError,
                    errorMaxLines: 3,
                  ),
                  onChanged: (_) {
                    _preview();
                    setState(() {});
                  },
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final token in current.tokens)
                      Tooltip(
                        message: token.means,
                        child: ActionChip(
                          label: Text(
                            token.token,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () => _insert(token.token),
                        ),
                      ),
                  ],
                ),
                if (_previews.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('Examples', style: text.titleSmall),
                  for (final example in _previews)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(example.path),
                      subtitle: Text(example.name),
                    ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (current.template.isNotEmpty)
                      TextButton(
                        onPressed: () => _save(''),
                        child: const Text('Back to the usual layout'),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: saved || _previewError != null
                          ? null
                          : () => _save(_field.text.trim()),
                      style: FilledButton.styleFrom(
                        backgroundColor: Palette.buttonGold,
                        foregroundColor: Palette.onGold,
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
                if (current.template.isNotEmpty) ...[
                  const Divider(height: 32),
                  Text('Files already here', style: text.titleMedium),
                  if (report != null &&
                      (report.running ||
                          report.template == current.template)) ...[
                    const SizedBox(height: 6),
                    Text(describeStorageReport(report)),
                    for (final move in report.samples.take(10))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(move.to),
                        subtitle: Text(move.from),
                      ),
                    for (final problem in report.errors)
                      Text(problem, style: TextStyle(color: Palette.err)),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: report?.running == true || !saved
                            ? null
                            : () => _apply(true),
                        child: const Text('Dry run'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: mayMoveFiles(current)
                            ? () => _apply(false)
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: Palette.buttonGold,
                          foregroundColor: Palette.onGold,
                        ),
                        child: const Text('Move the files'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
