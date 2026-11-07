import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/agent.dart';
import '../services/backup.dart';
import '../services/devices.dart';
import '../services/session.dart';
import '../theme.dart';

/// The state of a device in a word or two.
String deviceState(BackupDevice device) {
  if (device.quiet) return 'Quiet';
  if (device.failed > 0 || device.gone + device.trashed > 0) {
    return 'Needs a look';
  }
  return 'All good';
}

/// What the server counts as safe from a device, in one line.
String describeSafe(BackupDevice device) {
  final line = '${device.confirmed} files confirmed by the server';
  return device.files > device.confirmed
      ? '$line, of ${device.files} the device sent'
      : line;
}

/// The phone's own counts, and what is no longer safe on the server.
String describeCounts(BackupDevice device) {
  final parts = [
    'waiting ${device.pending + device.working}',
    'not sent ${device.failed}',
    if (device.trashed > 0) 'in the trash ${device.trashed}',
    if (device.gone > 0) 'no longer on the server ${device.gone}',
  ];
  return parts.join(' · ');
}

const quietChoices = [1, 3, 7, 14, 0];

String quietLabel(int days) => switch (days) {
  0 => 'Never',
  1 => '1 day',
  _ => '$days days',
};

/// Phones that back up, and how much from each is safe on the server, as on the web. With [all],
/// an administrator sees every user's devices.
class BackupDevicesScreen extends ConsumerStatefulWidget {
  const BackupDevicesScreen({super.key, this.all = false});

  final bool all;

  @override
  ConsumerState<BackupDevicesScreen> createState() =>
      _BackupDevicesScreenState();
}

class _BackupDevicesScreenState extends ConsumerState<BackupDevicesScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  BackupDeviceList? _list;
  String? _thisDevice;
  bool _failed = false;
  final Map<String, BackupDeviceMissing> _missing = {};

  @override
  void initState() {
    super.initState();
    _load(report: !widget.all);
  }

  Future<void> _load({bool report = false}) async {
    if (report) {
      // This phone reports first, so its line is fresh.
      try {
        final backup = ref.read(backupProvider);
        final status = await backup.status();
        _thisDevice = status.deviceId;
        await reportThisDevice(_session.api, backup, status: status);
      } on MissingPluginException {
        // No native backup here.
      } on PlatformException {
        // The list still shows.
      } on ApiException {
        // The same.
      }
    }
    try {
      final list = widget.all
          ? await _session.api.listAllBackupDevices()
          : await _session.api.listBackupDevices();
      if (!mounted) return;
      final devices = [...?list?.devices];
      // This phone on top.
      devices.sort(
        (a, b) => (b.id == _thisDevice ? 1 : 0) - (a.id == _thisDevice ? 1 : 0),
      );
      setState(() {
        _list = list == null
            ? null
            : BackupDeviceList(devices: devices, quietDays: list.quietDays);
        _failed = list == null;
      });
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _toggleMissing(BackupDevice device) async {
    if (_missing.containsKey(device.id)) {
      setState(() => _missing.remove(device.id));
      return;
    }
    try {
      final found = await _session.api.listBackupDeviceMissing(device.id);
      if (mounted && found != null) {
        setState(() => _missing[device.id] = found);
      }
    } on ApiException catch (cause) {
      _say(cause.message ?? 'Not loaded.');
    }
  }

  Future<void> _remove(BackupDevice device) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${device.name}?'),
        content: const Text(
          'Its photos stay on the server. If it reports again, it comes back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await _session.api.deleteBackupDevice(device.id);
      await _load();
    } on ApiException catch (cause) {
      _say(cause.message ?? 'Not removed.');
    }
  }

  Future<void> _setQuietDays(int days) async {
    try {
      await _session.api.setBackupQuietDays(BackupQuietDays(days: days));
      await _load();
      _say('Saved.');
    } on ApiException catch (cause) {
      _say(cause.message ?? 'Not saved.');
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _device(BackupDevice device) {
    final text = Theme.of(context).textTheme;
    final total =
        device.pending + device.working + device.verified + device.failed;
    final state = deviceState(device);
    final color = device.quiet
        ? Palette.err
        : state == 'All good'
        ? Palette.ok
        : Palette.warn;
    final missing = _missing[device.id];
    final owner = device.ownerName.isEmpty
        ? device.ownerEmail
        : '${device.ownerName} (${device.ownerEmail})';
    return Container(
      key: ValueKey(device.id),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Palette.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: device.quiet ? Palette.err : Palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_iphone, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  device.id == _thisDevice
                      ? '${device.name} · This phone'
                      : device.name,
                  style: text.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(state, style: text.labelMedium?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (widget.all) owner,
              device.platform == 'ios' ? 'iOS' : 'Android',
              if (device.appVersion.isNotEmpty) 'Mediarr ${device.appVersion}',
              'last report ${since(device.reportedAt.toLocal())}',
            ].join(' · '),
            style: text.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(describeSafe(device), style: text.bodyLarge),
          if (total > 0) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: device.verified / total,
              minHeight: 4,
              color: Palette.gold,
              backgroundColor: Palette.bg3,
            ),
            const SizedBox(height: 4),
            Text(
              '${device.verified} of $total on the device',
              style: text.bodySmall,
            ),
          ],
          Text(describeCounts(device), style: text.bodySmall),
          if (device.quiet)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'It has not reported for longer than you allow. Open Mediarr on it and '
                'check that backup is on.',
                style: text.bodySmall?.copyWith(color: Palette.err),
              ),
            ),
          if (missing != null) ...[
            const SizedBox(height: 6),
            if (missing.failures.isEmpty && missing.gone.isEmpty)
              Text('Nothing is missing.', style: text.bodySmall),
            for (final failure in missing.failures)
              Text('${failure.name}: ${failure.reason}', style: text.bodySmall),
            for (final gone in missing.gone)
              Text(
                '${gone.name.isEmpty ? gone.checksum.substring(0, 12) : gone.name}: '
                '${gone.inTrash ? 'in the trash on the server' : 'deleted from the server'}',
                style: text.bodySmall,
              ),
          ],
          if (!widget.all)
            Row(
              children: [
                if (device.failed > 0 || device.gone + device.trashed > 0)
                  TextButton(
                    onPressed: () => _toggleMissing(device),
                    child: Text(missing == null ? 'What is missing' : 'Hide'),
                  ),
                if (device.id == _thisDevice && device.failed > 0)
                  TextButton(
                    onPressed: () async {
                      await ref.read(backupProvider).retryFailed();
                      _say('Trying again.');
                    },
                    child: const Text('Try again'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => _remove(device),
                  child: Text('Remove', style: TextStyle(color: Palette.err)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final list = _list;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.all ? 'All backup devices' : 'Backup devices'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(report: !widget.all),
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                widget.all
                    ? 'Every user’s devices that back up. When one goes quiet, its owner is warned.'
                    : 'Phones that back up, and how much from each is safe on the server. '
                          'The server counts, from its own files.',
                style: text.bodyMedium,
              ),
            ),
            if (list == null && !_failed)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_failed)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('The devices did not load. Pull to try again.'),
              ),
            if (list != null && list.devices.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.all ? 'No device has reported yet.' : 'No device has reported yet. Turn on automatic backup in Upload.',
                ),
              ),
            if (list != null) ...list.devices.map(_device),
            if (list != null && !widget.all)
              ListTile(
                title: const Text('Warn me after'),
                subtitle: const Text(
                  'A notice here and on the web, and by e-mail if it is set up. Once, '
                  'until the device reports again.',
                ),
                trailing: DropdownButton<int>(
                  value: quietChoices.contains(list.quietDays)
                      ? list.quietDays
                      : 3,
                  items: [
                    for (final days in quietChoices)
                      DropdownMenuItem(
                        value: days,
                        child: Text(quietLabel(days)),
                      ),
                  ],
                  onChanged: (days) {
                    if (days != null) _setQuietDays(days);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
