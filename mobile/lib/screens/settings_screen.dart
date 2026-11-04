import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../services/session.dart';
import '../services/settings.dart';
import '../theme.dart';
import 'free_space_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
    final text = Theme.of(context).textTheme;

    Widget heading(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 6),
      child: Text(label, style: text.titleSmall?.copyWith(color: Palette.gold)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          heading('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<AppTheme>(
              segments: [
                for (final theme in AppTheme.values)
                  ButtonSegment(value: theme, label: Text(theme.label)),
              ],
              selected: {settings.theme},
              onSelectionChanged: (chosen) =>
                  notifier.change(settings.copyWith(theme: chosen.first)),
            ),
          ),
          heading('Photo grid'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<GridSize>(
              segments: [
                for (final size in GridSize.values)
                  ButtonSegment(value: size, label: Text(size.label)),
              ],
              selected: {settings.gridSize},
              onSelectionChanged: (chosen) =>
                  notifier.change(settings.copyWith(gridSize: chosen.first)),
            ),
          ),
          heading('Server'),
          const _SecondAddress(),
          heading('This phone'),
          if (!settings.readOnly)
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: const Text('Free up space'),
              subtitle: const Text(
                'Remove what is already safe on your server',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FreeSpaceScreen(),
                ),
              ),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.photo_album_outlined),
            title: const Text('Copy albums to the server'),
            subtitle: const Text(
              'Backed-up albums get an album of the same name on the server. Photos are only added, never removed',
            ),
            value: settings.mirrorAlbums,
            activeThumbColor: Palette.gold,
            onChanged: (value) =>
                notifier.change(settings.copyWith(mirrorAlbums: value)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.visibility_outlined),
            title: const Text('Read-only mode'),
            subtitle: const Text(
              'Only look: no uploading, editing or deleting from this app',
            ),
            value: settings.readOnly,
            activeThumbColor: Palette.gold,
            onChanged: (value) async {
              if (!value && !await _mayLeaveReadOnly()) return;
              await notifier.change(settings.copyWith(readOnly: value));
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
