import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mediarr_api/api.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/account_preferences.dart';
import '../services/backup.dart';
import '../services/session.dart';
import '../services/settings.dart';
import '../services/timeline.dart';
import '../theme.dart';
import '../timeline/layout.dart';
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
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 30),
        children: [
          group('Viewing', [
            row(
              Icons.image_outlined,
              'Asset viewer',
              'How photos and videos open',
              const ViewerSettings(),
            ),
            row(
              Icons.dashboard_outlined,
              'Photo grid',
              'How the timeline is laid out',
              const GridSettings(),
            ),
            row(
              Icons.interests_outlined,
              'Preferences',
              'Theme, color and feedback',
              const PreferenceSettings(),
            ),
            row(
              Icons.language,
              'Language',
              "The app's language",
              const LanguageSettings(),
            ),
          ]),
          group('This phone', [
            row(
              Icons.cloud_upload_outlined,
              'Backup',
              'What this phone sends to the server',
              const UploadPage(),
            ),
            row(
              Icons.cleaning_services_outlined,
              'Free up space',
              'Remove what is safe on the server',
              const FreeSpaceScreen(),
            ),
            row(
              Icons.sync,
              'Sync status',
              'What is on this phone and on the server',
              const SyncStatusScreen(),
            ),
            row(
              Icons.notifications_outlined,
              'Notifications',
              'What the app tells you about',
              const NotificationSettings(),
            ),
          ]),
          group('Server', [
            row(
              Icons.devices_outlined,
              'Devices',
              'Where this account is signed in',
              const DevicesScreen(),
            ),
            row(
              Icons.bar_chart_outlined,
              'Your library',
              'How much this account holds',
              const StatsScreen(),
            ),
            row(
              Icons.wifi,
              'Networking',
              'The addresses of your server',
              const NetworkSettings(),
            ),
            row(
              Icons.build_outlined,
              'Advanced',
              'Read-only mode and the image cache',
              const AdvancedSettings(),
            ),
            row(
              Icons.auto_awesome_outlined,
              "What's new",
              'The versions of Mediarr',
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
        localizedReason: 'Turn off read-only mode',
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
      appBar: AppBar(title: const Text('Advanced')),
      body: ListView(
        children: [
          _Toggle(
            'Read-only mode',
            'Only look: no uploading, editing or deleting from this app',
            settings.readOnly,
            (value) async {
              if (!value && !await _mayLeaveReadOnly()) return;
              await notifier.change(settings.copyWith(readOnly: value));
            },
          ),
          _Toggle(
            'Copy albums to the server',
            'Backed-up albums get an album of the same name on the server. Photos are only added, never removed',
            settings.mirrorAlbums,
            (value) => notifier.change(settings.copyWith(mirrorAlbums: value)),
          ),
          ListTile(
            leading: const Icon(Icons.playlist_remove),
            title: const Text('Clear image cache'),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              await DefaultCacheManager().emptyCache();
              PaintingBinding.instance.imageCache.clear();
              messenger.showSnackBar(
                const SnackBar(content: Text('The image cache is empty.')),
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
      appBar: AppBar(title: const Text('Asset viewer')),
      body: ListView(
        children: [
          const _Heading(Icons.image_outlined, 'Photos'),
          _Toggle(
            'Load the full photo',
            'Opens photos at full resolution. This uses more data and is slower',
            settings.loadOriginal,
            (value) => notifier.change(settings.copyWith(loadOriginal: value)),
          ),
          _Toggle(
            'Tap to navigate',
            'Tapping the left or right quarter of the screen goes to the previous or next photo',
            settings.tapToNavigate,
            (value) => notifier.change(settings.copyWith(tapToNavigate: value)),
          ),
          const Divider(),
          const _Heading(Icons.videocam_outlined, 'Videos'),
          _Toggle(
            'Auto play videos',
            'Videos start when they are opened',
            settings.autoPlay,
            (value) => notifier.change(settings.copyWith(autoPlay: value)),
          ),
          _Toggle(
            'Looping',
            'Videos start again when they end',
            settings.loopVideos,
            (value) => notifier.change(settings.copyWith(loopVideos: value)),
          ),
          _Toggle(
            'Play the original video',
            'Plays the original even when a converted version exists. It may have to buffer',
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
      appBar: AppBar(title: const Text('Photo grid')),
      body: ListView(
        children: [
          const _Heading(Icons.grid_on, 'Layout'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Photos per row (${settings.perRow})'),
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
          const _Heading(Icons.workspaces_outline, 'Group by'),
          RadioGroup<bool>(
            groupValue: settings.groupByDay,
            onChanged: (value) =>
                notifier.change(settings.copyWith(groupByDay: value ?? true)),
            child: const Column(
              children: [
                RadioListTile<bool>(title: Text('Month + day'), value: true),
                RadioListTile<bool>(title: Text('Month'), value: false),
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
      appBar: AppBar(title: const Text('Preferences')),
      body: ListView(
        children: [
          const _Heading(Icons.palette_outlined, 'Theme'),
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
          const _Heading(Icons.colorize_outlined, 'Primary color'),
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
          const _Heading(Icons.vibration, 'Haptic feedback'),
          _Toggle(
            'Enabled',
            null,
            settings.haptics,
            (value) => notifier.change(settings.copyWith(haptics: value)),
          ),
        ],
      ),
    );
  }
}

class LanguageSettings extends StatelessWidget {
  const LanguageSettings({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Language')),
    body: const EmptyMessage(
      icon: Icons.language,
      text: 'The app is in English for now. Other languages are not available yet.',
    ),
  );
}

class NotificationSettings extends StatelessWidget {
  const NotificationSettings({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: const EmptyMessage(
      icon: Icons.notifications_outlined,
      text: 'Notifications are not available yet.',
    ),
  );
}

class NetworkSettings extends StatelessWidget {
  const NetworkSettings({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Networking')),
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
      appBar: AppBar(title: const Text('Sync status')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          label('Photos and videos'),
          Row(
            children: [
              _tile(Icons.smartphone, 'Phone', _localAssets),
              _tile(Icons.cloud, 'Server', _remoteAssets),
            ],
          ),
          label('Albums'),
          Row(
            children: [
              _tile(Icons.smartphone, 'Phone', _localAlbums),
              _tile(Icons.cloud, 'Server', _remoteAlbums),
            ],
          ),
          label('Other'),
          Row(
            children: [
              _tile(Icons.calendar_today_outlined, 'Memories', _memories),
              _tile(Icons.verified_outlined, 'Backed up', _verified),
            ],
          ),
          const Divider(height: 30),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Check again'),
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
              title: Text('Send the $_failed that failed again'),
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
      message = _field.text.trim().isEmpty ? 'Removed.' : 'Saved.';
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
        if (_main != null) Text('Main address: $_main'),
        const SizedBox(height: 10),
        TextField(
          controller: _field,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Second address',
            helperText: 'Used when the main one does not answer, such as away from home',
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: _busy ? null : _save,
              child: const Text('Save'),
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
          ? const EmptyMessage(
              icon: Icons.cloud_off,
              text: 'This could not be loaded.',
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
                      Icons.smartphone_outlined,
                      on: item.current,
                    ),
                    title: Text(item.current ? 'This device' : item.ip),
                    subtitle: Text(
                      '${item.userAgent}\n${item.lastSeenAt.toLocal()}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: item.current
                        ? null
                        : TextButton(
                            onPressed: () =>
                                _act((api) => api.endSession(item.id)),
                            child: const Text('Sign out'),
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
                child: const Text('Sign out all the others'),
              ),
            ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
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
          ? const EmptyMessage(
              icon: Icons.cloud_off,
              text: 'This could not be loaded.',
            )
          : Center(child: CircularProgressIndicator(color: Palette.gold));
    } else {
      Widget row(String label, String value) => ListTile(
        title: Text(label),
        trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
      );
      body = ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 30),
        children: [
          GlassCard(
            child: Column(
              children: [
                row('Photos', '${stats.photos}'),
                row('Videos', '${stats.videos}'),
                row('Albums', '${stats.albums}'),
                row('Favorites', '${stats.favorites}'),
                row('Archive', '${stats.archived}'),
                row('Trash', '${stats.trashed}'),
                row('Used', formatBytes(stats.bytes)),
              ],
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Your library')),
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
        const _Heading(Icons.person_outline, 'Your account'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Seconds for each picture in memories (${prefs.memorySeconds})',
          ),
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
          child: Text(
            'Fewest photos for a person to be listed (${prefs.minFaces})',
          ),
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
          title: const Text('Order in a new album'),
          trailing: DropdownButton<UserPreferencesAlbumOrderEnum>(
            value: prefs.albumOrder,
            items: const [
              DropdownMenuItem(
                value: UserPreferencesAlbumOrderEnum.newest,
                child: Text('Newest first'),
              ),
              DropdownMenuItem(
                value: UserPreferencesAlbumOrderEnum.oldest,
                child: Text('Oldest first'),
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
