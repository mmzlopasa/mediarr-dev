import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mediarr_api/api.dart';

import '../l10n/l10n.dart';
import '../services/session.dart';
import '../theme.dart';
import '../timeline/layout.dart';

const _seenKey = 'update_seen';

/// Storage, whether the server answers, and its version, as in the web's side menu.
class ServerStatusCard extends ConsumerStatefulWidget {
  const ServerStatusCard({super.key});

  @override
  ConsumerState<ServerStatusCard> createState() => _ServerStatusCardState();
}

class _ServerStatusCardState extends ConsumerState<ServerStatusCard> {
  ServerStatus? _status;
  bool _online = true;
  bool _maintained = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = ref.read(sessionProvider).value;
    if (session == null) return;
    try {
      final status = await session.api.getServerStatus();
      if (mounted) {
        setState(() {
          _status = status;
          _online = true;
          _maintained = false;
        });
      }
    } on ApiException catch (cause) {
      if (mounted) {
        setState(() {
          _online = false;
          _maintained = cause.code == 503;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final status = _status;
    final total = status?.diskTotalBytes ?? 0;
    final used = status?.diskUsedBytes ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status != null) ...[
          Text(l.serverStatusStorage, style: text.titleMedium),
          const SizedBox(height: 4),
          Text(
            l.serverStatusUsedOf(formatBytes(used), formatBytes(total)),
            style: text.bodySmall,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: total > 0 ? used / total : 0,
            color: Palette.gold,
            backgroundColor: Palette.line2,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Icon(
              Icons.circle,
              size: 9,
              color: _online
                  ? Palette.ok
                  : _maintained
                  ? Palette.gold
                  : Palette.err,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _online
                    ? l.serverStatusOnline
                    : _maintained
                    ? l.serverStatusMaintained
                    : l.serverStatusOffline,
                style: text.bodyMedium,
              ),
            ),
            if (status != null) Text(status.version, style: text.bodySmall),
          ],
        ),
        if (status?.updateAvailable == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l.serverStatusVersionAvailable('${status?.latestVersion}'),
              style: text.bodyMedium?.copyWith(color: Palette.gold),
            ),
          ),
      ],
    );
  }
}

/// Tells about a new version once for each version.
Future<void> showUpdateNoticeIfNew(
  BuildContext context,
  Session session,
) async {
  const storage = FlutterSecureStorage();
  final ServerStatus? status;
  try {
    status = await session.api.getServerStatus();
  } on ApiException {
    return;
  }
  final latest = status?.latestVersion;
  if (status == null || !status.updateAvailable || latest == null) return;
  if (await storage.read(key: _seenKey) == latest || !context.mounted) return;
  final version = status.version;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.serverStatusNewVersion),
      content: Text(l.serverStatusUpdateBody(latest, version)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.serverStatusOk),
        ),
      ],
    ),
  );
  await storage.write(key: _seenKey, value: latest);
}
