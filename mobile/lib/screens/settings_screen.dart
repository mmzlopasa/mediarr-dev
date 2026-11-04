import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

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
