import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/backup.dart';
import '../services/session.dart';
import '../theme.dart';
import '../timeline/layout.dart';
import 'free_space_screen.dart';
import 'organize_screens.dart';
import 'settings_screen.dart';

Future<void> showAccountSheet(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const Dialog(
    insetPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 40),
    child: AccountSheet(),
  ),
);

/// Who is signed in, the server's disk and versions, and the ways further.
class AccountSheet extends ConsumerStatefulWidget {
  const AccountSheet({super.key});

  @override
  ConsumerState<AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<AccountSheet> {
  ServerStatus? _status;
  String? _appVersion;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(
          () => _appVersion = '${info.version} build ${info.buildNumber}',
        );
      }
    } on MissingPluginException {
      // Only in tests.
    }
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

  void _push(Widget screen) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _signOut(Session session) async {
    final navigator = Navigator.of(context);
    // Otherwise the device would keep uploading after signing out.
    final backup = ref.read(backupProvider);
    final notifier = ref.read(sessionProvider.notifier);
    try {
      await backup.disable(session);
    } on MissingPluginException {
      // No native engine on this platform.
    }
    await forgetVaultPin();
    navigator.pop();
    await notifier.signOut();
  }

  Widget _section(List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Palette.bg,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(color: Palette.dim),
          ),
        ),
      ],
    ),
  );

  Widget _link(String label, String url) => TextButton(
    onPressed: () =>
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    child: Text(label, style: TextStyle(color: Palette.haze)),
  );

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
    if (session == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final status = _status;
    final total = status?.diskTotalBytes ?? 0;
    final used = status?.diskUsedBytes ?? 0;
    final name = session.user.name.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'mediarr.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Palette.gold,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          _section([
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Palette.bg3,
                  child: Text(
                    name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.user.name,
                        style: text.titleMedium?.copyWith(color: Palette.gold),
                      ),
                      Text(session.user.email, style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ]),
          _section([
            Text('Server storage', style: text.titleMedium),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: total > 0 ? used / total : 0,
              color: Palette.gold,
              backgroundColor: Palette.line2,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 8),
            Text(
              status == null
                  ? (_online ? 'Loading…' : 'The server does not answer.')
                  : '${formatBytes(used)} of ${formatBytes(total)} used',
              style: text.bodySmall,
            ),
          ]),
          _section([
            if (_appVersion != null) _row('App version', _appVersion!),
            _row('Server version', status?.version ?? (_online ? '…' : '—')),
            if (status?.updateAvailable == true)
              _row('New version', '${status?.latestVersion} is available'),
            _row('Server address', session.serverUrl),
          ]),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Free up space'),
            onTap: () => _push(const FreeSpaceScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () => _push(const SettingsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => _signOut(session),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              _link('Documentation', 'https://docs.mediarr.app'),
              _link('GitHub', 'https://github.com/mediarr-app/mediarr'),
              TextButton(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: 'Mediarr',
                ),
                child: Text('Licenses', style: TextStyle(color: Palette.haze)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
