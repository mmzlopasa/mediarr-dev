import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';
import 'package:photo_manager/photo_manager.dart';

import '../services/backup.dart';
import '../services/session.dart';
import '../theme.dart';

String describeLastBackup(DateTime? last, DateTime now) {
  if (last == null) return 'Nothing has been backed up yet.';
  final age = now.difference(last);
  if (age.inMinutes < 1) return 'Last file backed up just now.';
  if (age.inHours < 1) return 'Last file backed up ${age.inMinutes} min ago.';
  if (age.inDays < 1) return 'Last file backed up ${age.inHours} h ago.';
  return 'Last file backed up ${age.inDays} d ago.';
}

/// The switch and the live state of the automatic backup.
class BackupCard extends ConsumerStatefulWidget {
  const BackupCard({super.key, this.onStatus});

  final void Function(BackupStatus status)? onStatus;

  @override
  ConsumerState<BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends ConsumerState<BackupCard> {
  static const _pollEvery = Duration(seconds: 3);

  BackupStatus? _status;
  Timer? _poll;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(_pollEvery, (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final status = await ref.read(backupProvider).status();
      if (!mounted) {
        return;
      }
      setState(() => _status = status);
      widget.onStatus?.call(status);
    } on MissingPluginException {
      // Only the iOS app has the native engine so far.
    } on PlatformException catch (cause) {
      if (mounted) {
        setState(() => _error = cause.message);
      }
    }
  }

  Future<bool?> _askScope() => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('What should be backed up?'),
      content: const Text(
        'Backing up everything can take a while. Files already on the server are not stored twice.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Only new photos'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('All photos'),
        ),
      ],
    ),
  );

  Future<void> _toggle(bool value) async {
    final session = ref.read(sessionProvider).value;
    final service = ref.read(backupProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (value) {
        final permission = await PhotoManager.requestPermissionExtend();
        if (!permission.hasAccess) {
          setState(() => _error = 'Allow access to your photos in Settings.');
          return;
        }
        final onlyNew = await _askScope();
        if (onlyNew == null || session == null) {
          return;
        }
        await service.enable(
          session,
          wifiOnly: _status?.wifiOnly ?? true,
          onlyNew: onlyNew,
        );
      } else {
        await service.disable(session);
      }
      await _refresh();
    } on ApiException catch (cause) {
      if (mounted) {
        setState(
          () => _error =
              'The server could not be reached. ${cause.message ?? ''}',
        );
      }
    } on PlatformException catch (cause) {
      if (mounted) setState(() => _error = cause.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final status = _status;
    if (status == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
      decoration: BoxDecoration(
        color: Palette.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Automatic backup', style: text.titleMedium),
              ),
              Switch(
                value: status.enabled,
                activeTrackColor: Palette.gold,
                onChanged: _busy ? null : _toggle,
              ),
            ],
          ),
          if (status.enabled) ...[
            Row(
              children: [
                Expanded(child: Text('Only on Wi-Fi', style: text.bodyMedium)),
                Switch(
                  value: status.wifiOnly,
                  activeTrackColor: Palette.gold,
                  onChanged: (value) async {
                    await ref.read(backupProvider).setWifiOnly(value);
                    await _refresh();
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${status.verified} of ${status.total} verified on the server',
              style: text.bodyLarge,
            ),
            if (status.total > 0) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: LinearProgressIndicator(
                  value: status.verified / status.total,
                  minHeight: 4,
                  color: Palette.gold,
                  backgroundColor: Palette.bg3,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '${status.working} sending · ${status.pending} waiting · ${status.failed} failed',
              style: text.bodySmall,
            ),
            Text(
              describeLastBackup(status.lastFinished, DateTime.now()),
              style: text.bodySmall,
            ),
            if (status.unauthorized)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'The server refused this device. Turn backup off and on again.',
                  style: text.bodySmall?.copyWith(color: Palette.err),
                ),
              ),
            if (status.failed > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () async {
                    await ref.read(backupProvider).retryFailed();
                    await _refresh();
                  },
                  child: Text('Try the ${status.failed} failed again'),
                ),
              ),
            if (status.failures.isNotEmpty)
              Text(
                status.failures.first.error,
                style: text.bodySmall?.copyWith(color: Palette.err),
              ),
          ] else
            Text(
              'Sends your photos to your server, also while the app is closed. iOS decides when, '
              'and stops it if you swipe the app away, until you open it again.',
              style: text.bodySmall,
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _error!,
                style: text.bodySmall?.copyWith(color: Palette.err),
              ),
            ),
        ],
      ),
    );
  }
}
