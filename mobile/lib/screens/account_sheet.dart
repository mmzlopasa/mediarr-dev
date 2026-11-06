import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../brand.dart';
import '../services/backup.dart';
import '../services/session.dart';
import '../services/settings.dart';
import '../theme.dart';
import '../timeline/layout.dart';
import 'backup_screen.dart';
import 'free_space_screen.dart';
import 'imports_screen.dart';
import 'organize_screens.dart';
import 'settings_screen.dart';

Future<void> showAccountSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, 40, 10, 10),
          child: GlassCard(radius: 28, child: AccountSheet()),
        ),
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
  AccountStats? _stats;
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
      final stats = await session.api.getMyStats();
      if (mounted) setState(() => _stats = stats);
    } on ApiException {
      // The line about the library waits; the rest still shows.
    }
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

  Widget _section(List<Widget> children) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Palette.line2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          _section([
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Palette.fill,
                  ),
                  child: Text(
                    name.isEmpty
                        ? '?'
                        : name
                              .substring(0, name.length < 2 ? 1 : 2)
                              .toUpperCase(),
                    style: const TextStyle(
                      color: Palette.onFill,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: displayTitle(26),
                      ),
                      Text(
                        session.user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(color: Palette.dim),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ]),
          // The library in one line, as on the web.
          Container(
            color: Palette.bg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _stats == null
                ? Text('…', style: text.bodySmall)
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_stats!.photos + _stats!.videos} photos and videos',
                          style: text.bodySmall?.copyWith(color: Palette.ink),
                        ),
                      ),
                      Text(
                        '${formatBytes(_stats!.bytes)} used',
                        style: text.bodySmall?.copyWith(color: Palette.ink),
                      ),
                    ],
                  ),
          ),
          _section([
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Appearance', style: text.bodySmall),
                const SizedBox(width: 16),
                Expanded(
                  child: SegmentedButton<AppTheme>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: AppTheme.dark, label: Text('Dark')),
                      ButtonSegment(
                        value: AppTheme.light,
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: AppTheme.system,
                        label: Text('System'),
                      ),
                    ],
                    selected: {ref.watch(settingsProvider).theme},
                    onSelectionChanged: (choice) => ref
                        .read(settingsProvider.notifier)
                        .change(
                          ref
                              .read(settingsProvider)
                              .copyWith(theme: choice.first),
                        ),
                  ),
                ),
              ],
            ),
          ]),
          Divider(color: Palette.line, height: 1),
          _section([
            const SizedBox(height: 6),
            Text('Server disk', style: text.titleMedium),
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
          Divider(color: Palette.line, height: 1),
          const SizedBox(height: 6),
          ListTile(
            leading: Icon(Icons.cleaning_services_outlined, color: Palette.dim),
            title: const Text('Free up space'),
            onTap: () => _push(const FreeSpaceScreen()),
          ),
          ListTile(
            leading: Icon(Icons.download_outlined, color: Palette.dim),
            title: const Text('Import'),
            onTap: () => _push(const ImportsScreen()),
          ),
          if (session.user.isAdmin)
            ListTile(
              leading: Icon(Icons.backup_outlined, color: Palette.dim),
              title: const Text('Backup'),
              onTap: () => _push(const BackupScreen()),
            ),
          ListTile(
            leading: Icon(Icons.settings_outlined, color: Palette.dim),
            title: const Text('Settings'),
            onTap: () => _push(const SettingsScreen()),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Palette.dim),
            title: const Text('Sign out'),
            onTap: () => _signOut(session),
          ),
          const SizedBox(height: 12),
          const Center(child: BrandLogo(size: 16)),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              _link('Documentation', 'https://docs.mediarr.app'),
              _link('GitHub', 'https://github.com/mediarr-app/mediarr'),
              TextButton(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: 'Mediarr',
                  applicationIcon: const BrandMark(size: 40),
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
