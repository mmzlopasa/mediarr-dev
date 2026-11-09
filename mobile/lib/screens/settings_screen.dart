import '../motion.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mediarr_api/api.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../services/account_preferences.dart';
import '../services/language.dart';
import '../services/backup.dart';
import '../services/session.dart';
import '../services/agent.dart';
import '../services/settings.dart';
import '../services/timeline.dart';
import '../theme.dart';
import '../timeline/layout.dart';
import 'home_widget_screen.dart';
import 'app_header.dart';
import 'free_space_screen.dart';
import 'memories_screen.dart';

/// The list of settings, one card for each subject.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget row(
      IconData icon,
      String title,
      String subtitle,
      Widget? screen, {
      VoidCallback? onTap,
    }) => ListTile(
      leading: RingIcon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap:
          onTap ??
          () =>
              Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => screen!)),
    );
    Widget group(String title, List<Widget> rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Palette.dim,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: rows),
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 30),
        children: [
          group(l.settingsScreenViewing, [
            row(
              Icons.image_outlined,
              l.settingsScreenAssetViewer,
              l.settingsScreenAssetViewerHint,
              const ViewerSettings(),
            ),
            row(
              Icons.dashboard_outlined,
              l.settingsScreenPhotoGrid,
              l.settingsScreenPhotoGridHint,
              const GridSettings(),
            ),
            row(
              Icons.interests_outlined,
              l.settingsScreenPreferences,
              l.settingsScreenPreferencesHint,
              const PreferenceSettings(),
            ),
            row(
              Icons.language,
              l.languageTitle,
              l.settingsScreenLanguageHint,
              const LanguageSettings(),
            ),
          ]),
          group(l.settingsScreenThisPhone, [
            row(
              Icons.cloud_upload_outlined,
              l.settingsScreenBackup,
              l.settingsScreenBackupHint,
              const UploadPage(),
            ),
            row(
              Icons.cleaning_services_outlined,
              l.settingsScreenFreeUpSpace,
              l.settingsScreenFreeUpSpaceHint,
              const FreeSpaceScreen(),
            ),
            row(
              Icons.sync,
              l.settingsScreenSyncStatus,
              l.settingsScreenSyncStatusHint,
              const SyncStatusScreen(),
            ),
            row(
              Icons.widgets_outlined,
              l.settingsScreenHomeWidget,
              l.settingsScreenHomeWidgetHint,
              const HomeWidgetScreen(),
            ),
            row(
              Icons.notifications_outlined,
              l.settingsScreenNotifications,
              l.settingsScreenNotificationsHint,
              const NotificationSettings(),
            ),
          ]),
          group(l.settingsScreenServer, [
            row(
              Icons.devices_outlined,
              l.settingsScreenDevices,
              l.settingsScreenDevicesHint,
              const DevicesScreen(),
            ),
            row(
              Icons.bar_chart_outlined,
              l.settingsScreenYourLibrary,
              l.settingsScreenYourLibraryHint,
              const StatsScreen(),
            ),
            row(
              Icons.wifi,
              l.settingsScreenNetworking,
              l.settingsScreenNetworkingHint,
              const NetworkSettings(),
            ),
            row(
              Icons.build_outlined,
              l.settingsScreenAdvanced,
              l.settingsScreenAdvancedHint,
              const AdvancedSettings(),
            ),
            row(
              Icons.auto_awesome_outlined,
              l.settingsScreenWhatsNew,
              l.settingsScreenWhatsNewHint,
              null,
              onTap: () => launchUrl(
                Uri.parse('https://github.com/mediarr-app/mediarr/tags'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Palette.dim),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: Palette.dim)),
      ],
    ),
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle(this.title, this.subtitle, this.value, this.onChanged);

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    value: value,
    activeThumbColor: Palette.gold,
    onChanged: onChanged,
  );
}

class AdvancedSettings extends ConsumerWidget {
  const AdvancedSettings({super.key});

  /// Read-only is meant for a phone in someone else's hands, so leaving it asks for the phone's lock.
  Future<bool> _mayLeaveReadOnly() async {
    final auth = LocalAuthentication();
    try {
      if (!await auth.isDeviceSupported()) return true;
      return await auth.authenticate(
        localizedReason: l.settingsScreenReadOnlyOff,
      );
    } on MissingPluginException {
      return true;
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsScreenAdvanced)),
      body: ListView(
        children: [
          _Toggle(
            l.settingsScreenReadOnly,
            l.settingsScreenReadOnlyHint,
            settings.readOnly,
            (value) async {
              if (!value && !await _mayLeaveReadOnly()) return;
              await notifier.change(settings.copyWith(readOnly: value));
            },
          ),
          _Toggle(
            l.settingsScreenCopyAlbums,
            l.settingsScreenCopyAlbumsHint,
            settings.mirrorAlbums,
            (value) => notifier.change(settings.copyWith(mirrorAlbums: value)),
          ),
          ListTile(
            leading: const Icon(Icons.playlist_remove),
            title: Text(l.settingsScreenClearCache),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              await DefaultCacheManager().emptyCache();
              PaintingBinding.instance.imageCache.clear();
              messenger.showSnackBar(
                SnackBar(content: Text(l.settingsScreenCacheEmpty)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ViewerSettings extends ConsumerWidget {
  const ViewerSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsScreenAssetViewer)),
      body: ListView(
        children: [
          _Heading(Icons.image_outlined, l.settingsScreenPhotos),
          _Toggle(
            l.settingsScreenLoadFull,
            l.settingsScreenLoadFullHint,
            settings.loadOriginal,
            (value) => notifier.change(settings.copyWith(loadOriginal: value)),
          ),
          _Toggle(
            l.settingsScreenTapToNavigate,
            l.settingsScreenTapToNavigateHint,
            settings.tapToNavigate,
            (value) => notifier.change(settings.copyWith(tapToNavigate: value)),
          ),
          const Divider(),
          _Heading(Icons.videocam_outlined, l.settingsScreenVideos),
          _Toggle(
            l.settingsScreenAutoPlay,
            l.settingsScreenAutoPlayHint,
            settings.autoPlay,
            (value) => notifier.change(settings.copyWith(autoPlay: value)),
          ),
          _Toggle(
            l.settingsScreenLooping,
            l.settingsScreenLoopingHint,
            settings.loopVideos,
            (value) => notifier.change(settings.copyWith(loopVideos: value)),
          ),
          _Toggle(
            l.settingsScreenPlayOriginal,
            l.settingsScreenPlayOriginalHint,
            settings.forceOriginalVideo,
            (value) =>
                notifier.change(settings.copyWith(forceOriginalVideo: value)),
          ),
        ],
      ),
    );
  }
}

class GridSettings extends ConsumerWidget {
  const GridSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsScreenPhotoGrid)),
      body: ListView(
        children: [
          _Heading(Icons.grid_on, l.settingsScreenLayout),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l.settingsScreenPerRow('${settings.perRow}')),
          ),
          Slider(
            value: settings.perRow.toDouble(),
            min: minPerRow.toDouble(),
            max: maxPerRow.toDouble(),
            divisions: maxPerRow - minPerRow,
            activeColor: Palette.gold,
            label: '${settings.perRow}',
            onChanged: (value) =>
                notifier.change(settings.copyWith(perRow: value.round())),
          ),
          const Divider(),
          _Heading(Icons.workspaces_outline, l.settingsScreenGroupBy),
          RadioGroup<bool>(
            groupValue: settings.groupByDay,
            onChanged: (value) =>
                notifier.change(settings.copyWith(groupByDay: value ?? true)),
            child: Column(
              children: [
                RadioListTile<bool>(
                  title: Text(l.settingsScreenMonthDay),
                  value: true,
                ),
                RadioListTile<bool>(
                  title: Text(l.settingsScreenMonth),
                  value: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PreferenceSettings extends ConsumerWidget {
  const PreferenceSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsScreenPreferences)),
      body: ListView(
        children: [
          _Heading(Icons.palette_outlined, l.settingsScreenTheme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<AppTheme>(
              showSelectedIcon: false,
              segments: [
                for (final theme in AppTheme.values)
                  ButtonSegment(value: theme, label: Text(theme.label)),
              ],
              selected: {settings.theme},
              onSelectionChanged: (chosen) =>
                  notifier.change(settings.copyWith(theme: chosen.first)),
            ),
          ),
          _Heading(Icons.colorize_outlined, l.settingsScreenPrimaryColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              children: [
                for (final accent in AppAccent.values)
                  Semantics(
                    label: accent.label,
                    selected: settings.accent == accent,
                    button: true,
                    child: GestureDetector(
                      onTap: () =>
                          notifier.change(settings.copyWith(accent: accent)),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Palette.ink,
                        child: CircleAvatar(
                          radius: settings.accent == accent ? 19 : 22,
                          backgroundColor: Color(
                            Palette.light ? accent.onLight : accent.onDark,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const _AccountChoices(),
          const Divider(height: 34),
          _Heading(Icons.vibration, l.settingsScreenHaptics),
          _Toggle(
            l.settingsScreenEnabled,
            null,
            settings.haptics,
            (value) => notifier.change(settings.copyWith(haptics: value)),
          ),
        ],
      ),
    );
  }
}

class LanguageSettings extends ConsumerWidget {
  const LanguageSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);
    final session = ref.watch(sessionProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l.languageTitle)),
      body: RadioGroup<String>(
        groupValue: current,
        onChanged: (code) {
          if (code != null) {
            ref.read(languageProvider.notifier).choose(code, api: session?.api);
          }
        },
        child: ListView(
          children: [
            for (final entry in appLanguages.entries)
              RadioListTile<String>(
                value: entry.key,
                title: Text(entry.value),
                subtitle: unreviewedLanguages.contains(entry.key)
                    ? Text(l.languageMachine)
                    : null,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.languageFollowsAccount),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationSettings extends StatelessWidget {
  const NotificationSettings({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(l.settingsScreenNotifications)),
    body: EmptyMessage(
      icon: Icons.notifications_outlined,
      text: l.settingsScreenNotificationsNotYet,
    ),
  );
}

class NetworkSettings extends StatelessWidget {
  const NetworkSettings({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(l.settingsScreenNetworking)),
    body: ListView(
      padding: const EdgeInsets.only(top: 16),
      children: const [_SecondAddress()],
    ),
  );
}

/// Real counts, from this phone and the server. What cannot be read says so.
class SyncStatusScreen extends ConsumerStatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  ConsumerState<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends ConsumerState<SyncStatusScreen> {
  int? _localAssets;
  int? _localAlbums;
  int? _remoteAssets;
  int? _remoteAlbums;
  int? _memories;
  int? _verified;
  int _failed = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = ref.read(sessionProvider).value;
    final backup = ref.read(backupProvider);
    if (session == null) return;
    setState(() => _busy = true);
    try {
      final state = await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(),
      );
      if (state.hasAccess) {
        final assets = await PhotoManager.getAssetCount();
        final albums = await PhotoManager.getAssetPathList(hasAll: false);
        if (mounted) {
          setState(() {
            _localAssets = assets;
            _localAlbums = albums.length;
          });
        }
      }
    } on PlatformException {
      // Stays unknown.
    } on MissingPluginException {
      // Stays unknown.
    }
    try {
      final verified = await backup.verifiedChecksums();
      final status = await backup.status();
      if (mounted) {
        setState(() {
          _verified = verified.length;
          _failed = status.failed;
        });
      }
    } on PlatformException {
      // Stays unknown.
    } on MissingPluginException {
      // Stays unknown.
    }
    try {
      final store = ref.read(timelineProvider);
      await store.refresh();
      final albums = await session.api.listAlbums();
      final memories = await session.api.listMemories(
        date: localToday(DateTime.now()),
      );
      if (mounted) {
        setState(() {
          _remoteAssets = (store.months ?? const <TimelineMonth>[]).fold<int>(
            0,
            (sum, month) => sum + month.count,
          );
          _remoteAlbums = albums?.length;
          _memories = memories?.length;
        });
      }
    } on ApiException {
      // Stays unknown.
    }
    if (mounted) setState(() => _busy = false);
  }

  Widget _tile(IconData icon, String label, int? value) => Expanded(
    child: Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Palette.bg2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Palette.gold),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: Palette.gold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value?.toString() ?? '—',
            style: const TextStyle(
              fontSize: 22,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    Widget label(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
      child: Text(text, style: TextStyle(color: Palette.dim)),
    );
    final readOnly = ref.watch(settingsProvider).readOnly;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsScreenSyncStatus)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          label(l.settingsScreenPhotosAndVideos),
          Row(
            children: [
              _tile(Icons.smartphone, l.settingsScreenPhone, _localAssets),
              _tile(Icons.cloud, l.settingsScreenServer, _remoteAssets),
            ],
          ),
          label(l.settingsScreenAlbums),
          Row(
            children: [
              _tile(Icons.smartphone, l.settingsScreenPhone, _localAlbums),
              _tile(Icons.cloud, l.settingsScreenServer, _remoteAlbums),
            ],
          ),
          label(l.settingsScreenOther),
          Row(
            children: [
              _tile(
                Icons.calendar_today_outlined,
                l.settingsScreenMemories,
                _memories,
              ),
              _tile(
                Icons.verified_outlined,
                l.settingsScreenBackedUp,
                _verified,
              ),
            ],
          ),
          const Divider(height: 30),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: Text(l.settingsScreenCheckAgain),
            trailing: _busy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Palette.gold,
                    ),
                  )
                : null,
            onTap: _busy ? null : _load,
          ),
          if (!readOnly && _failed > 0)
            ListTile(
              leading: const Icon(Icons.replay),
              title: Text(l.settingsScreenRetryFailed('$_failed')),
              onTap: () async {
                await ref.read(backupProvider).retryFailed();
                await _load();
              },
            ),
        ],
      ),
    );
  }
}

class _SecondAddress extends ConsumerStatefulWidget {
  const _SecondAddress();

  @override
  ConsumerState<_SecondAddress> createState() => _SecondAddressState();
}

class _SecondAddressState extends ConsumerState<_SecondAddress> {
  final _field = TextEditingController();
  String? _main;
  String? _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notifier = ref.read(sessionProvider.notifier);
    final main = await notifier.mainServer();
    final second = await notifier.secondServer();
    if (!mounted) return;
    setState(() {
      _main = main;
      _field.text = second ?? '';
    });
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    String message;
    try {
      await ref.read(sessionProvider.notifier).setSecondServer(_field.text);
      message = _field.text.trim().isEmpty
          ? l.settingsScreenRemoved
          : l.settingsScreenSaved;
    } on LoginFailure catch (cause) {
      message = cause.message;
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _message = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_main != null) Text(l.settingsScreenMainAddress('$_main')),
        const SizedBox(height: 10),
        TextField(
          controller: _field,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l.settingsScreenSecondAddress,
            helperText: l.settingsScreenSecondAddressHint,
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: _busy ? null : _save,
              child: Text(l.settingsScreenSave),
            ),
            if (_message != null) Expanded(child: Text(_message!)),
          ],
        ),
      ],
    ),
  );
}

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  List<UserSession>? _sessions;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = ref.read(sessionProvider).value;
    if (session == null) return;
    try {
      final sessions = await session.api.listMySessions();
      if (mounted) {
        setState(() {
          _sessions = sessions ?? const [];
          _failed = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _act(Future<void> Function(DefaultApi api) work) async {
    final session = ref.read(sessionProvider).value;
    if (session == null) return;
    try {
      await work(session.api);
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _sessions;
    final Widget body;
    if (sessions == null) {
      body = _failed
          ? EmptyMessage(
              icon: Icons.cloud_off,
              text: l.settingsScreenCouldNotLoad,
            )
          : Center(child: CircularProgressIndicator(color: Palette.gold));
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 30),
        children: [
          GlassCard(
            child: Column(
              children: [
                for (final item in sessions)
                  ListTile(
                    leading: RingIcon(
                      describeAgent(item.userAgent).phone
                          ? Icons.smartphone_outlined
                          : Icons.desktop_windows_outlined,
                      on: item.current,
                    ),
                    title: Text(
                      describeAgent(item.userAgent).title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        if (item.current) l.settingsScreenThisDevice,
                        if (item.ip.isNotEmpty) item.ip,
                        since(item.lastSeenAt.toLocal()),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: item.current
                        ? null
                        : TextButton(
                            onPressed: () =>
                                _act((api) => api.endSession(item.id)),
                            child: Text(l.settingsScreenSignOut),
                          ),
                  ),
              ],
            ),
          ),
          if (sessions.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextButton(
                onPressed: () => _act((api) => api.endOtherSessions()),
                child: Text(l.settingsScreenSignOutOthers),
              ),
            ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsScreenDevices)),
      body: body,
    );
  }
}

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  AccountStats? _stats;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = ref.read(sessionProvider).value;
    if (session == null) return;
    try {
      final stats = await session.api.getMyStats();
      if (mounted) setState(() => _stats = stats);
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final Widget body;
    if (stats == null) {
      body = _failed
          ? EmptyMessage(
              icon: Icons.cloud_off,
              text: l.settingsScreenCouldNotLoad,
            )
          : Center(child: CircularProgressIndicator(color: Palette.gold));
    } else {
      Widget row(String label, num value, [String Function(num)? format]) =>
          ListTile(
            title: Text(label),
            trailing: CountUp(
              value: value,
              format: format,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
      body = ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 30),
        children: [
          GlassCard(
            child: Column(
              children: [
                row(l.settingsScreenPhotos, stats.photos),
                row(l.settingsScreenVideos, stats.videos),
                row(l.settingsScreenAlbums, stats.albums),
                row(l.settingsScreenFavorites, stats.favorites),
                row(l.settingsScreenArchive, stats.archived),
                row(l.settingsScreenTrash, stats.trashed),
                row(
                  l.settingsScreenUsed,
                  stats.bytes,
                  (v) => formatBytes(v.round()),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsScreenYourLibrary)),
      body: body,
    );
  }
}

/// Choices kept on the server, which follow this person to every device.
class _AccountChoices extends ConsumerWidget {
  const _AccountChoices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(accountPreferencesProvider).value;
    if (prefs == null) return const SizedBox.shrink();
    final notifier = ref.read(accountPreferencesProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 34),
        _Heading(Icons.person_outline, l.settingsScreenYourAccount),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l.settingsScreenMemorySeconds('${prefs.memorySeconds}')),
        ),
        Slider(
          value: prefs.memorySeconds.toDouble().clamp(1, 20),
          min: 1,
          max: 20,
          divisions: 19,
          activeColor: Palette.gold,
          onChanged: (value) {
            prefs.memorySeconds = value.round();
            notifier.change(prefs);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l.settingsScreenMinFaces('${prefs.minFaces}')),
        ),
        Slider(
          value: prefs.minFaces.toDouble().clamp(1, 20),
          min: 1,
          max: 20,
          divisions: 19,
          activeColor: Palette.gold,
          onChanged: (value) {
            prefs.minFaces = value.round();
            notifier.change(prefs);
          },
        ),
        ListTile(
          title: Text(l.settingsScreenAlbumOrder),
          trailing: DropdownButton<UserPreferencesAlbumOrderEnum>(
            value: prefs.albumOrder,
            items: [
              DropdownMenuItem(
                value: UserPreferencesAlbumOrderEnum.newest,
                child: Text(l.settingsScreenNewestFirst),
              ),
              DropdownMenuItem(
                value: UserPreferencesAlbumOrderEnum.oldest,
                child: Text(l.settingsScreenOldestFirst),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              prefs.albumOrder = value;
              notifier.change(prefs);
            },
          ),
        ),
      ],
    );
  }
}
