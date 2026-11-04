import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mediarr_api/api.dart';

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
        });
      }
    } on ApiException {
      if (mounted) setState(() => _online = false);
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
          Text('Storage', style: text.titleMedium),
          const SizedBox(height: 4),
          Text(
            '${formatBytes(used)} of ${formatBytes(total)} used',
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
              color: _online ? Palette.ok : Palette.err,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _online ? 'Server online' : 'Server offline',
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
              'Version ${status?.latestVersion} is available',
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
      title: const Text('A new version is available'),
      content: Text(
        'Mediarr $latest is available. This server runs $version. '
        'The server administrator updates it with:\n\n'
        'docker compose pull && docker compose up -d',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  await storage.write(key: _seenKey, value: latest);
}
