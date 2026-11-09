import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/agent.dart';
import '../services/backup.dart';
import '../services/devices.dart';
import '../services/session.dart';
import '../theme.dart';
import '../l10n/l10n.dart';

/// The state of a device in a word or two.
String deviceState(BackupDevice device) {
  if (device.quiet) return l.devicesScreenQuiet;
  if (device.failed > 0 || device.gone + device.trashed > 0) {
    return l.devicesScreenNeedsALook;
  }
  return l.devicesScreenAllGood;
}

/// What the server counts as safe from a device, in one line.
String describeSafe(BackupDevice device) {
  final line = l.devicesScreenConfirmed('${device.confirmed}');
  return device.files > device.confirmed
      ? l.devicesScreenOfSent(line, '${device.files}')
      : line;
}

/// The phone's own counts, and what is no longer safe on the server.
String describeCounts(BackupDevice device) {
  final parts = [
    l.devicesScreenWaiting('${device.pending + device.working}'),
    l.devicesScreenNotSent('${device.failed}'),
    if (device.trashed > 0) l.devicesScreenInTrash('${device.trashed}'),
    if (device.gone > 0) l.devicesScreenGone('${device.gone}'),
  ];
  return parts.join(' · ');
}

const quietChoices = [1, 3, 7, 14, 0];

String quietLabel(int days) => switch (days) {
  0 => l.devicesScreenNever,
  _ => l.devicesScreenDays(days),
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
      _say(cause.message ?? l.devicesScreenNotLoaded);
    }
  }

  Future<void> _remove(BackupDevice device) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.devicesScreenRemoveTitle(device.name)),
        content: Text(l.devicesScreenRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.devicesScreenCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.devicesScreenRemove),
          ),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await _session.api.deleteBackupDevice(device.id);
      await _load();
    } on ApiException catch (cause) {
      _say(cause.message ?? l.devicesScreenNotRemoved);
    }
  }

  Future<void> _setQuietDays(int days) async {
    try {
      await _session.api.setBackupQuietDays(BackupQuietDays(days: days));
      await _load();
      _say(l.devicesScreenSaved);
    } on ApiException catch (cause) {
      _say(cause.message ?? l.devicesScreenNotSaved);
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
        : state == l.devicesScreenAllGood
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
                      ? l.devicesScreenThisPhone(device.name)
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
              l.devicesScreenLastReport(since(device.reportedAt.toLocal())),
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
              l.devicesScreenOnDevice('${device.verified}', '$total'),
              style: text.bodySmall,
            ),
          ],
          Text(describeCounts(device), style: text.bodySmall),
          if (device.quiet)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l.devicesScreenQuietWarning,
                style: text.bodySmall?.copyWith(color: Palette.err),
              ),
            ),
          if (missing != null) ...[
            const SizedBox(height: 6),
            if (missing.failures.isEmpty && missing.gone.isEmpty)
              Text(l.devicesScreenNothingMissing, style: text.bodySmall),
            for (final failure in missing.failures)
              Text('${failure.name}: ${failure.reason}', style: text.bodySmall),
            for (final gone in missing.gone)
              Text(
                '${gone.name.isEmpty ? gone.checksum.substring(0, 12) : gone.name}: '
                '${gone.inTrash ? l.devicesScreenInTrashOnServer : l.devicesScreenDeletedFromServer}',
                style: text.bodySmall,
              ),
          ],
          if (!widget.all)
            Row(
              children: [
                if (device.failed > 0 || device.gone + device.trashed > 0)
                  TextButton(
                    onPressed: () => _toggleMissing(device),
                    child: Text(
                      missing == null
                          ? l.devicesScreenWhatIsMissing
                          : l.devicesScreenHide,
                    ),
                  ),
                if (device.id == _thisDevice && device.failed > 0)
                  TextButton(
                    onPressed: () async {
                      await ref.read(backupProvider).retryFailed();
                      _say(l.devicesScreenTryingAgain);
                    },
                    child: Text(l.devicesScreenTryAgain),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => _remove(device),
                  child: Text(
                    l.devicesScreenRemove,
                    style: TextStyle(color: Palette.err),
                  ),
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
        title: Text(
          widget.all
              ? l.devicesScreenAllBackupDevices
              : l.devicesScreenBackupDevices,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(report: !widget.all),
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                widget.all ? l.devicesScreenAllIntro : l.devicesScreenIntro,
                style: text.bodyMedium,
              ),
            ),
            if (list == null && !_failed)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_failed)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.devicesScreenDidNotLoad),
              ),
            if (list != null && list.devices.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.all
                      ? l.devicesScreenNoneReported
                      : l.devicesScreenNoneReportedTurnOn,
                ),
              ),
            if (list != null) ...list.devices.map(_device),
            if (list != null && !widget.all)
              ListTile(
                title: Text(l.devicesScreenWarnMeAfter),
                subtitle: Text(l.devicesScreenWarnHelp),
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
