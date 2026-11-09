import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'admin/admin_screen.dart';
import '../brand.dart';
import '../services/backup.dart';
import '../services/session.dart';
import '../services/settings.dart';
import '../theme.dart';
import '../timeline/layout.dart';
import 'backup_screen.dart';
import 'devices_screen.dart';
import 'free_space_screen.dart';
import 'exports_screen.dart';
import 'imports_screen.dart';
import 'profile_screen.dart';
import 'qr_sign_in.dart';
import 'organize_screens.dart';
import 'settings_screen.dart';
import 'storage_template_screen.dart';
import '../l10n/l10n.dart';

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
  String? _serverName;
  AccountStats? _stats;
  AssetList? _problems;
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
          () => _appVersion = l.accountSheetVersionBuild(
            info.version,
            info.buildNumber,
          ),
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
      // Files the server could not read, told here rather than over the photos.
      final problems = await session.api.listAssets(
        limit: 200,
        status: 'failed',
      );
      if (mounted) setState(() => _problems = problems);
    } on ApiException {
      // Nothing to tell.
    }
    try {
      final methods = await session.api.getAuthMethods();
      if (mounted) setState(() => _serverName = methods?.serverName);
    } on ApiException {
      // The name is only shown when it is known.
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
                GestureDetector(
                  onTap: () => _push(const ProfileScreen()),
                  child: Semantics(
                    button: true,
                    label: l.accountSheetEditProfile,
                    child: PersonAvatar(
                      session: session,
                      user: session.user,
                      size: 48,
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
                  tooltip: l.accountSheetClose,
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
                          l.accountSheetPhotosAndVideos(
                            '${_stats!.photos + _stats!.videos}',
                          ),
                          style: text.bodySmall?.copyWith(color: Palette.ink),
                        ),
                      ),
                      Text(
                        l.accountSheetUsed(formatBytes(_stats!.bytes)),
                        style: text.bodySmall?.copyWith(color: Palette.ink),
                      ),
                    ],
                  ),
          ),
          if ((_problems?.failed ?? 0) > 0)
            ListTile(
              leading: Icon(Icons.error_outline, color: Palette.err),
              title: Text(l.accountSheetFilesFailed(_problems!.failed)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (context) => SafeArea(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final asset in _problems!.items)
                        ListTile(
                          title: Text(asset.originalName, style: monoData(13)),
                          subtitle: Text(asset.error ?? ''),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          _section([
            const SizedBox(height: 6),
            Row(
              children: [
                Text(l.accountSheetAppearance, style: text.bodySmall),
                const SizedBox(width: 16),
                Expanded(
                  child: SegmentedButton<AppTheme>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: AppTheme.dark,
                        label: Text(l.accountSheetDark),
                      ),
                      ButtonSegment(
                        value: AppTheme.light,
                        label: Text(l.accountSheetLight),
                      ),
                      ButtonSegment(
                        value: AppTheme.system,
                        label: Text(l.accountSheetSystem),
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
            Text(l.accountSheetServerDisk, style: text.titleMedium),
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
                  ? (_online
                        ? l.accountSheetLoading
                        : l.accountSheetServerNoAnswer)
                  : l.accountSheetDiskUsed(
                      formatBytes(used),
                      formatBytes(total),
                    ),
              style: text.bodySmall,
            ),
          ]),
          _section([
            if (_appVersion != null)
              _row(l.accountSheetAppVersion, _appVersion!),
            _row(
              l.accountSheetServerVersion,
              status?.version ?? (_online ? '…' : '—'),
            ),
            if (status?.updateAvailable == true)
              _row(
                l.accountSheetNewVersion,
                l.accountSheetIsAvailable('${status?.latestVersion}'),
              ),
            if (_serverName != null && _serverName != 'Mediarr')
              _row(l.accountSheetServer, _serverName!),
            _row(l.accountSheetServerAddress, session.serverUrl),
          ]),
          Divider(color: Palette.line, height: 1),
          const SizedBox(height: 6),
          ListTile(
            leading: Icon(Icons.cleaning_services_outlined, color: Palette.dim),
            title: Text(l.accountSheetFreeUpSpace),
            onTap: () => _push(const FreeSpaceScreen()),
          ),
          ListTile(
            leading: Icon(Icons.person_outline, color: Palette.dim),
            title: Text(l.accountSheetProfile),
            onTap: () => _push(const ProfileScreen()),
          ),
          ListTile(
            leading: Icon(Icons.qr_code_2, color: Palette.dim),
            title: Text(l.accountSheetSignInOnAnotherDevice),
            onTap: () => _push(const ShowSignInCodeScreen()),
          ),
          ListTile(
            leading: Icon(Icons.phone_iphone, color: Palette.dim),
            title: Text(l.accountSheetBackupDevices),
            onTap: () => _push(const BackupDevicesScreen()),
          ),
          ListTile(
            leading: Icon(Icons.download_outlined, color: Palette.dim),
            title: Text(l.accountSheetImport),
            onTap: () => _push(const ImportsScreen()),
          ),
          ListTile(
            leading: Icon(Icons.ios_share, color: Palette.dim),
            title: Text(l.accountSheetExport),
            onTap: () => _push(const ExportsScreen()),
          ),
          if (session.user.isAdmin)
            ListTile(
              leading: Icon(
                Icons.admin_panel_settings_outlined,
                color: Palette.dim,
              ),
              title: Text(l.accountSheetAdministration),
              onTap: () => _push(const AdminScreen()),
            ),
          if (session.user.isAdmin)
            ListTile(
              leading: Icon(Icons.backup_outlined, color: Palette.dim),
              title: Text(l.accountSheetBackup),
              onTap: () => _push(const BackupScreen()),
            ),
          if (session.user.isAdmin)
            ListTile(
              leading: Icon(Icons.devices_other_outlined, color: Palette.dim),
              title: Text(l.accountSheetAllBackupDevices),
              onTap: () => _push(const BackupDevicesScreen(all: true)),
            ),
          if (session.user.isAdmin)
            ListTile(
              leading: Icon(Icons.drive_file_move_outline, color: Palette.dim),
              title: Text(l.accountSheetStorageTemplate),
              onTap: () => _push(const StorageTemplateScreen()),
            ),
          ListTile(
            leading: Icon(Icons.settings_outlined, color: Palette.dim),
            title: Text(l.accountSheetSettings),
            onTap: () => _push(const SettingsScreen()),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Palette.dim),
            title: Text(l.accountSheetSignOut),
            onTap: () => _signOut(session),
          ),
          const SizedBox(height: 12),
          const Center(child: BrandLogo(size: 16)),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              _link(l.accountSheetDocumentation, 'https://docs.mediarr.app'),
              _link('GitHub', 'https://github.com/mediarr-app/mediarr'),
              TextButton(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: 'Mediarr',
                  applicationIcon: const BrandMark(size: 40),
                ),
                child: Text(
                  l.accountSheetLicenses,
                  style: TextStyle(color: Palette.haze),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
